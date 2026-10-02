package Langertha::Skeid::UsageStore::DBI;
our $VERSION = '0.003';
# ABSTRACT: SQLite and PostgreSQL usage store
use Moo;
use strict;
use warnings;
use Carp qw(croak);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::ShareDir qw(dist_dir);
use Mojo::IOLoop;
use Scalar::Util qw(weaken);
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

has _dbh => (is => 'rw');
has _queue => (is => 'ro', default => sub { [] });
has _flush_timer => (is => 'rw');


sub prepare {
  my ($self) = @_;
  my $dbh = $self->dbh or return;
  return 1 unless $self->auto_migrate;

  my $schema_file = $self->schema_file;
  $schema_file = $self->shipped_schema_file unless length $schema_file;
  croak "usage schema file not found: $schema_file" unless -f $schema_file;

  my $sql = Langertha::Skeid::UsageStore::read_text_file($schema_file);
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

  my $dbh = DBI->connect($self->dsn, $self->user, $self->password, \%connect_attr);
  $self->_dbh($dbh);
  return $dbh;
}


sub disconnect {
  my ($self) = @_;
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
  return $self->_with_handle(sub {
    my ($dbh) = @_;
    return { ok => 1, $self->_insert($dbh, $event) };
  });
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
  return $batch if $batch->{ok};

  # No handle left: the reconnect failed, and one attempt per event would only repeat it.
  return $self->_lose(0, \@events, $batch->{error}) unless $self->_dbh;

  my ($written, $lost, $error) = (0, 0);
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
    $lost++;
    $error = $one->{error};
    $self->_report_lost($event, $error);
    next if $self->_dbh;
    # The handle died under the single writes and did not come back: the rest go with it.
    $lost += $self->_lose(0, \@events, $error)->{lost};
    last;
  }
  return $lost
    ? { ok => 0, written => $written, lost => $lost, error => $error }
    : { ok => 1, written => $written };
}

# Reports every event in $events as lost and answers the flush with it.
sub _lose {
  my ($self, $written, $events, $err) = @_;
  my $failure = $self->_failure($err);
  $self->_report_lost($_, $failure->{error}) for @$events;
  return { ok => 0, written => $written, lost => scalar(@$events), error => $failure->{error} };
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

sub _insert {
  my ($self, $dbh, $event) = @_;
  my $sth = $dbh->prepare_cached(q{
    INSERT INTO usage_events (
      created_at, request_id, api_format, endpoint, api_key_id, provider, engine, model, node_id, route_url,
      status_code, ok, duration_ms, input_tokens, output_tokens, total_tokens, cached_tokens, tool_calls,
      cost_input_usd, cost_output_usd, cost_total_usd, error_type, error_message, requested_model,
      content_bytes, cost_cache_read_usd, cost_cache_write_usd, cache_write_tokens
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  });
  $sth->execute(
    $event->{created_at},
    $event->{request_id},
    $event->{api_format},
    $event->{endpoint},
    $event->{api_key_id},
    $event->{provider},
    $event->{engine},
    $event->{model},
    $event->{node_id},
    $event->{route_url},
    $event->{status_code},
    $event->{ok},
    $event->{duration_ms},
    $event->{input_tokens},
    $event->{output_tokens},
    $event->{total_tokens},
    # Nullable: an event that carried no cache count writes NULL, not a measured zero.
    $event->{cached_tokens},
    $event->{tool_calls},
    $event->{cost_input_usd},
    $event->{cost_output_usd},
    $event->{cost_total_usd},
    $event->{error_type},
    $event->{error_message},
    ($event->{requested_model} // $event->{model} // ''),
    # Nullable: only a streamed request carries it; anything else writes NULL, "not measured".
    $event->{content_bytes},
    # Nullable: an event from a caller that does not price the cache apart writes NULL.
    $event->{cost_cache_read_usd},
    $event->{cost_cache_write_usd},
    # Nullable: an event that carried no cache write count writes NULL.
    $event->{cache_write_tokens},
  );

  return ($self->backend eq 'sqlite' && $dbh->can('sqlite_last_insert_rowid'))
    ? ( id => Langertha::Skeid::UsageStore::num($dbh->sqlite_last_insert_rowid) )
    : ();
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
       COALESCE(SUM(cost_total_usd), 0) AS total_cost_usd
     FROM usage_events
     $where_sql
     GROUP BY api_key_id
     ORDER BY total_cost_usd DESC, requests DESC",
    { Slice => {} },
    @bind,
  ) || [];

  my $by_model = $dbh->selectall_arrayref(
    "SELECT
       COALESCE(model, '') AS model,
       COUNT(*) AS requests,
       COALESCE(SUM(total_tokens), 0) AS total_tokens,
       COALESCE(SUM(cost_total_usd), 0) AS total_cost_usd
     FROM usage_events
     $where_sql
     GROUP BY model
     ORDER BY total_cost_usd DESC, requests DESC",
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
      total_cost_usd => $num->($totals->{total_cost_usd}),
    },
    by_key   => [ map {
      +{
        api_key_id     => ($_->{api_key_id} // ''),
        requests       => $num->($_->{requests}),
        total_tokens   => $num->($_->{total_tokens}),
        total_cost_usd => $num->($_->{total_cost_usd}),
      }
    } @$by_key ],
    by_model => [ map {
      +{
        model          => ($_->{model} // ''),
        requests       => $num->($_->{requests}),
        total_tokens   => $num->($_->{total_tokens}),
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

version 0.003

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

C<DBI> is loaded at runtime rather than compile time: a Skeid that never configures a database
backend must not require one to be installed.

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

=head2 prepare

Connects if possible and applies the schema when C<auto_migrate> is on: its C<CREATE TABLE>
statements, then any column an older table lacks (C<ALTER TABLE ... ADD COLUMN>; nothing is
ever dropped or rewritten), then the rest. Returns false without complaint when C<DBI> is
unavailable -- an unusable store degrades to "no usage recorded", it does not take the proxy
down. Croaks when the schema file does not exist; a failing connect or statement dies.

=head2 dbh

The cached database handle, connecting on first use. Returns nothing when C<DBI> is not
installed or no DSN is configured.

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
event tries again), and a failure on a live handle -- a dropped table, a constraint -- is
reported without a reconnect. There is no loop and no wait: at most one extra synchronous
connect per event, the cost ADR 0005 already accepts for this backend. The schema is not
re-applied on a reconnect; L</prepare> ran when the store was configured, and a lost connection
does not lose the table. One corner remains: a connection that drops after the server committed
the insert but before it answered is indistinguishable from one that dropped before, so that
event can be written twice. A duplicate row carries the same C<request_id>; a lost one leaves
nothing to reconcile.

=head2 flush

  my $res = $store->flush;

Writes every queued event in one transaction and empties the queue. Returns
C<< { ok => 1, written => $n } >>, or C<< { ok => 0, written => $n, lost => $m, error => … } >>
when some could not be written; each of those is also handed to L</on_lost>. Never dies, never
waits, never retries later: every queued event gets the one attempt a synchronous L</store>
would have given it.

A failing batch is rolled back, so nothing is half written. When the handle survived the failure
-- one event a constraint rejects, a dropped table -- the events are written one by one, so a
single bad event loses only itself. When the handle died, it is reconnected once and the batch
retried once, as for L</store>; a reconnect that fails loses the whole batch with one connect
attempt, not one per event. The duplicate corner of L</store> applies to a batch: a connection
that drops after the server committed but before it answered is retried as a whole.

Called by the flush timer, by L</disconnect>, by L</report> (so a report counts what was queued)
and by L</store> when it writes synchronously. L<Langertha::Skeid/flush_usage> calls it.

=head2 report

  my $report = $store->report(\%filters);

Aggregates in SQL: totals, per-key and per-model breakdowns, and the newest C<limit> events.
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
