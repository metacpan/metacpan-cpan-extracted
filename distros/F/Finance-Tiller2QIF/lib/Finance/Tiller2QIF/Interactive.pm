package Finance::Tiller2QIF::Interactive;
# ABSTRACT: Review and correct an isolated import before publishing it
$Finance::Tiller2QIF::Interactive::VERSION = '1.23';
use 5.036;
use utf8;
use warnings FATAL => 'utf8';
use open ':std', ':encoding(UTF-8)';
use Path::Tiny;
use File::Temp qw(tempdir tempfile);
use Fcntl qw(:flock);
use IO::Handle;
use Digest::SHA ();
use Cpanel::JSON::XS;
use DBD::SQLite::Constants qw(SQLITE_OK SQLITE_DENY SQLITE_ATTACH SQLITE_DETACH
  SQLITE_PRAGMA SQLITE_TRANSACTION SQLITE_SAVEPOINT);
use Finance::Tiller2QIF::DB qw(connect_db);
use Finance::Tiller2QIF::ReadCSV;
use Finance::Tiller2QIF::Map;
use Finance::Tiller2QIF::WriteQIF;

=head1 DESCRIPTION

The C<interactive> CLI command rebuilds an isolated database from a fixed
checkpoint and input CSV, then applies current mapping, hooks, and session SQL.
Only explicit export publishes the database and QIF. Session artifacts are
retained. A publication journal permits rollback after an interrupted install.

=head1 FUNCTIONS

=head2 Run

  Finance::Tiller2QIF::Interactive::Run(\%options);

Run the interactive CLI session with resolved CLI options. Returns 1 after
publication, 0 on cancellation, and dies on an unrecovered error. Refresh errors
are reported within the session so the user can repair files and retry.

=cut

{
  package Finance::Tiller2QIF::Interactive::_DatabaseGuard;
$Finance::Tiller2QIF::Interactive::_DatabaseGuard::VERSION = '1.23';
  sub DESTROY ($self) {
    local $@;
    eval {
      $self->[0]->rollback unless $self->[0]{AutoCommit};
      $self->[0]->disconnect;
    };
  }
}

# Database/QIF copies and hashes are binary file transport, not text decoding.
sub _digest ($file) {
  return undef unless -e $file;
  my $fh = path($file)->openr_raw;
  return Digest::SHA->new(256)->addfile($fh)->hexdigest;
}

sub _same ($a, $b) { return ($a // '') eq ($b // '') }

sub _sync ($file) {
  # Windows uses normal OS buffering; power-loss durability is not required.
  # This also bypasses directory fsync, which Windows does not support here.
  return if $^O eq 'MSWin32';
  my $fh = path($file)->openr_raw;
  $fh->sync or die "Cannot sync $file: $!\n";
  close $fh or die "Cannot close $file: $!\n";
}

sub _sync_directory ($file) {
  _sync(path($file)->parent);
}

# Stage in the destination directory so rename cannot cross filesystems.
sub _install ($source, $target) {
  my ($fh, $stage) = tempfile('.tiller2qif-install-XXXXXXXX',
    DIR => path($target)->parent->stringify, UNLINK => 0);
  close $fh or die "Cannot close $stage: $!\n";
  path($source)->copy($stage);
  chmod((stat($source))[2] & 0777, $stage) or die "Cannot chmod $stage: $!\n";
  _sync($stage);
  rename $stage, $target or die "Cannot install $target: $!\n";
  _sync_directory($target);
}

sub _journal ($file, $record) {
  my ($fh, $stage) = tempfile('.tiller2qif-journal-XXXXXXXX',
    DIR => path($file)->parent->stringify, UNLINK => 0);
  close $fh or die "Cannot close $stage: $!\n";
  path($stage)->spew_utf8(Cpanel::JSON::XS->new->canonical->encode($record));
  _sync($stage);
  rename $stage, $file or die "Cannot install journal $file: $!\n";
  _sync_directory($file);
}

sub _recover ($journal) {
  return unless -e $journal;
  my $record = Cpanel::JSON::XS->new->decode(path($journal)->slurp_utf8);
  if ($record->{state} ne 'committed') {
    # Refuse to overwrite an unrelated edit made after the interrupted session.
    for my $entry ($record->{files}->@*) {
      my $now = _digest($entry->{target});
      die "Recovery conflict at $entry->{target}; inspect $journal\n"
        unless _same($now, $entry->{old}) || _same($now, $entry->{new});
      die "Recovery backup changed: $entry->{backup}\n"
        if defined $entry->{old} && !_same(_digest($entry->{backup}), $entry->{old});
    }
    for my $entry (reverse $record->{files}->@*) {
      next if _same(_digest($entry->{target}), $entry->{old});
      if (defined $entry->{old}) { _install($entry->{backup}, $entry->{target}) }
      else {
        unlink $entry->{target} or die "Cannot restore absent $entry->{target}: $!\n";
        _sync_directory($entry->{target});
      }
    }
    say 'Rolled back interrupted publication; originals restored.';
  }
  unlink $journal or die "Cannot remove publication journal $journal: $!\n";
  _sync_directory($journal);
}

sub _publish ($session, $db, $qif) {
  my @files;
  for my $pair ([$db, $session->{db}, 'database'], [$qif, $session->{output}, 'output']) {
    my ($source, $target, $name) = @$pair;
    my $old = _digest($target);
    die "$target changed outside the session; export refused\n"
      unless _same($old, $session->{original}{$name});
    my $backup = "$session->{dir}/original-$name";
    if (defined $old) {
      path($target)->copy($backup);
      chmod((stat($target))[2] & 0777, $backup) or die "Cannot chmod $backup: $!\n";
      _sync($backup);
      _sync_directory($backup);
    }
    _sync($source);
    _sync_directory($source);
    push @files, { target => $target, source => $source, backup => $backup,
      old => $old, new => _digest($source) };
  }
  my $record = { state => 'pending', files => \@files };
  _journal($session->{journal}, $record);
  my $ok = eval {
    # Keep the recoverable interval small: all generation has already finished.
    for my $entry (@files) { _install($entry->{source}, $entry->{target}) }
    $record->{state} = 'committed';
    _journal($session->{journal}, $record);
    1;
  };
  if (!$ok) {
    my $error = $@;
    # The committed marker is the commit point. A signal or sync error after
    # that rename must not report an unsuccessful session with published data.
    my $installed = eval {
      Cpanel::JSON::XS->new->decode(path($session->{journal})->slurp_utf8)->{state}
        eq 'committed';
    };
    if ($installed) {
      warn "Publication committed; journal cleanup deferred: $error";
      return;
    }
    eval { _recover($session->{journal}); 1 }
      or die "$error\nRollback requires recovery using $session->{journal}: $@";
    die $error;
  }
  # A committed journal is harmless if cleanup is interrupted.
  eval { _recover($session->{journal}); 1 } or warn $@;
}

sub _prepare_sql ($dbh) {
  # Corrections and hooks operate only on the working database. Transaction
  # boundaries are owned by the session, and PRAGMA cannot enable WAL sidecars.
  my %denied = map { $_ => 1 } (SQLITE_ATTACH, SQLITE_DETACH, SQLITE_PRAGMA,
    SQLITE_TRANSACTION, SQLITE_SAVEPOINT);
  $dbh->sqlite_set_authorizer(sub { $denied{$_[0]} ? SQLITE_DENY : SQLITE_OK });
}

sub _sql ($dbh, $file, $verbose=0) {
  local $dbh->{sqlite_allow_multiple_statements} = 1;
  $dbh->do(path($file)->slurp_utf8);
  say "Applied SQL: $file" if $verbose;
}

sub _sources ($session) {
  return { map { $_ => _digest($session->{options}{$_}) }
    grep { defined $session->{options}{$_} } qw(mapfile beforemap aftermap corrections) };
}

sub _signature ($sources) {
  return Cpanel::JSON::XS->new->canonical->encode($sources);
}

sub _refresh ($session) {
  my $generation = ++$session->{generation};
  my $dir = "$session->{dir}/review-$generation";
  path($dir)->mkpath;
  my %options = $session->{options}->%*;
  my $sources = _sources($session);
  for my $key (keys %$sources) {
    die "Missing $key file: $options{$key}\n" unless defined $sources->{$key};
    my $copy = "$dir/$key";
    path($options{$key})->copy($copy);
    die "$options{$key} changed while reading; refresh again\n"
      unless _same(_digest($copy), $sources->{$key});
    $options{$key} = $copy;
  }
  my $db = "$dir/working.sqlite3";
  path($session->{baseline})->copy($db);
  Finance::Tiller2QIF::ReadCSV::Ingest($session->{input}, $db, $options{verbose}, 1);
  $options{db_path} = $db;
  $options{strict} = 1;
  $options{prepare_db} = \&_prepare_sql;
  $options{sql_runner} = \&_sql;
  if ($options{mapfile}) { Finance::Tiller2QIF::Map::Map(\%options) }
  else {
    my $dbh = connect_db($db);
    _prepare_sql($dbh);
    _sql($dbh, $options{$_}, $options{verbose})
      for grep { $options{$_} } qw(beforemap aftermap);
    $dbh->disconnect;
  }
  my $dbh = connect_db($db);
  _prepare_sql($dbh);
  _sql($dbh, $options{corrections}, $options{verbose});
  $dbh->disconnect;
  my ($count, $text) = Finance::Tiller2QIF::WriteQIF::_preview_text($db);
  my $preview = "$dir/preview.t2qpv";
  path($preview)->spew_utf8($text);
  chmod 0400, $preview or die "Cannot make preview read-only: $!\n";
  $session->{review} = { db => $db, preview => $preview, count => $count,
    signature => _signature($sources), digest => _digest($db) };
  $session->{valid} = 1;
}

sub _view ($session) {
  my $review = $session->{review};
  my $viewer = $session->{options}{viewer};
  if (lc $viewer eq 'console') {
    print path($review->{preview})->slurp_utf8 if $review;
  }
  else {
    my @files = ($review ? ($review->{preview}) : (),
      $session->{options}{mapfile} ? ($session->{options}{mapfile}) : (),
      $session->{options}{corrections});
    if ($^O eq 'MSWin32') {
      Finance::Tiller2QIF::WriteQIF::_launch_windows_viewer($viewer, @files);
    }
    else {
      my $cmd = join ' ', $viewer,
        map { Finance::Tiller2QIF::WriteQIF::_shell_quote($_) } @files;
      die "preview viewer '$viewer' failed\n" if system($cmd);
    }
  }
  say "$review->{count} transaction(s) in last successful preview." if $review;
}

sub Run ($options) {
  my %options = %$options;
  for my $key (qw(db_path output input mapfile beforemap aftermap)) {
    next unless defined $options{$key};
    my $file = path($options{$key})->absolute;
    die "Interactive paths must not be symlinks: $file\n" if -l $file;
    $options{$key} = $file->parent->realpath->child($file->basename)->stringify;
    die "Not a regular file: $file\n" if -e $file && !-f $file;
  }
  die "interactive requires an existing database; use newdb first\n" unless -f $options{db_path};
  for my $target_key (qw(db_path output)) {
    my $target = $options{$target_key};
    for my $key (qw(db_path output input mapfile beforemap aftermap)) {
      next if $key eq $target_key || !defined $options{$key};
      my $file = $options{$key};
      my @a = stat($target);
      my @b = stat($file);
      die "Database and output must be distinct from all input files\n"
        if $file eq $target || (@a && @b && $a[0] == $b[0] && $a[1] == $b[1]);
    }
  }
  my $db = $options{db_path};
  for my $reserved ("$db.interactive.lock", "$db.interactive.json") {
    die "Interactive metadata must not be a symlink: $reserved\n" if -l $reserved;
    die "Interactive metadata path is reserved: $reserved\n"
      if grep { defined $_ && $_ eq $reserved } @options{qw(output input mapfile beforemap aftermap)};
  }
  my $lock = path("$db.interactive.lock")->opena_utf8;
  flock($lock, LOCK_EX | LOCK_NB) or die "Another interactive session is using $db\n";
  my $journal = "$db.interactive.json";
  _recover($journal);
  my $guard = connect_db($db);
  my $release = bless [$guard], 'Finance::Tiller2QIF::Interactive::_DatabaseGuard';
  die "Interactive sessions require a rollback-journal database, not WAL\n"
    if lc($guard->selectrow_array('PRAGMA journal_mode')) eq 'wal';
  $guard->do('BEGIN EXCLUSIVE');
  my $dir = tempdir('.tiller2qif-session-XXXXXXXX', DIR => path($db)->parent->stringify, CLEANUP => 0);
  say "Interactive session artifacts: $dir";
  my $session = { dir => $dir, db => $db, output => $options{output}, journal => $journal,
    baseline => "$dir/checkpoint.sqlite3", input => "$dir/input.csv", generation => 0,
    original => { database => _digest($db), output => _digest($options{output}) } };
  path($db)->copy($session->{baseline});
  chmod((stat($db))[2] & 0777, $session->{baseline})
    or die "Cannot preserve database permissions: $!\n";
  path($options{input})->copy($session->{input});
  $options{corrections} = "$dir/corrections.t2qsql";
  path($options{corrections})->spew_utf8(<<'SQL');
-- Session corrections run AFTER mapping and aftermap on every fresh rebuild.
-- Use full transaction IDs from the preview. Save, then choose Apply/refresh.
-- UPDATE transactions SET mapped_category = 'Expenses:Food' WHERE id = 'ID';
-- UPDATE transactions SET payee = 'Corrected name' WHERE id = 'ID';
-- UPDATE transactions SET skipped = 0, exported = 0 WHERE id = 'ID';
-- Removing a statement removes its effect on the next refresh.
-- ATTACH, DETACH, PRAGMA and explicit transactions are not supported.
SQL
  $session->{options} = \%options;
  say "Corrections SQL: $options{corrections}";
  my $interrupted = 0;
  local $SIG{INT} = local $SIG{TERM} = sub {
    $interrupted = 1;
    die "Interactive session interrupted; artifacts: $dir\n";
  };
  my $refresh = sub {
    $session->{valid} = 0;
    if (!eval { _refresh($session); 1 }) {
      die $@ if $interrupted;
      warn "Refresh failed: $@";
    }
    _view($session);
  };
  $refresh->();
  while (1) {
    say 'A=Apply and refresh, V=View/edit, E=Export, C=Cancel';
    my $answer = <STDIN>;
    if (!defined $answer || $answer =~ /^\s*[cn]\s*$/i) {
      say "Session cancelled; original database and QIF unchanged. Artifacts: $dir";
      return 0;
    }
    if ($answer =~ /^\s*a\s*$/i) { $refresh->(); next }
    if ($answer =~ /^\s*v\s*$/i) { _view($session); next }
    if ($answer !~ /^\s*[ey]\s*$/i) { say 'Choose A, V, E, or C.'; next }
    if (!$session->{valid}
      || $session->{review}{signature} ne _signature(_sources($session))
      || !_same($session->{review}{digest}, _digest($session->{review}{db}))) {
      say 'Apply and refresh successfully before exporting saved changes.';
      next;
    }
    my $export_db = "$dir/export.sqlite3";
    my $export_qif = "$dir/export.qif";
    path($session->{review}{db})->copy($export_db);
    chmod((stat($session->{baseline}))[2] & 0777, $export_db)
      or die "Cannot preserve database permissions: $!\n";
    my $count = Finance::Tiller2QIF::WriteQIF::Emit($export_db, $export_qif,
      $options{verbose}, $options{qifdate});
    chmod((stat($options{output}))[2] & 0777, $export_qif)
      or die "Cannot preserve output permissions: $!\n" if -e $options{output};
    # Windows cannot replace a database while SQLite has it open. The session
    # lock remains held, and _publish rechecks the original file digests.
    $guard->disconnect if $^O eq 'MSWin32';
    _publish($session, $export_db, $export_qif);
    say "QIF written: $options{output}, $count records emitted! Session committed.";
    return 1;
  }
}

1;
