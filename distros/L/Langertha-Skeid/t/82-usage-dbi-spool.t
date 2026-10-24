use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use JSON::MaybeXS qw(decode_json encode_json);
use Mojo::IOLoop;
use Test::File::ShareDir -share => {
  -dist => { 'Langertha-Skeid' => 'share' },
};
use Langertha::Skeid;
use Langertha::Skeid::UsageStore;
use Langertha::Skeid::UsageStore::DBI;

# Skeid on the edge keeps serving while the usage database is down (skeid k110, ADR 0023).
# Before, every event of the outage was reported lost and every event or flush paid one
# blocking connect against a host that did not answer. What this proves:
#
#   (a) with usage_store.spool_dir, what the database cannot take goes to a JSON Lines spool,
#       from a synchronous store and from a write-behind flush, and is not reported lost;
#   (b) the first write that succeeds replays the spool, inside the loop on a timer as well;
#   (c) a new store over the same spool dir -- a restart -- replays at prepare, and a store
#       prepared while the database is down starts anyway and migrates on the first connect;
#   (d) replay never adds a second row: an event already in the table, a spool replayed twice,
#       a replay cut into batches;
#   (e) after a failed connect, no connect is tried before the backoff deadline -- with and
#       without a spool -- and the deadline doubles, caps and resets;
#   (f) a spool line carries the event's columns only: no password, no DSN, no stray field.

eval { require DBI; require DBD::SQLite; 1 } or plan skip_all => 'DBI/DBD::SQLite not available';

# --- A database that can be switched off, and a clock that only moves when told ---------------
my $real_connect = \&DBI::connect;
my ($down, $connects) = (0, 0);
{
  no warnings 'redefine';
  *DBI::connect = sub {
    $connects++;
    die "DBI connect('dbname=usage;host=db.internal;password=hunter2','skeid',...) failed: "
      . "could not connect to server: Connection refused\n" if $down;
    goto &$real_connect;
  };
}
my $clock = 1000;
{
  no warnings 'redefine';
  *Langertha::Skeid::UsageStore::DBI::_now = sub { $clock };
}

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

sub event {
  my ($request_id, %over) = @_;
  return {
    created_at   => '2026-10-13T04:00:00Z',
    request_id   => $request_id,
    api_format   => 'openai',
    endpoint     => '/v1/chat/completions',
    api_key_id   => 'k_0123456789abcdef0123456789abcdef01234567',
    model        => 'm1',
    node_id      => 'n1',
    status_code  => 200,
    ok           => 1,
    input_tokens => 7, output_tokens => 3, total_tokens => 10, tool_calls => 0,
    cost_input_usd => 0, cost_output_usd => 0, cost_total_usd => 0.25,
    %over,
  };
}

# Counted through a handle of its own, never the store's and never through the counter.
sub rows {
  my ($path, $request_id) = @_;
  my $dbh = $real_connect->('DBI', "dbi:SQLite:dbname=$path", '', '', { RaiseError => 1, PrintError => 0 });
  my ($count) = defined $request_id
    ? $dbh->selectrow_array('SELECT COUNT(*) FROM usage_events WHERE request_id = ?', undef, $request_id)
    : $dbh->selectrow_array('SELECT COUNT(*) FROM usage_events');
  $dbh->disconnect;
  return $count;
}

sub spool_files {
  my ($dir) = @_;
  opendir(my $dh, $dir) or return ();
  my @files = sort grep { /\Ausage-spool-/ } readdir $dh;
  closedir $dh;
  return @files;
}

sub spool_lines {
  my ($dir) = @_;
  my @lines;
  for my $name (spool_files($dir)) {
    open my $fh, '<', File::Spec->catfile($dir, $name) or die $!;
    push @lines, <$fh>;
  }
  return @lines;
}

sub new_store {
  my (%args) = @_;
  my $dir = $args{dir} // tempdir(CLEANUP => 1);
  delete $args{dir};
  my $spool = exists $args{spool_dir} ? delete $args{spool_dir} : "$dir/spool";
  my $store = Langertha::Skeid::UsageStore::DBI->new(
    backend   => 'sqlite',
    dsn       => "dbi:SQLite:dbname=$dir/usage.sqlite",
    path      => "$dir/usage.sqlite",
    spool_dir => $spool,
    %args,
  );
  return ($store, "$dir/usage.sqlite", $spool, $dir);
}

# The database goes away under a running store: its handle dies, connects fail.
sub take_down {
  my ($store) = @_;
  my $dbh = $store->_dbh;
  $dbh->disconnect if $dbh;
  $down = 1;
}

sub bring_back {
  $down = 0;
  $clock += 3600;   # well past any backoff deadline
}

sub in_loop {
  my ($code) = @_;
  my @r;
  Mojo::IOLoop->next_tick(sub { @r = $code->(); Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  return wantarray ? @r : $r[0];
}

sub run_until {
  my ($cond, $seconds) = @_;
  my $guard = Mojo::IOLoop->timer($seconds => sub { Mojo::IOLoop->stop });
  my $poll = Mojo::IOLoop->recurring(0.01 => sub { Mojo::IOLoop->stop if $cond->() });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($_) for $guard, $poll;
  return $cond->();
}

# --- (a) + (f) synchronous store: spooled, not lost, columns only, no secret ----------------------
{
  my ($store, $db, $spool) = new_store();
  ok $store->prepare, 'prepared while the database is up';
  my @lost;
  $store->on_lost(sub { push @lost, [@_] });
  ok $store->store(event('req-up'))->{ok}, 'written while up';

  take_down($store);
  @warnings = ();
  my @res = map {
    $store->store(event("req-down-$_", api_key => 'sk-live-secret-must-not-spool'))
  } 1 .. 3;
  is_deeply \@res, [ map { { ok => 1, spooled => 1 } } 1 .. 3 ],
    'store answers spooled, not a failure, while the database is down';
  is scalar(@lost), 0, 'nothing is reported lost';
  is scalar(grep { /spool/ } @warnings), 1, 'the outage is said once, not per event'
    or diag explain \@warnings;
  unlike join('', @warnings), qr/hunter2/, 'and the warning carries no password';

  my @files = spool_files($spool);
  is scalar(@files), 1, 'one spool file for this process';
  like $files[0], qr/\Ausage-spool-[A-Za-z0-9._-]+-$$\.jsonl\z/, 'named by host and pid';

  my @lines = spool_lines($spool);
  is scalar(@lines), 3, 'one line per event';
  my @events = map { decode_json($_) } @lines;
  is_deeply [ map { $_->{request_id} } @events ], [ map { "req-down-$_" } 1 .. 3 ],
    'in the order they came';
  is $events[0]{api_key_id}, 'k_0123456789abcdef0123456789abcdef01234567', 'with the key id';
  is $events[0]{cost_total_usd}, 0.25, 'and the priced cost';
  ok !exists $events[0]{api_key}, 'a field that is not a column never reaches the spool';
  my $raw = join '', @lines;
  unlike $raw, qr/hunter2|password|dbi:|db\.internal|sk-live/i,
    'no password, no DSN, no key in the spool';

  # (b) the database comes back: the next write replays the spool.
  bring_back();
  my $back = $store->store(event('req-back'));
  ok $back->{ok} && $back->{id}, 'the first write after the outage is a normal insert';
  is rows($db, "req-down-$_"), 1, "req-down-$_ replayed exactly once" for 1 .. 3;
  is rows($db), 5, 'nothing else written';
  is_deeply [ spool_files($spool) ], [], 'the spool is gone once its events committed';
}

# --- (a) write-behind flush: the batch is spooled; (b) replay runs on a loop timer -------------
{
  my ($store, $db, $spool) = new_store(flush_interval_ms => 60_000);
  $store->prepare;
  my @lost;
  $store->on_lost(sub { push @lost, [@_] });
  in_loop(sub { $store->store(event("req-wb-$_")) for 1 .. 3 });
  take_down($store);
  my $res = $store->flush;
  is_deeply $res, { ok => 1, written => 0, spooled => 3 }, 'a flush against a dead database spools the batch';
  is scalar(@lost), 0, 'and loses nothing';
  is scalar(spool_lines($spool)), 3, 'three lines in the spool';

  bring_back();
  in_loop(sub { $store->store(event('req-wb-next')) });
  is $store->flush->{written}, 1, 'the next flush writes its own event';
  ok run_until(sub { rows($db) == 4 }, 5), 'and the replay timer writes the spool behind it';
  is rows($db, "req-wb-$_"), 1, "req-wb-$_ once" for 1 .. 3;
  ok run_until(sub { !spool_files($spool) }, 5), 'the spool is emptied';
}

# --- An event the database refuses on a live handle is not spooled -----------------------------
{
  my ($store, $db, $spool) = new_store(flush_interval_ms => 60_000);
  $store->prepare;
  my @lost;
  $store->on_lost(sub { push @lost, [@_] });
  in_loop(sub { $store->store(event('req-bad', created_at => undef)) });
  my $res = $store->flush;
  is $res->{lost}, 1, 'a refused event is lost, as before';
  is scalar(@lost), 1, 'and reported';
  is_deeply [ spool_files($spool) ], [], 'not spooled: a replay would only be refused again';
}

# --- (c) restart: a new store over the same spool dir replays at prepare -----------------------
{
  my ($store, $db, $spool, $dir) = new_store();
  $store->prepare;
  take_down($store);
  $store->store(event("req-restart-$_")) for 1 .. 2;
  is scalar(spool_lines($spool)), 2, 'two events spooled by the first process';
  undef $store;

  bring_back();
  my ($again) = new_store(dir => $dir);
  ok $again->prepare, 'the next store prepares';
  is rows($db, "req-restart-$_"), 1, "req-restart-$_ replayed at prepare" for 1 .. 2;
  is_deeply [ spool_files($spool) ], [], 'and the spool is empty';
}

# --- (c) a store prepared while the database is down starts, spools, then migrates -------------
{
  my ($store, $db, $spool) = new_store();
  $down = 1;
  @warnings = ();
  my $ok = eval { $store->prepare };
  is $@, '', 'prepare does not die when a spool is configured';
  ok $ok, 'and answers true';
  like join('', @warnings), qr/unreachable at start/, 'it warns';
  unlike join('', @warnings), qr/hunter2/, 'without the password';
  is_deeply $store->store(event('req-cold')), { ok => 1, spooled => 1 }, 'events go to the spool';

  bring_back();
  my $res = $store->store(event('req-warm'));
  ok $res->{ok} && $res->{id}, 'the first connect applies the schema and writes';
  is rows($db, 'req-cold'), 1, 'and the spool is replayed into the new table';

  my ($plain) = new_store(spool_dir => '');
  $down = 1;
  ok !eval { $plain->prepare; 1 }, 'without a spool, prepare still dies on a failed connect';
  $down = 0;
}

# --- (d) no duplicates ------------------------------------------------------------------------
{
  my ($store, $db, $spool) = new_store();
  $store->prepare;
  ok $store->store(event('req-dup'))->{ok}, 'an event that made it into the table';
  mkdir $spool;
  my $write_spool = sub {
    my ($name, @events) = @_;
    open my $fh, '>', File::Spec->catfile($spool, $name) or die $!;
    print {$fh} encode_json($_), "\n" for @events;
    close $fh;
  };
  # It is in the spool as well (its connection dropped after the commit), twice, from two files.
  $write_spool->('usage-spool-otherhost-1.jsonl', event('req-dup'), event('req-once'));
  $write_spool->('usage-spool-otherhost-2.jsonl.replay-otherhost-2-1', event('req-dup'), event('req-once'));
  my $res = $store->replay_spool;
  ok $res->{ok}, 'replay succeeds';
  is $res->{replayed}, 1, 'one row written';
  is $res->{consumed}, 4, 'four lines done with';
  is rows($db, 'req-dup'), 1, 'an event already present is not written again';
  is rows($db, 'req-once'), 1, 'one replayed twice is written once';

  # An interrupted replay: the commit went through, the spool file stayed. Again: no new row.
  $write_spool->('usage-spool-otherhost-3.jsonl', event('req-once'));
  is $store->replay_spool->{replayed}, 0, 'replaying committed events again writes nothing';
  is rows($db, 'req-once'), 1, 'still one row';

  # A client that reuses its x-request-id: a different event, kept.
  $write_spool->('usage-spool-otherhost-4.jsonl', event('req-once', created_at => '2026-10-13T05:00:00Z'));
  $store->replay_spool;
  is rows($db, 'req-once'), 2, 'the same request_id at another time is another event';

  # No request_id: no key; written once per replay -- at least once rather than lost.
  $write_spool->('usage-spool-otherhost-5.jsonl', event(''));
  $store->replay_spool;
  is rows($db, ''), 1, 'an event without a request_id is replayed';

  # A torn line is dropped with a warning; the rest of the file is replayed.
  open my $fh, '>', File::Spec->catfile($spool, 'usage-spool-otherhost-6.jsonl') or die $!;
  print {$fh} encode_json(event('req-before-torn')), "\n", '{"request_id":"req-to';
  close $fh;
  @warnings = ();
  ok $store->replay_spool->{ok}, 'a torn line does not stop the replay';
  is rows($db, 'req-before-torn'), 1, 'the readable line is written';
  is scalar(grep { /unreadable line/ } @warnings), 1, 'the torn one is warned about';
  is_deeply [ spool_files($spool) ], [], 'and the file is done';
}

# --- (d) a large spool is replayed in batches, each committed before its lines go --------------
{
  local $Langertha::Skeid::UsageStore::DBI::REPLAY_BATCH = 2;
  my ($store, $db, $spool) = new_store();
  $store->prepare;
  take_down($store);
  $store->store(event("req-batch-$_")) for 1 .. 5;
  bring_back();

  my $first = $store->replay_spool;
  is $first->{consumed}, 2, 'one replay takes one batch';
  ok $first->{remaining}, 'and says there is more';
  is rows($db), 2, 'two rows committed';
  is scalar(spool_lines($spool)), 3, 'and only their lines left the spool';

  my $guard = 0;
  $store->replay_spool while spool_files($spool) && $guard++ < 10;
  is rows($db, "req-batch-$_"), 1, "req-batch-$_ once" for 1 .. 5;
}

# --- A writer whose file was claimed by a replay appends to a new one ---------------------------
{
  my ($store, $db, $spool) = new_store();
  $store->prepare;
  take_down($store);
  $store->store(event('req-claimed'));
  my $res = $store->replay_spool;       # the database is still down: the file is claimed only
  ok !$res->{ok}, 'a replay against a dead database fails';
  my @files = spool_files($spool);
  is scalar(@files), 1, 'the spool file is kept';
  like $files[0], qr/\.replay-/, 'renamed for the replay';
  $store->store(event('req-after-claim'));
  is scalar(spool_files($spool)), 2, 'the next spooled event starts a new file';

  bring_back();
  $store->store(event('req-recovered'));
  is rows($db, $_), 1, "$_ written" for qw(req-claimed req-after-claim req-recovered);
  is_deeply [ spool_files($spool) ], [], 'both files replayed';
}

# --- (e) backoff: one connect per deadline, with and without a spool ---------------------------
for my $with_spool (1, 0) {
  my $label = $with_spool ? 'with spool' : 'without spool';
  my ($store, $db, $spool) = new_store(flush_interval_ms => 60_000, ($with_spool ? () : (spool_dir => '')));
  $store->prepare;
  my @lost;
  $store->on_lost(sub { push @lost, [@_] });
  take_down($store);
  $connects = 0;

  my @answers = map { $store->store(event("req-bo-$_")) } 1 .. 10;
  is $connects, 1, "$label: ten events while down cost one connect";
  if ($with_spool) {
    ok !(grep { !$_->{spooled} } @answers), "$label: all ten spooled";
  } else {
    ok !(grep { $_->{ok} } @answers), "$label: all ten fail";
    like $answers[-1]{error}, qr/next connect attempt in/, "$label: saying a connect is due later";
    like $answers[-1]{error}, qr/Connection refused/, "$label: and why the last one failed";
    unlike $answers[-1]{error}, qr/hunter2/, "$label: without the password";
  }
  for (1 .. 5) {
    in_loop(sub { $store->store(event("req-bo-q$_")) });
    $store->flush;
  }
  is $connects, 1, "$label: five flushes inside the window cost no connect";

  $clock += 0.9;
  $store->store(event('req-bo-early'));
  is $connects, 1, "$label: none before the 1s deadline";
  $clock += 0.2;
  $store->store(event('req-bo-due'));
  is $connects, 2, "$label: one when it is due";
  $clock += 1.5;
  $store->store(event('req-bo-doubled'));
  is $connects, 2, "$label: the next deadline is 2s away";
  $clock += 0.6;
  $store->store(event('req-bo-2s'));
  is $connects, 3, "$label: and is kept";

  $clock += 1000 for 1 .. 10;
  $store->store(event("req-bo-cap-$_")), $clock += 61 for 1 .. 10;
  ok $store->_backoff_s <= 60, "$label: the backoff caps at 60s";

  bring_back();
  ok $store->store(event('req-bo-up'))->{ok}, "$label: a successful connect";
  is $store->_backoff_s, 0, "$label: resets the backoff";
  take_down($store);
  $connects = 0;
  $store->store(event('req-bo-again'));
  $clock += 1.1;
  $store->store(event('req-bo-again-2'));
  is $connects, 2, "$label: and the next outage starts at 1s again";
  bring_back();
}

# --- Config: carried, validated, compared on reload --------------------------------------------
{
  my $cfg = Langertha::Skeid::UsageStore->normalize_config({ sqlite_path => '/tmp/x.sqlite' });
  is $cfg->{spool_dir}, '', 'normalize_config: spool_dir is off by default';
  $cfg = Langertha::Skeid::UsageStore->normalize_config({ dsn => 'dbi:Pg:dbname=x', spool_dir => '/var/lib/skeid/spool' });
  is $cfg->{spool_dir}, '/var/lib/skeid/spool', 'and carried for postgresql';
  is(Langertha::Skeid::UsageStore->for_config($cfg)->spool_dir, '/var/lib/skeid/spool', 'for_config builds the store with it');
  eval { Langertha::Skeid::UsageStore->normalize_config({ sqlite_path => '/tmp/x.sqlite', spool_dir => [] }) };
  like $@, qr/spool_dir/, 'a spool_dir that is not a path is refused';

  my $dir = tempdir(CLEANUP => 1);
  my $skeid = Langertha::Skeid->new(usage_store => { sqlite_path => "$dir/a.sqlite" });
  is $skeid->_usage_store_obj->spool_dir, '', 'Skeid: no spool unless configured';
  $skeid->configure_usage_store({ sqlite_path => "$dir/a.sqlite", spool_dir => "$dir/spool" });
  is $skeid->_usage_store_obj->spool_dir, "$dir/spool", 'Skeid: a changed spool_dir rebuilds the store';
}

done_testing;
