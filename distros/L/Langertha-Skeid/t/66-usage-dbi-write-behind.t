use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use Test::File::ShareDir -share => {
  -dist => { 'Langertha-Skeid' => 'share' },
};
use Langertha::Skeid;
use Langertha::Skeid::Proxy;
use Langertha::Skeid::UsageStore;
use Langertha::Skeid::UsageStore::DBI;

# A DBI usage write used to be a synchronous insert and commit on the request path, made before
# the answer was rendered: the client and every other stream on the loop waited for the database
# (ADR 0005, skeid k78). usage_store.flush_interval_ms turns on write-behind: store() queues and
# answers at once, a Mojo::IOLoop timer writes the queue in one transaction. What this proves:
#
#   - the default is unchanged: 0 means a synchronous insert that returns its row id;
#   - with it on, the request is answered before the insert happens, and request.start /
#     request.finish stay paired;
#   - nothing is lost silently: the timer, disconnect (a reload replacing the store), destroying
#     the Skeid, a report and flush_usage all write the queue; what a flush cannot write is
#     reported per event, with the usual "usage event lost" line and never a key;
#   - one bad event loses only itself, and a dead database costs one reconnect per flush.

eval { require DBI; require DBD::SQLite; 1 } or plan skip_all => 'DBI/DBD::SQLite not available';

sub event {
  my ($request_id, %over) = @_;
  return {
    created_at   => '2026-09-30T00:00:00Z',
    request_id   => $request_id,
    api_format   => 'openai',
    endpoint     => '/v1/chat/completions',
    api_key_id   => 'k_test',
    model        => 'm1',
    node_id      => 'n1',
    status_code  => 200,
    ok           => 1,
    input_tokens => 7, output_tokens => 3, total_tokens => 10, tool_calls => 0,
    cost_input_usd => 0, cost_output_usd => 0, cost_total_usd => 0,
    %over,
  };
}

# Counted through a handle of its own, so the count never flushes or reuses the store's handle.
sub rows {
  my ($path, $request_id) = @_;
  my $dbh = DBI->connect("dbi:SQLite:dbname=$path", '', '', { RaiseError => 1, PrintError => 0 });
  my ($count) = defined $request_id
    ? $dbh->selectrow_array('SELECT COUNT(*) FROM usage_events WHERE request_id = ?', undef, $request_id)
    : $dbh->selectrow_array('SELECT COUNT(*) FROM usage_events');
  $dbh->disconnect;
  return $count;
}

sub new_store {
  my (%args) = @_;
  my $dir = tempdir(CLEANUP => 1);
  my $store = Langertha::Skeid::UsageStore::DBI->new(
    backend => 'sqlite',
    dsn     => "dbi:SQLite:dbname=$dir/usage.sqlite",
    path    => "$dir/usage.sqlite",
    %args,
  );
  $store->prepare;
  return ($store, "$dir/usage.sqlite");
}

# Runs $code inside the running loop -- where a request handler runs -- and returns what it
# returned. The loop stops right after, so a flush timer armed in $code has not fired yet.
sub in_loop {
  my ($code) = @_;
  my @r;
  Mojo::IOLoop->next_tick(sub { @r = $code->(); Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  return wantarray ? @r : $r[0];
}

# Runs the loop until $cond holds or $seconds pass.
sub run_until {
  my ($cond, $seconds) = @_;
  my $guard = Mojo::IOLoop->timer($seconds => sub { Mojo::IOLoop->stop });
  my $poll = Mojo::IOLoop->recurring(0.01 => sub { Mojo::IOLoop->stop if $cond->() });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($_) for $guard, $poll;
  return $cond->();
}

# --- Default unchanged: 0 is a synchronous insert, inside the loop as well -------------------
{
  my ($store, $path) = new_store();
  is $store->flush_interval_ms, 0, 'write-behind is off by default';
  my $res = in_loop(sub { $store->store(event('req-sync')) });
  ok $res->{ok} && $res->{id}, 'without it, store inserts at once and answers the row id';
  ok !$res->{queued}, 'and queues nothing';
  is rows($path, 'req-sync'), 1, 'the row is there when store returns';
}

# --- With it on: queued, not written, one transaction per flush -------------------------------
{
  my ($store, $path) = new_store(flush_interval_ms => 30);
  my $begun = 0;
  my @res = do {
    no warnings 'redefine';
    my $orig = \&DBI::db::begin_work;
    local *DBI::db::begin_work = sub { $begun++; goto &$orig };
    my @answers = in_loop(sub { map { $store->store(event("req-q$_")) } 1 .. 3 });
    is rows($path), 0, 'queued events are not written while the request path runs';
    ok run_until(sub { rows($path) == 3 }, 5), 'the flush timer writes them';
    @answers;
  };
  is_deeply [ map { $_->{queued} } @res ], [1, 1, 1], 'store answers queued';
  ok !(grep { !$_->{ok} || exists $_->{id} } @res), 'ok, and without a row id that does not exist yet';
  is $begun, 1, 'three events, one transaction';
  is rows($path, "req-q$_"), 1, "req-q$_ written exactly once" for 1 .. 3;
}

# --- No running loop: nothing would fire the timer, so store writes at once, in order --------
{
  my ($store, $path) = new_store(flush_interval_ms => 60_000);
  in_loop(sub { $store->store(event('req-first')) });
  is rows($path), 0, 'an event queued inside the loop waits';
  my $res = $store->store(event('req-second'));
  ok $res->{ok} && $res->{id}, 'outside the loop, store writes synchronously and answers the id';
  my $order = $store->dbh->selectcol_arrayref('SELECT request_id FROM usage_events ORDER BY id');
  is_deeply $order, ['req-first', 'req-second'], 'what was queued is written first';
}

# --- disconnect and report flush first --------------------------------------------------------
{
  my ($store, $path) = new_store(flush_interval_ms => 60_000);
  in_loop(sub { $store->store(event("req-d$_")) for 1 .. 2 });
  $store->disconnect;
  is rows($path), 2, 'disconnect writes the queue before it lets go of the handle';

  in_loop(sub { $store->store(event('req-report')) });
  my $report = $store->report({});
  is $report->{totals}{requests}, 3, 'a report counts what was queued before it was asked for';
}

# --- One bad event loses only itself, and is reported ------------------------------------------
{
  my ($store, $path) = new_store(flush_interval_ms => 60_000);
  my @lost;
  $store->on_lost(sub { push @lost, [@_] });
  in_loop(sub {
    $store->store(event('req-good-1'));
    $store->store(event('req-bad', created_at => undef));   # created_at is NOT NULL
    $store->store(event('req-good-2'));
  });
  my $res = $store->flush;
  ok !$res->{ok}, 'a flush that lost an event says so';
  is $res->{written}, 2, 'the good events are written';
  is $res->{lost}, 1, 'one is lost';
  is rows($path, 'req-good-1') + rows($path, 'req-good-2'), 2, 'both good events are in the table once';
  is rows($path, 'req-bad'), 0, 'the bad one is not';
  is scalar(@lost), 1, 'on_lost is called once';
  is $lost[0][0]{request_id}, 'req-bad', 'with the event that was lost';
  like $lost[0][1], qr/created_at/i, 'and the database error';
}

# --- A dead database: one reconnect for the whole flush, every event reported, no secret ------
{
  my ($store, $path) = new_store(flush_interval_ms => 60_000);
  my @lost;
  $store->on_lost(sub { push @lost, [@_] });
  in_loop(sub { $store->store(event("req-dead-$_")) for 1 .. 3 });
  $store->dbh->disconnect;

  my $connects = 0;
  my $res = do {
    no warnings qw( redefine once );
    local *DBI::connect = sub {
      $connects++;
      die "DBI connect('dbname=skeid;host=db;password=hunter2','skeid',...) failed: "
        . "could not connect to server: Connection refused\n";
    };
    eval { $store->flush };
  };
  is $@, '', 'a flush against a dead database does not die';
  is $res->{lost}, 3, 'the batch is reported lost';
  is $connects, 1, 'with one reconnect attempt, not one per event';
  is_deeply [ sort map { $_->[0]{request_id} } @lost ], [ map { "req-dead-$_" } 1 .. 3 ],
    'each lost event reaches on_lost';
  ok !(grep { $_->[1] =~ /hunter2/ } @lost), 'with no password in the error';

  ok $store->store(event('req-after'))->{ok}, 'once the database answers again, events are written';
  is rows($path, 'req-after'), 1, 'and are in the table';
}

# --- Config: carried, validated, compared on reload -------------------------------------------
{
  my $cfg = Langertha::Skeid::UsageStore->normalize_config({ sqlite_path => '/tmp/x.sqlite' });
  is $cfg->{flush_interval_ms}, 0, 'normalize_config defaults flush_interval_ms to 0';
  $cfg = Langertha::Skeid::UsageStore->normalize_config({ dsn => 'dbi:Pg:dbname=x', flush_interval_ms => 500 });
  is $cfg->{flush_interval_ms}, 500, 'and carries it for postgresql';
  for my $bad (-1, '1.5', 'soon') {
    eval { Langertha::Skeid::UsageStore->normalize_config({ sqlite_path => '/tmp/x.sqlite', flush_interval_ms => $bad }) };
    like $@, qr/flush_interval_ms/, "flush_interval_ms '$bad' is refused";
  }
  is(Langertha::Skeid::UsageStore->for_config($cfg)->flush_interval_ms, 500, 'for_config builds the store with it');
}

# --- Skeid: a reload that replaces the store, and destroying the Skeid, write the queue -------
{
  my $dir = tempdir(CLEANUP => 1);
  my $skeid = Langertha::Skeid->new(
    usage_store => { sqlite_path => "$dir/a.sqlite", flush_interval_ms => 60_000 },
  );
  my $res = in_loop(sub { $skeid->call_function('usage.record', { request_id => 'req-old-store', model => 'm1', ok => 1 }) });
  ok $res->{queued}, 'usage.record queues through the Skeid';
  is rows("$dir/a.sqlite"), 0, 'nothing written yet';

  $skeid->configure_usage_store({ sqlite_path => "$dir/b.sqlite", flush_interval_ms => 60_000 });
  is rows("$dir/a.sqlite", 'req-old-store'), 1, 'replacing the store writes its queue to its own table';

  in_loop(sub { $skeid->call_function('usage.record', { request_id => 'req-flush-usage', model => 'm1', ok => 1 }) });
  is_deeply $skeid->flush_usage, { ok => 1, written => 1 }, 'flush_usage writes what the store holds';
  is rows("$dir/b.sqlite", 'req-flush-usage'), 1, 'into the new table';

  $skeid->configure_usage_store({ sqlite_path => "$dir/b.sqlite", flush_interval_ms => 0 });
  is $skeid->_usage_store_obj->flush_interval_ms, 0, 'a changed flush_interval_ms rebuilds the store on reload';
  $skeid->configure_usage_store({ sqlite_path => "$dir/b.sqlite", flush_interval_ms => 60_000 });

  in_loop(sub { $skeid->call_function('usage.record', { request_id => 'req-demolish', model => 'm1', ok => 1 }) });
  undef $skeid;
  is rows("$dir/b.sqlite", 'req-demolish'), 1, 'destroying the Skeid writes the queue';
}

# --- Through the proxy: answered before the insert, paired, lost events logged ----------------
my $customer_key = 'sk-k78-customer-secret-do-not-log';

my $upstream = Mojolicious->new;
$upstream->log->level('fatal');
$upstream->routes->post('/v1/chat/completions' => sub {
  my ($c) = @_;
  $c->render(json => {
    id => 'c1', model => 'm1', object => 'chat.completion',
    choices => [{ index => 0, finish_reason => 'stop',
      message => { role => 'assistant', content => 'hello' } }],
    usage => { prompt_tokens => 7, completion_tokens => 3, total_tokens => 10 },
  });
});
my $up = Mojo::Server::Daemon->new(app => $upstream, listen => ['http://127.0.0.1'], silent => 1);
$up->start;
my $up_port = $up->ports->[0];
my $ua = Mojo::UserAgent->new;

sub serve_one {
  my ($skeid, $request_id) = @_;
  $skeid->add_node(id => 'n1', url => "http://127.0.0.1:$up_port/v1", model => 'm1', max_conns => 4)
    unless grep { $_->{id} eq 'n1' } @{ $skeid->nodes };
  my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
  my @logged;
  $proxy->log->level('warn');
  $proxy->log->unsubscribe('message');
  $proxy->log->on(message => sub {
    my ($log, $level, @lines) = @_;
    push @logged, { level => $level, text => join(' ', @lines) };
  });
  my $pd = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
  $pd->start;
  my $port = $pd->ports->[0];

  my $tx;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("http://127.0.0.1:$port/v1/chat/completions" => {
    Authorization  => "Bearer $customer_key",
    'x-request-id' => $request_id,
  } => json => { model => 'm1', messages => [{ role => 'user', content => 'hi' }] } => sub {
    (undef, $tx) = @_;
    Mojo::IOLoop->stop;
  });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);
  return ($tx, \@logged, $proxy, $pd);
}

{
  my $dir = tempdir(CLEANUP => 1);
  my $db = "$dir/usage.sqlite";
  my $skeid = Langertha::Skeid->new(
    route_wait_poll_ms => 5,
    usage_store => { sqlite_path => $db, flush_interval_ms => 60_000 },
  );
  my ($tx, $logged, $proxy, $pd) = serve_one($skeid, 'req-k78-proxy');
  is $tx->res->code, 200, 'proxy: the client gets its answer';
  is rows($db), 0, 'proxy: answered before the usage event was inserted';
  my $metrics = $skeid->node_metrics('n1');
  is $metrics->{inflight}, 0, 'proxy: nothing remains in flight';
  is $metrics->{ok} + $metrics->{error}, $metrics->{started}, 'proxy: request.start and request.finish paired';

  is $skeid->flush_usage->{written}, 1, 'proxy: flush_usage writes the queued event';
  is rows($db, 'req-k78-proxy'), 1, 'proxy: with the request id the client sent';
  is scalar(grep { $_->{text} =~ /usage event/ } @$logged), 0, 'proxy: nothing was lost, nothing logged';
  $pd->stop;
}

{
  my $dir = tempdir(CLEANUP => 1);
  my $skeid = Langertha::Skeid->new(
    route_wait_poll_ms => 5,
    usage_store => { sqlite_path => "$dir/usage.sqlite", flush_interval_ms => 20 },
  );
  $skeid->_usage_store_obj->dbh->do('DROP TABLE usage_events');

  my ($tx, $logged, $proxy, $pd) = serve_one($skeid, 'req-k78-lost');
  is $tx->res->code, 200, 'failing flush: the client still gets its answer';
  ok run_until(sub { grep { $_->{text} =~ /usage event/ } @$logged }, 5),
    'failing flush: the timer fires and the loss is logged';
  my @lost = grep { $_->{text} =~ /usage event/ } @$logged;
  is scalar(@lost), 1, 'failing flush: exactly one line for the lost event' or diag explain $logged;
  is $lost[0]{level}, 'error', 'failing flush: at error level';
  like $lost[0]{text}, qr/usage event lost: request_id=req-k78-lost\b/, 'failing flush: naming the request id';
  like $lost[0]{text}, qr/\bstore=sqlite\b/, 'failing flush: and the store';
  ok !(grep { $_->{text} =~ /\Q$customer_key\E/ } @$logged), 'failing flush: no line carries the customer key';
  $pd->stop;
}

$up->stop;
done_testing;
