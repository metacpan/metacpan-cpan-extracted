package Langertha::Skeid::UsageStore::DBI;
our $VERSION = '0.004';
# ABSTRACT: SQLite and PostgreSQL usage store
use Moo;
use strict;
use warnings;
use Carp qw(croak);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::ShareDir qw(dist_dir);
use Fcntl qw(LOCK_EX LOCK_NB);
use IO::Handle;
use JSON::MaybeXS qw(encode_json decode_json);
use List::Util qw(min);
use Mojo::IOLoop;
use Mojo::Util qw(steady_time);
use Scalar::Util qw(weaken);
use Sys::Hostname ();
use Langertha::Skeid::UsageStore;


has backend      => (is => 'ro', required => 1);
has dsn          => (is => 'ro', required => 1);
has user         => (is => 'ro', default => sub { '' });
has password     => (is => 'ro', default => sub { '' });
has path         => (is => 'ro', default => sub { '' });
has schema_file  => (is => 'ro', default => sub { '' });
has auto_migrate => (is => 'ro', default => sub { 1 });
has flush_interval_ms => (is => 'ro', default => sub { 0 });
has on_lost      => (is => 'rw');
has spool_dir    => (is => 'ro', default => sub { '' });

has _dbh => (is => 'rw');
has _queue => (is => 'ro', default => sub { [] });
has _flush_timer => (is => 'rw');
# Reconnect backoff (k110): no connect before _reconnect_at (steady clock); _backoff_s is the
# wait the last failure set, _connect_error the masked error it failed with.
has _reconnect_at   => (is => 'rw', default => sub { 0 });
has _backoff_s      => (is => 'rw', default => sub { 0 });
has _connect_error  => (is => 'rw', default => sub { '' });
# Prepared while the database was down (spool_dir): the schema is applied on the first connect.
has _schema_pending => (is => 'rw', default => sub { 0 });
has _spool_pending  => (is => 'rw', default => sub { 0 });
has _spool_announced => (is => 'rw', default => sub { 0 });
has _replay_timer   => (is => 'rw');

# The values ADR 0027 names; tests lower them.
our $BACKOFF_START_S = 1;
our $BACKOFF_MAX_S   = 60;
our $REPLAY_BATCH    = 500;


sub prepare {
  my ($self) = @_;
  if (length $self->spool_dir) {
    $self->_spool_pending(1) if $self->_spool_files('any');
    my $dbh = eval { $self->dbh };
    unless ($dbh) {
      my $err = $@;
      return unless defined($err) && length($err);   # no DBI: as without a spool
      if ($self->auto_migrate) {
        $self->_schema_path;                          # a missing file still croaks here
        $self->_schema_pending(1);
      }
      warn 'skeid: usage database unreachable at start, usage events go to the spool in '
        . $self->spool_dir . ': ' . $self->_error_text($err) . "\n";
      $self->_spool_announced(1);
      return 1;
    }
  }
  my $dbh = $self->dbh or return;
  $self->_apply_schema($dbh) if $self->auto_migrate;
  $self->_schedule_replay;
  return 1;
}

sub _schema_path {
  my ($self) = @_;
  my $schema_file = $self->schema_file;
  $schema_file = $self->shipped_schema_file unless length $schema_file;
  croak "usage schema file not found: $schema_file" unless -f $schema_file;
  return $schema_file;
}

sub _apply_schema {
  my ($self, $dbh) = @_;
  my $sql = Langertha::Skeid::UsageStore::read_text_file($self->_schema_path);
  my @stmts = grep { /\S/ } map {
    my $s = $_;
    $s =~ s/^\s+//;
    $s =~ s/\s+$//;
    $s;
  } split /;\s*(?:\n|$)/, $sql;
  # Tables first, then any column an older table is missing, then the rest. The index
  # statements reference columns, so on an upgraded table they only work after the ALTER --
  # running the file top to bottom fails on exactly the deployments this exists for.
  my (@tables, @rest);
  for my $stmt (@stmts) {
    if ($stmt =~ /\A\s*CREATE\s+TABLE\b/i) { push @tables, $stmt }
    else                                   { push @rest, $stmt }
  }
  $dbh->do($_) for @tables;
  $self->_add_missing_columns($dbh);
  $dbh->do($_) for @rest;
  return 1;
}

# The shipped schema is CREATE TABLE IF NOT EXISTS, so it does nothing to a table that already
# exists -- a deployment that upgrades Skeid keeps its old columns and every insert naming a
# new one fails. Usage failures are reported rather than thrown, so that would show up as
# silently missing billing data. Adding the column is the whole migration story; nothing here
# ever drops or rewrites one.
my @ADDED_COLUMNS = (
  ['requested_model', 'TEXT'],
  # Prompt-cache read count (k27). Nullable on purpose: an old row that predates it reads NULL
  # ("was not measured"), which is not the same as a measured zero. BIGINT is INTEGER affinity
  # in SQLite and a 64-bit integer in PostgreSQL, so one type serves both ALTER statements.
  ['cached_tokens', 'BIGINT'],
  # UTF-8 bytes a streamed request relayed (skeid #36). Nullable: only streamed events carry it.
  ['content_bytes', 'BIGINT'],
  # Prompt-cache read / write cost (skeid #28), already part of cost_total_usd. Nullable: an old
  # row reads NULL ("was not priced apart"). DOUBLE PRECISION is REAL affinity in SQLite.
  ['cost_cache_read_usd', 'DOUBLE PRECISION'],
  ['cost_cache_write_usd', 'DOUBLE PRECISION'],
  # Prompt-cache write count (skeid #41), beside cached_tokens. Nullable: an old row reads NULL.
  ['cache_write_tokens', 'BIGINT'],
  # Seconds of audio an audio route's node reported (skeid k91, ADR 0021). Nullable: an event
  # whose node did not say reads NULL ("not measured"), not a measured zero.
  ['audio_seconds', 'DOUBLE PRECISION'],
  # Documents a rerank request carried (skeid k92). Nullable: only a rerank event has a count.
  ['documents', 'BIGINT'],
  # Pages a documents request converted (skeid k94, ADR 0028), read off the answer's
  # json_content. Nullable: only a documents event whose answer carried a page count has one.
  ['pages', 'BIGINT'],
);

sub _add_missing_columns {
  my ($self, $dbh) = @_;

  my $existing = eval {
    my $sth = $dbh->prepare('SELECT * FROM usage_events WHERE 1=0');
    $sth->execute;
    my %cols = map { lc($_) => 1 } @{ $sth->{NAME_lc} || [] };
    $sth->finish;
    \%cols;
  } or return;

  for my $column (@ADDED_COLUMNS) {
    my ($name, $type) = @$column;
    next if $existing->{$name};
    eval { $dbh->do("ALTER TABLE usage_events ADD COLUMN $name $type") };
  }
  return 1;
}


sub dbh {
  my ($self) = @_;
  my $cached = $self->_dbh;
  return $cached if $cached;
  return unless length($self->backend) && length($self->dsn);

  eval { require DBI } or return;

  if ($self->backend eq 'sqlite' && length $self->path) {
    my $dir = dirname($self->path);
    if (defined $dir && length $dir && $dir ne '.' && !-d $dir) {
      make_path($dir);
    }
  }

  my %connect_attr = (
    RaiseError => 1,
    PrintError => 0,
    AutoCommit => 1,
  );
  $connect_attr{sqlite_unicode} = 1 if $self->backend eq 'sqlite';

  my $wait = $self->_reconnect_at - _now();
  if ($wait > 0) {
    die sprintf("usage database unreachable (next connect attempt in %.1fs): %s\n",
      $wait, $self->_connect_error);
  }

  my $dbh = eval {
    my $h = DBI->connect($self->dsn, $self->user, $self->password, \%connect_attr)
      or die((DBI->errstr // 'failed to connect usage database') . "\n");
    # Prepared while the database was down (spool_dir): the schema waited for this connect.
    if ($self->_schema_pending) {
      unless (eval { $self->_apply_schema($h); 1 }) {
        my $err = $@;
        eval { $h->disconnect };
        die $err;
      }
      $self->_schema_pending(0);
    }
    $h;
  };
  unless ($dbh) {
    my $err = $@ || 'failed to connect usage database';
    # Back off (k110): one blocking connect per deadline while the database is away, never one
    # per event or per flush tick.
    my $backoff = $self->_backoff_s
      ? min($self->_backoff_s * 2, $BACKOFF_MAX_S)
      : $BACKOFF_START_S;
    $self->_backoff_s($backoff);
    $self->_reconnect_at(_now() + $backoff);
    $self->_connect_error($self->_error_text($err));
    die $err;
  }
  $self->_backoff_s(0);
  $self->_reconnect_at(0);
  $self->_connect_error('');
  $self->_spool_announced(0);
  $self->_dbh($dbh);
  return $dbh;
}

# The steady clock the backoff is measured on; a test moves it.
sub _now { steady_time() }


sub disconnect {
  my ($self) = @_;
  if (defined(my $timer = $self->_replay_timer)) {
    Mojo::IOLoop->remove($timer);
    $self->_replay_timer(undef);
  }
  $self->flush;
  $self->_drop_handle;
  return;
}

# Forget the handle without flushing: what _with_handle does to a handle a failed statement left
# dead, in the middle of a flush as well -- where a flush of its own would be a re-entry.
sub _drop_handle {
  my ($self) = @_;
  my $dbh = $self->_dbh or return;
  eval { $dbh->disconnect };
  $self->_dbh(undef);
  return;
}


sub shipped_schema_file {
  my ($self) = @_;
  my $name = ($self->backend eq 'postgresql') ? 'usage_events.postgresql.sql' : 'usage_events.sqlite.sql';
  my @candidates;

  # Installed/runtime lookup via dist sharedir.
  my $share_dir = eval { dist_dir('Langertha-Skeid') };
  if (!$@ && defined($share_dir) && length($share_dir)) {
    push @candidates, File::Spec->catfile($share_dir, 'sql', $name);
  }

  # Dev + dzil test fallback: walk up from this file looking for the repo's share/.
  my $dir = dirname(dirname(dirname(dirname(__FILE__))));
  for (1 .. 6) {
    push @candidates, File::Spec->catfile($dir, 'share', 'sql', $name);
    push @candidates, File::Spec->catfile($dir, 'sql', $name);
    my $parent = dirname($dir);
    last if !defined($parent) || $parent eq $dir;
    $dir = $parent;
  }

  for my $path (@candidates) {
    return $path if -f $path;
  }

  return $candidates[0];
}


sub store {
  my ($self, $event) = @_;
  if ($self->_writes_behind) {
    push @{ $self->_queue }, { %$event };
    $self->_arm_flush;
    return { ok => 1, queued => 1 };
  }
  # Whatever was queued while the loop ran goes first, so the table keeps the order the events
  # arrived in.
  $self->flush if @{ $self->_queue };
  my $res = $self->_with_handle(sub {
    my ($dbh) = @_;
    return { ok => 1, $self->_insert($dbh, $event) };
  });
  if ($res->{ok}) {
    $self->_schedule_replay;
    return $res;
  }
  # A live handle refused the event: spooling it would only replay the refusal.
  return $res if $self->_dbh || !length($self->spool_dir);
  my $spool_err = $self->_spool_events([$event]);
  unless ($spool_err) {
    $self->_announce_spool($res->{error});
    return { ok => 1, spooled => 1 };
  }
  return $self->_failure("$res->{error}; spool write failed: $spool_err");
}

# Queue only while a loop runs to fire the flush timer. Outside one -- a script calling
# usage.record, the prefork manager before it forks -- there is no request path to keep free and
# a queue that nothing would ever write.
sub _writes_behind {
  my ($self) = @_;
  return 0 unless $self->flush_interval_ms > 0;
  return Mojo::IOLoop->is_running ? 1 : 0;
}

sub _arm_flush {
  my ($self) = @_;
  return if defined $self->_flush_timer;
  weaken(my $weak = $self);
  $self->_flush_timer(Mojo::IOLoop->timer($self->flush_interval_ms / 1000 => sub {
    return unless $weak;
    $weak->_flush_timer(undef);
    $weak->flush;
  }));
  return;
}


sub flush {
  my ($self) = @_;
  if (defined(my $timer = $self->_flush_timer)) {
    Mojo::IOLoop->remove($timer);
    $self->_flush_timer(undef);
  }
  my @events = splice @{ $self->_queue };
  return { ok => 1, written => 0 } unless @events;

  my $batch = $self->_with_handle(sub {
    my ($dbh) = @_;
    $dbh->begin_work;
    my $done = eval {
      $self->_insert($dbh, $_) for @events;
      $dbh->commit;
      1;
    };
    unless ($done) {
      my $err = $@;
      eval { $dbh->rollback };
      die $err;
    }
    return { ok => 1, written => scalar @events };
  });
  if ($batch->{ok}) {
    $self->_schedule_replay;
    return $batch;
  }

  # No handle left: the reconnect failed (or the backoff runs), and one attempt per event would
  # only repeat it.
  return _flush_answer(0, $self->_spool_or_lose(\@events, $batch->{error}))
    unless $self->_dbh;

  my ($written, $spooled, $lost, $error) = (0, 0, 0);
  while (@events) {
    my $event = shift @events;
    my $one = $self->_with_handle(sub {
      my ($dbh) = @_;
      $self->_insert($dbh, $event);
      return { ok => 1 };
    });
    if ($one->{ok}) {
      $written++;
      next;
    }
    if ($self->_dbh) {
      # Refused on a live handle: this event alone is lost, and never spooled.
      $lost++;
      $error = $one->{error};
      $self->_report_lost($event, $error);
      next;
    }
    # The handle died under the single writes and did not come back: this event and the rest
    # go with it.
    my ($s, $l, $e) = $self->_spool_or_lose([$event, @events], $one->{error});
    $spooled += $s;
    $lost += $l;
    $error = $e if $l;
    last;
  }
  $self->_schedule_replay if $written;
  return _flush_answer($written, $spooled, $lost, $error);
}

sub _flush_answer {
  my ($written, $spooled, $lost, $error) = @_;
  return {
    ok      => ($lost ? 0 : 1),
    written => $written,
    ($spooled ? (spooled => $spooled) : ()),
    ($lost ? (lost => $lost, error => $error) : ()),
  };
}

# Events that could not be written for want of a connection: to the spool when there is one,
# else -- or when the spool write fails -- reported lost. Answers ($spooled, $lost, $error).
sub _spool_or_lose {
  my ($self, $events, $err) = @_;
  if (length $self->spool_dir) {
    my $spool_err = $self->_spool_events($events);
    unless ($spool_err) {
      $self->_announce_spool($err);
      return (scalar(@$events), 0, undef);
    }
    $err = $self->_error_text($err) . "; spool write failed: $spool_err";
  }
  my $failure = $self->_failure($err);
  $self->_report_lost($_, $failure->{error}) for @$events;
  return (0, scalar(@$events), $failure->{error});
}

# Fail loud once per outage: spooled events are not lost, but the database is away.
sub _announce_spool {
  my ($self, $err) = @_;
  return if $self->_spool_announced;
  $self->_spool_announced(1);
  warn 'skeid: usage database unreachable, usage events go to the spool in '
    . $self->spool_dir . ' until it is back: ' . $self->_error_text($err) . "\n";
  return;
}

sub _report_lost {
  my ($self, $event, $err) = @_;
  my $cb = $self->on_lost;
  return if $cb && eval { $cb->($event, $err); 1 };
  # A timer callback that dies takes the reactor's error path; a lost event must still be said.
  warn 'skeid: usage event lost: request_id=' . ($event->{request_id} // '')
    . ' store=' . $self->backend . ': ' . $err . "\n";
  return;
}

# Runs $work with the store's handle and returns its answer, or { ok => 0, error } when it dies.
# On a failure that left the handle dead the handle is dropped, connected once more and $work
# retried once on the new one (skeid k71). Never more than that, never a wait.
sub _with_handle {
  my ($self, $work) = @_;

  my $dbh = eval { $self->dbh };
  return $self->_failure($@ || 'failed to connect usage database') unless $dbh;

  my $res = eval { $work->($dbh) };
  return $res if $res;
  my $err = $@;
  return $self->_failure($err) if $self->_handle_alive($dbh);

  $self->_drop_handle;
  my $fresh = eval { $self->dbh };
  return $self->_failure('usage database connection lost, reconnect failed: '
    .($@ || 'no database handle')) unless $fresh;

  $res = eval { $work->($fresh) };
  return $res || $self->_failure($@);
}

# Asked only after a statement failed, so the round-trip a ping costs on PostgreSQL is never
# paid by a healthy write. DBD::Pg keeps Active set on a connection the server dropped; ping
# is what notices.
sub _handle_alive {
  my ($self, $dbh) = @_;
  return 0 unless $dbh->{Active};
  return eval { $dbh->ping } ? 1 : 0;
}

sub _failure {
  my ($self, $err) = @_;
  return { ok => 0, error => $self->_error_text($err) };
}

# A DBI error names the DSN it failed on, and a DSN may carry the password. Nothing that
# leaves this store may (ADR 0003).
sub _error_text {
  my ($self, $err) = @_;
  $err = 'unknown database error' unless defined($err) && length($err);
  $err =~ s/\b(password|pwd)=[^;'"\s)]*/$1=***/gi;
  $err =~ s/\s+$//;
  return $err;
}

# The columns of one event, in the order _insert binds them. The spool writes exactly these keys
# of an event and nothing else (k110), so a new column is added here once and reaches both.
my @EVENT_COLUMNS = qw(
  created_at request_id api_format endpoint api_key_id provider engine model node_id route_url
  status_code ok duration_ms input_tokens output_tokens total_tokens cached_tokens tool_calls
  cost_input_usd cost_output_usd cost_total_usd error_type error_message requested_model
  content_bytes cost_cache_read_usd cost_cache_write_usd cache_write_tokens audio_seconds
  documents pages
);
# Nullable, written as NULL when the event has no such key -- "not measured", not a zero:
#   cached_tokens          an event that carried no cache count
#   content_bytes          only a streamed request carries it
#   cost_cache_read_usd,
#   cost_cache_write_usd   an event from a caller that does not price the cache apart
#   cache_write_tokens     an event that carried no cache write count
#   audio_seconds          only an audio route's event, and only when its node reported it
#   documents              only a rerank or documents event
#   pages                  only a documents event whose answer said how many pages it was
# requested_model falls back to model, then ''.
my $INSERT_SQL = 'INSERT INTO usage_events (' . join(', ', @EVENT_COLUMNS) . ') VALUES ('
  . join(', ', ('?') x @EVENT_COLUMNS) . ')';

sub _insert {
  my ($self, $dbh, $event) = @_;
  my $sth = $dbh->prepare_cached($INSERT_SQL);
  $sth->execute(map {
    $_ eq 'requested_model'
      ? ($event->{requested_model} // $event->{model} // '')
      : $event->{$_}
  } @EVENT_COLUMNS);

  return ($self->backend eq 'sqlite' && $dbh->can('sqlite_last_insert_rowid'))
    ? ( id => Langertha::Skeid::UsageStore::num($dbh->sqlite_last_insert_rowid) )
    : ();
}

# Replay's insert (k110): skipped when the event is already in the table. The key is
# request_id with created_at -- the spool holds the event as it was built, so a copy that made it
# in carries both, while a client that sends the same x-request-id twice does not lose its
# second, real event. Without a request_id there is no key: the event is written. Answers 1 for
# a row written, 0 for one skipped.
sub _insert_once {
  my ($self, $dbh, $event) = @_;
  my $request_id = $event->{request_id};
  if (defined($request_id) && length($request_id)) {
    my $found = $dbh->selectrow_arrayref(
      'SELECT 1 FROM usage_events WHERE request_id = ? AND created_at = ?',
      undef, $request_id, $event->{created_at});
    return 0 if $found;
  }
  $self->_insert($dbh, $event);
  return 1;
}

# --- The spool (k110, ADR 0027) ----------------------------------------------------------------
#
# Writers append to usage-spool-<host>-<pid>.jsonl, one per process. A replay first claims a
# writer's file by renaming it to <name>.replay-<host>-<pid>-<n> under the file's lock; a writer
# that was waiting for that lock sees the path no longer names its file and opens a new one. A
# claimed file is then worked under its own lock, which only replays ever take -- so a writer
# waits at most for a rename, never for a database. Temporary files start with a dot and match
# neither pattern.

my $SPOOL_FILE   = qr/\Ausage-spool-[A-Za-z0-9._-]+\.jsonl\z/;
my $CLAIMED_FILE = qr/\Ausage-spool-[A-Za-z0-9._-]+\.jsonl\.replay-[A-Za-z0-9._-]+\z/;
my $CLAIM_SEQ = 0;
my $HOST;

sub _host {
  return $HOST //= do {
    my $host = eval { Sys::Hostname::hostname() } // '';
    $host =~ s/[^A-Za-z0-9.-]+/_/g;
    length($host) ? $host : 'localhost';
  };
}

sub _spool_files {
  my ($self, $kind) = @_;
  opendir(my $dh, $self->spool_dir) or return;
  my @names = sort grep {
      $kind eq 'writer'  ? $_ =~ $SPOOL_FILE
    : $kind eq 'claimed' ? $_ =~ $CLAIMED_FILE
    : ($_ =~ $SPOOL_FILE || $_ =~ $CLAIMED_FILE)
  } readdir $dh;
  closedir $dh;
  return @names;
}

# True when the open $fh is still the file at $path: a replay may have renamed or removed it
# between the open and the lock.
sub _same_file {
  my ($fh, $path) = @_;
  my @open = stat $fh or return 0;
  my @named = stat $path or return 0;
  return $open[0] == $named[0] && $open[1] == $named[1];
}

# Appends $events to this process's spool file. Answers undef, or the error -- never dies.
sub _spool_events {
  my ($self, $events) = @_;
  my $ok = eval { $self->_append_spool($events); 1 };
  return $@ || 'unknown spool error' unless $ok;
  $self->_spool_pending(1);
  return undef;
}

sub _append_spool {
  my ($self, $events) = @_;
  my $dir = $self->spool_dir;
  unless (-d $dir) {
    make_path($dir, { error => \my $mkerr });
    die "Cannot create spool directory $dir\n" unless -d $dir;
  }
  # Only the columns: whatever else an event hash carries never reaches the disk.
  my $lines = join '', map {
    my $event = $_;
    encode_json({ map { exists $event->{$_} ? ($_ => $event->{$_}) : () } @EVENT_COLUMNS }) . "\n";
  } @$events;
  my $path = File::Spec->catfile($dir, 'usage-spool-' . _host() . "-$$.jsonl");

  for (1 .. 5) {
    open my $fh, '>>', $path or die "Cannot append $path: $!\n";
    binmode $fh;
    flock($fh, LOCK_EX) or die "Cannot lock $path: $!\n";
    unless (_same_file($fh, $path)) {
      close $fh;   # claimed by a replay meanwhile: append to a new file
      next;
    }
    print {$fh} $lines or die "Cannot append $path: $!\n";
    $fh->flush       or die "Cannot flush $path: $!\n";
    $fh->sync        or die "Cannot sync $path: $!\n";
    close $fh        or die "Cannot close $path: $!\n";
    return 1;
  }
  die "Cannot append $path: claimed by a replay on every attempt\n";
}


sub replay_spool {
  my ($self) = @_;
  my %res = (ok => 1, replayed => 0, consumed => 0, remaining => 0);
  return \%res unless length $self->spool_dir;
  my $dir = $self->spool_dir;

  # Claim: rename every writer file this process can lock right now.
  for my $name ($self->_spool_files('writer')) {
    my $path = File::Spec->catfile($dir, $name);
    open my $fh, '<', $path or next;
    flock($fh, LOCK_EX | LOCK_NB) or next;
    rename($path, "$path.replay-" . _host() . "-$$-" . ++$CLAIM_SEQ) if _same_file($fh, $path);
    close $fh;
  }

  my $budget = $REPLAY_BATCH;
  for my $name ($self->_spool_files('claimed')) {
    last if $budget <= 0;
    my $one = $self->_replay_file(File::Spec->catfile($dir, $name), $budget);
    $res{replayed} += $one->{replayed};
    $res{consumed} += $one->{consumed};
    $budget -= $one->{consumed};
    next if $one->{ok};
    @res{qw(ok error)} = (0, $one->{error});
    last;
  }

  $res{remaining} = $self->_spool_files('any') ? 1 : 0;
  $self->_spool_pending($res{remaining});
  return \%res;
}

sub _replay_file {
  my ($self, $path, $budget) = @_;
  my %none = (ok => 1, replayed => 0, consumed => 0);
  open my $fh, '<', $path or return \%none;         # finished by another process
  flock($fh, LOCK_EX | LOCK_NB) or return \%none;   # being replayed by another process
  return \%none unless _same_file($fh, $path);
  binmode $fh;
  my @lines = <$fh>;
  my @take = splice @lines, 0, $budget;

  my @events;
  for my $i (0 .. $#take) {
    next unless $take[$i] =~ /\S/;
    my $event = eval { decode_json($take[$i]) };
    if (ref($event) eq 'HASH') {
      push @events, $event;
      next;
    }
    # A torn last line (the process died mid-write, the disk filled up): nothing to replay.
    warn "skeid: unreadable line dropped from usage spool $path\n";
  }

  my $written = $self->_replay_events(\@events);
  return { ok => 0, replayed => 0, consumed => 0, error => $written->{error} }
    unless $written->{ok};

  # Committed: only now do the lines leave the spool. Should this fail, they stay and the next
  # replay skips them as already present.
  if (@lines) {
    my ($vol, $dir) = File::Spec->splitpath($path);
    my $tmp = File::Spec->catpath($vol, $dir, ".tmp-$$-" . ++$CLAIM_SEQ);
    if (open my $out, '>', $tmp) {
      binmode $out;
      if ((print {$out} @lines) && $out->flush && $out->sync && close($out)) {
        rename($tmp, $path) or unlink $tmp;
      } else {
        unlink $tmp;
      }
    }
  } else {
    unlink $path;
  }
  close $fh;
  return { ok => 1, replayed => $written->{written}, consumed => scalar(@take) };
}

# One transaction for the batch. A refusal on a live handle falls back to one event at a time,
# so a single event the database will never take is reported lost and does not hold up the
# rest; a database that went away again stops the replay with the spool untouched.
sub _replay_events {
  my ($self, $events) = @_;
  return { ok => 1, written => 0 } unless @$events;

  my $batch = $self->_with_handle(sub {
    my ($dbh) = @_;
    $dbh->begin_work;
    my $written = eval {
      my $n = 0;
      $n += $self->_insert_once($dbh, $_) for @$events;
      $dbh->commit;
      $n;
    };
    unless (defined $written) {
      my $err = $@;
      eval { $dbh->rollback };
      die $err;
    }
    return { ok => 1, written => $written };
  });
  return $batch if $batch->{ok} || !$self->_dbh;

  my $written = 0;
  for my $event (@$events) {
    my $one = $self->_with_handle(sub {
      my ($dbh) = @_;
      return { ok => 1, written => $self->_insert_once($dbh, $event) };
    });
    if ($one->{ok}) {
      $written += $one->{written};
      next;
    }
    return $one unless $self->_dbh;
    $self->_report_lost($event, $one->{error});
  }
  return { ok => 1, written => $written };
}

# After a write that succeeded: replay one batch of the spool. Inside the loop on the next tick,
# batch after batch while there is progress; outside it -- prepare at start, a script -- one
# batch at once, the rest with the next write.
sub _schedule_replay {
  my ($self) = @_;
  return unless $self->_spool_pending && length $self->spool_dir;
  unless (Mojo::IOLoop->is_running) {
    $self->replay_spool;
    return;
  }
  return if defined $self->_replay_timer;
  weaken(my $weak = $self);
  $self->_replay_timer(Mojo::IOLoop->timer(0 => sub {
    return unless $weak;
    $weak->_replay_timer(undef);
    my $res = $weak->replay_spool;
    $weak->_schedule_replay if $res->{ok} && $res->{consumed} && $res->{remaining};
  }));
  return;
}


sub report {
  my ($self, $filters) = @_;
  $filters ||= {};
  $self->flush;

  my $report = $self->_with_handle(sub {
    my ($dbh) = @_;
    return $self->_report($dbh, $filters);
  });
  return $report->{ok} ? $report : { %$report, enabled => 0 };
}

sub _report {
  my ($self, $dbh, $filters) = @_;
  my $num = \&Langertha::Skeid::UsageStore::num;

  my $limit = $filters->{limit} // 20;

  my @where;
  my @bind;
  if (defined $filters->{since} && length $filters->{since}) {
    push @where, 'created_at >= ?';
    push @bind, $filters->{since};
  }
  if (defined $filters->{api_key_id} && length $filters->{api_key_id}) {
    push @where, 'api_key_id = ?';
    push @bind, $filters->{api_key_id};
  }
  if (defined $filters->{model} && length $filters->{model}) {
    push @where, 'model = ?';
    push @bind, $filters->{model};
  }

  my $where_sql = @where ? ('WHERE ' . join(' AND ', @where)) : '';

  my $totals = $dbh->selectrow_hashref(
    "SELECT
       COUNT(*) AS requests,
       COALESCE(SUM(input_tokens), 0) AS input_tokens,
       COALESCE(SUM(output_tokens), 0) AS output_tokens,
       COALESCE(SUM(total_tokens), 0) AS total_tokens,
       COALESCE(SUM(cached_tokens), 0) AS cached_tokens,
       COALESCE(SUM(cache_write_tokens), 0) AS cache_write_tokens,
       COALESCE(SUM(tool_calls), 0) AS tool_calls,
       COALESCE(SUM(audio_seconds), 0) AS audio_seconds,
       COALESCE(SUM(documents), 0) AS documents,
       COALESCE(SUM(pages), 0) AS pages,
       COALESCE(SUM(cost_total_usd), 0) AS total_cost_usd
     FROM usage_events $where_sql",
    undef,
    @bind,
  ) || {};

  my $by_key = $dbh->selectall_arrayref(
    "SELECT
       COALESCE(api_key_id, '') AS api_key_id,
       COUNT(*) AS requests,
       COALESCE(SUM(total_tokens), 0) AS total_tokens,
       COALESCE(SUM(audio_seconds), 0) AS audio_seconds,
       COALESCE(SUM(documents), 0) AS documents,
       COALESCE(SUM(pages), 0) AS pages,
       COALESCE(SUM(cost_total_usd), 0) AS total_cost_usd
     FROM usage_events
     $where_sql
     GROUP BY api_key_id
     ORDER BY total_cost_usd DESC, requests DESC, api_key_id ASC",
    { Slice => {} },
    @bind,
  ) || [];

  my $by_model = $dbh->selectall_arrayref(
    "SELECT
       COALESCE(model, '') AS model,
       COUNT(*) AS requests,
       COALESCE(SUM(total_tokens), 0) AS total_tokens,
       COALESCE(SUM(audio_seconds), 0) AS audio_seconds,
       COALESCE(SUM(documents), 0) AS documents,
       COALESCE(SUM(pages), 0) AS pages,
       COALESCE(SUM(cost_total_usd), 0) AS total_cost_usd
     FROM usage_events
     $where_sql
     GROUP BY model
     ORDER BY total_cost_usd DESC, requests DESC, model ASC",
    { Slice => {} },
    @bind,
  ) || [];

  my $recent = $dbh->selectall_arrayref(
    "SELECT
       id, created_at, api_format, endpoint, api_key_id, model, requested_model, node_id, status_code, ok,
       input_tokens, output_tokens, total_tokens, cached_tokens, cache_write_tokens, tool_calls, cost_total_usd
     FROM usage_events
     $where_sql
     ORDER BY id DESC
     LIMIT ?",
    { Slice => {} },
    @bind,
    $limit,
  ) || [];

  return {
    ok        => 1,
    enabled   => 1,
    backend   => $self->backend,
    db_path   => ($self->backend eq 'sqlite' ? ($self->path // '') : ''),
    since     => ($filters->{since} // ''),
    totals    => {
      requests       => $num->($totals->{requests}),
      input_tokens   => $num->($totals->{input_tokens}),
      output_tokens  => $num->($totals->{output_tokens}),
      total_tokens   => $num->($totals->{total_tokens}),
      cached_tokens  => $num->($totals->{cached_tokens}),
      cache_write_tokens => $num->($totals->{cache_write_tokens}),
      tool_calls     => $num->($totals->{tool_calls}),
      audio_seconds  => $num->($totals->{audio_seconds}),
      documents      => $num->($totals->{documents}),
      pages          => $num->($totals->{pages}),
      total_cost_usd => $num->($totals->{total_cost_usd}),
    },
    by_key   => [ map {
      +{
        api_key_id     => ($_->{api_key_id} // ''),
        requests       => $num->($_->{requests}),
        total_tokens   => $num->($_->{total_tokens}),
        audio_seconds  => $num->($_->{audio_seconds}),
        documents      => $num->($_->{documents}),
        pages          => $num->($_->{pages}),
        total_cost_usd => $num->($_->{total_cost_usd}),
      }
    } @$by_key ],
    by_model => [ map {
      +{
        model          => ($_->{model} // ''),
        requests       => $num->($_->{requests}),
        total_tokens   => $num->($_->{total_tokens}),
        audio_seconds  => $num->($_->{audio_seconds}),
        documents      => $num->($_->{documents}),
        pages          => $num->($_->{pages}),
        total_cost_usd => $num->($_->{total_cost_usd}),
      }
    } @$by_model ],
    recent   => [ map {
      +{
        id            => $num->($_->{id}),
        created_at    => ($_->{created_at} // ''),
        api_format    => ($_->{api_format} // ''),
        endpoint      => ($_->{endpoint} // ''),
        api_key_id    => ($_->{api_key_id} // ''),
        model           => ($_->{model} // ''),
        requested_model => ($_->{requested_model} // $_->{model} // ''),
        node_id         => ($_->{node_id} // ''),
        status_code   => $num->($_->{status_code}),
        ok            => ($_->{ok} ? 1 : 0),
        input_tokens  => $num->($_->{input_tokens}),
        output_tokens => $num->($_->{output_tokens}),
        total_tokens  => $num->($_->{total_tokens}),
        cached_tokens => $num->($_->{cached_tokens}),
        cache_write_tokens => $num->($_->{cache_write_tokens}),
        tool_calls    => $num->($_->{tool_calls}),
        cost_total_usd => $num->($_->{cost_total_usd}),
      }
    } @$recent ],
  };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::UsageStore::DBI - SQLite and PostgreSQL usage store

=head1 VERSION

version 0.004

=head1 DESCRIPTION

Usage events in a real database — SQLite for a single box, PostgreSQL for a deployment. Both
speak the same C<usage_events> table, shipped as F<share/sql/usage_events.E<lt>backendE<gt>.sql>.

By default every event costs a synchronous database round-trip -- and a commit -- on the request
path, which is why L<Langertha::Skeid::UsageStore::JsonLog> is the recommended default and this
backend is a deliberate choice. See F<docs/adr/0004-usage-events-are-the-billing-unit.md>.

C<flush_interval_ms> turns on write-behind: while the event loop runs, L</store> only queues the
event and answers at once, and a L<Mojo::IOLoop> timer writes the queue in one transaction. The
request is answered without waiting for the database, and a burst of events costs one commit
instead of one each. The flush itself is still a synchronous database call on the loop -- it
runs once per interval instead of once per request, it is not off the loop. The price is a wider
loss window: events still queued when the process dies without a flush are lost (ADR 0005,
Update skeid k78). Off by default.

C<spool_dir> keeps the events the database cannot take while it is down: they are appended to a
local file instead of being reported lost, and written once the database answers again (see
L</spool_dir> and F<docs/adr/0027-usage-events-spool-while-the-database-is-down.md>). With or
without it, a failed connect is not repeated for every event: the next attempt waits for a
backoff deadline (L</Reconnect backoff>). Off by default.

C<DBI> is loaded at runtime rather than compile time: a Skeid that never configures a database
backend must not require one to be installed.

=head2 Reconnect backoff

After a connect fails, the store does not connect again before a deadline: 1 second after the
first failure, doubling with every further failure up to 60 seconds. Until then every write
fails at once with C<usage database unreachable (next connect attempt in ...)> and the last
connect error, without touching the network -- a database host that does not answer costs one
blocking connect per deadline, not one per event or per flush (ADR 0005). The first connect that
succeeds clears the backoff. The events of that window go to the spool when L</spool_dir> is set,
else to L</on_lost> (or the caller of a synchronous L</store>) as before.

=head2 backend

C<sqlite> or C<postgresql>. Decides the schema file and whether an insert can report a row id.

=head2 dsn

Required. The DBI data source, as normalized by L<Langertha::Skeid::UsageStore/normalize_config>
(C<dbi:SQLite:dbname=...> or C<dbi:Pg:...>).

=head2 user

Database user (default empty).

=head2 password

Database password (default empty). Normalization reads it from C<password_env> when the config
names that instead; it is never written anywhere.

=head2 path

SQLite database file. Its parent directory is created on connect. Empty for PostgreSQL.

=head2 schema_file

Explicit schema path. Empty means "find the shipped one for this backend".

=head2 auto_migrate

Apply the schema when the store is prepared. On by default.

=head2 flush_interval_ms

Write-behind interval in milliseconds; C<0> (the default) writes every event synchronously when
L</store> is called. Above C<0>, L</store> queues the event while L<Mojo::IOLoop> is running, and
the first queued event arms a timer that calls L</flush> after this many milliseconds. With no
running loop there is nothing to protect and nothing to fire the timer, so L</store> writes at
once, after anything still queued.

=head2 on_lost

Optional code ref, called as C<< ->($event, $error) >> for every queued event a L</flush> could
not write -- the request it describes was answered long ago, so there is no caller left to hand
the failure to. L<Langertha::Skeid> sets it to its own lost-event report. Without it the store
C<warn>s one line naming the request id and the backend, never the DSN.

=head2 spool_dir

Directory for the usage spool; empty (the default) turns it off and leaves every failure to
L</on_lost> as before. Set, an event the store cannot write because the database is unreachable
-- the connect failed, the handle died and the one reconnect failed, or the reconnect backoff is
running -- is appended to a file in this directory instead of being reported lost: JSON Lines,
one event per line, flushed and C<fsync>'d before the write counts. A synchronous L</store>
then answers C<< { ok => 1, spooled => 1 } >>, a L</flush> counts it in C<spooled>. An event the
database I<refuses> on a live connection (a constraint, a dropped table) is not spooled -- it
would be refused again on every replay -- and stays an L</on_lost> report. A spool write that
fails reports the event lost, with both errors. The first event spooled after a connect
C<warn>s once that the database is unreachable and where the events go.

A spool line holds the event's columns and nothing else: key ids, never a key, never the DSN or
the password. Each process appends to its own file,
F<usage-spool-E<lt>hostE<gt>-E<lt>pidE<gt>.jsonl>, under an exclusive C<flock>, so the workers of
one Skeid can share the directory. Several Skeid instances should each have their own; the
spool is per instance.

The spool is replayed once the database takes writes again: after a write that succeeded
(L</store>, L</flush>) and when the store is prepared, so a restart picks up what an earlier
process left behind. A replay claims a file by renaming it, writes at most 500 of its events in
one transaction and removes those lines only after the commit; the rest follows on the next loop
tick (or with the next write when no loop runs). Replay is idempotent: an event whose
C<request_id> and C<created_at> are already in the table is skipped, so a replay that is
interrupted and repeated, or an event that did make it in before its connection dropped, never
adds a second row. An event without a C<request_id> cannot be recognized and is written again
by a repeated replay -- at least once rather than lost. A line that does not parse is dropped
with a warning; an event the database refuses on a live connection during the replay is
reported to L</on_lost> and dropped, the rest of its batch is written. Nothing replays while the
database is unreachable, and a replay that fails half way leaves the spool file as it was (what it did commit is skipped
next time).

A store prepared while the database is down does not die when it has a spool: it warns, starts
with the backoff running and applies the schema on its first successful connect.

=head2 prepare

Connects if possible and applies the schema when C<auto_migrate> is on: its C<CREATE TABLE>
statements, then any column an older table lacks (C<ALTER TABLE ... ADD COLUMN>; nothing is
ever dropped or rewritten), then the rest. Returns false without complaint when C<DBI> is
unavailable -- an unusable store degrades to "no usage recorded", it does not take the proxy
down. Croaks when the schema file does not exist; a failing connect or statement dies -- except
a failing connect of a store with a L</spool_dir>, which warns and returns true: its events go
to the spool and the schema is applied on the first connect that succeeds. With a spool, what
an earlier process left in it starts to be replayed here.

=head2 dbh

The cached database handle, connecting on first use. Returns nothing when C<DBI> is not
installed or no DSN is configured. Dies when the connect fails, and -- without trying -- while
the L</Reconnect backoff> a failed connect set is running.

=head2 disconnect

Writes what is still queued (L</flush>), then drops the cached handle, so the next L</dbh>
connects anew. Called when the store is replaced on a reload -- the queued events belong to this
store's destination, not the next one's -- and from Skeid's C<DEMOLISH>.

=head2 shipped_schema_file

The schema file this backend would apply when C<schema_file> is not set. Looks in the installed
sharedir first, then walks up from this file for the repository's F<share/sql/> — the dev and
C<dzil test> case, where nothing is installed yet. Returns the first candidate that exists, or
the first candidate at all, so the caller can report a useful path when none does.

=head2 store

  my $res = $store->store($event);

Inserts one event. Returns C<< { ok => 1 } >> (plus C<id> on SQLite), or
C<< { ok => 0, error => … } >> when there is no database handle or the insert fails -- a failure
is reported, never thrown, because the request it describes has already been served. The proxy
logs such an answer at C<error> level as a lost usage event. A C<password=> in the error text
(a DSN that carries one) is masked.

With L</flush_interval_ms> set and the event loop running, the event is queued instead and the
answer is C<< { ok => 1, queued => 1 } >>, without an C<id>: the row does not exist yet. What
becomes of it is L</flush>'s to report.

A dropped connection is survived: when the insert fails and the handle turns out to be dead
(not C<Active>, or C<ping> fails -- checked only after a failure, so a healthy write costs
nothing extra), the store connects once more and retries that one event once. The new handle
serves every later event. A reconnect that fails is reported like any other failure (the next
event tries again once the L</Reconnect backoff> has run out), and a failure on a live handle
-- a dropped table, a constraint -- is reported without a reconnect. There is no loop and no
wait: at most one extra synchronous connect per event, and while the database stays away at
most one per backoff deadline, the cost ADR 0005 already accepts for this backend. With a
L</spool_dir>, an event that could not be written for want of a connection is spooled and the
answer is C<< { ok => 1, spooled => 1 } >>; a write that succeeds starts a replay of the
spool. The schema is not
re-applied on a reconnect; L</prepare> ran when the store was configured, and a lost connection
does not lose the table. One corner remains: a connection that drops after the server committed
the insert but before it answered is indistinguishable from one that dropped before, so that
event can be written twice. A duplicate row carries the same C<request_id>; a lost one leaves
nothing to reconcile.

=head2 flush

  my $res = $store->flush;

Writes every queued event in one transaction and empties the queue. Returns
C<< { ok => 1, written => $n } >>, or C<< { ok => 0, written => $n, lost => $m, error => … } >>
when some could not be written; each of those is also handed to L</on_lost>. With a
L</spool_dir>, events that went to the spool are counted in C<spooled> and are not lost. Never
dies, never waits, never retries later: every queued event gets the one attempt a synchronous
L</store> would have given it -- the spool's replay is a write of its own.

A failing batch is rolled back, so nothing is half written. When the handle survived the failure
-- one event a constraint rejects, a dropped table -- the events are written one by one, so a
single bad event loses only itself. When the handle died, it is reconnected once and the batch
retried once, as for L</store>; a reconnect that fails loses (or spools) the whole batch with
one connect attempt, not one per event, and while the L</Reconnect backoff> runs a flush makes
no connect attempt at all. The duplicate corner of L</store> applies to a batch: a connection
that drops after the server committed but before it answered is retried as a whole. A flush
that wrote something starts a replay of the spool.

Called by the flush timer, by L</disconnect>, by L</report> (so a report counts what was queued)
and by L</store> when it writes synchronously. L<Langertha::Skeid/flush_usage> calls it.

=head2 replay_spool

  my $res = $store->replay_spool;

Writes up to one batch (500 events) of the L</spool_dir> to the database and removes what was
committed. Returns C<< { ok => 1, replayed => $n, consumed => $m, remaining => 0|1 } >> --
C<replayed> rows written, C<consumed> spool lines done with (written, already present, or
dropped), C<remaining> whether spool files are left -- or the same with C<< ok => 0 >> and an
C<error> when the database failed; the spool is then left as it was. Never dies. The store calls
it itself (see L</spool_dir>); it is public for an operator's script and for tests.

=head2 report

  my $report = $store->report(\%filters);

Aggregates in SQL: totals, per-key and per-model breakdowns (tokens, cost, the
C<audio_seconds> the audio routes recorded, the C<documents> of the rerank and documents routes and
the C<pages> of the documents routes), and the
newest C<limit> events.
The same C<since> / C<api_key_id> / C<model> filter set applies to every part of the report, so
the breakdowns always add up to the totals shown next to them. C<limit> defaults to 20. The shape
is described in L<Langertha::Skeid::UsageStore/The store contract>; a failure to connect or a
failing query is C<< { ok => 0, enabled => 0, error => … } >>. A dropped connection is
reconnected once, exactly as for L</store>. Queued events are flushed first, so a report counts
every event recorded before it was asked for.

=head1 SEE ALSO

L<Langertha::Skeid::UsageStore>, L<Langertha::Skeid::UsageStore::JsonLog>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-skeid/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
