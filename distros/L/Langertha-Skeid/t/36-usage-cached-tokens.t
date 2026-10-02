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

# cached_tokens is the prompt-cache read count (k27). It is recorded on the usage event, read off
# the raw OpenAI-shaped upstream usage, and it must survive every store. Pricing is deliberately
# unchanged (ADR 0013) -- this file proves the count lands, not that it is discounted.

# --- The extraction helper reads every wire spelling, and 0 for none ---------------------------
{
  is(Langertha::Skeid::Proxy::_cached_tokens({ prompt_tokens => 100, prompt_tokens_details => { cached_tokens => 80 } }),
    80, 'OpenAI nested prompt_tokens_details.cached_tokens');
  is(Langertha::Skeid::Proxy::_cached_tokens({ cached_tokens => 42 }), 42, 'flat cached_tokens fallback');
  is(Langertha::Skeid::Proxy::_cached_tokens({ cached => 7 }), 7, 'normalized cached name');
  is(Langertha::Skeid::Proxy::_cached_tokens({ prompt_tokens => 100 }), 0, 'no cache field -> 0');
  is(Langertha::Skeid::Proxy::_cached_tokens(undef), 0, 'undef usage -> 0');
  is(Langertha::Skeid::Proxy::_cached_tokens({ prompt_tokens_details => 'not-a-hash' }), 0, 'malformed details -> 0');
}

# --- record_usage puts cached_tokens on the event, from each spelling --------------------------
{
  my @events;
  my $skeid = Langertha::Skeid->new(
    store_usage_event => sub { push @events, $_[1]; return { ok => 1 } },
  );

  # OpenAI wire spelling reaches record_usage directly here (no metrics.normalize in the way).
  $skeid->call_function('usage.record', {
    api_key_id => 'k_cache', model => 'm', ok => 1, status_code => 200,
    metrics => { usage => { prompt_tokens => 1000, completion_tokens => 50, total_tokens => 1050,
      prompt_tokens_details => { cached_tokens => 800 } } },
  });
  is($events[0]{cached_tokens}, 800, 'event carries cached_tokens from the nested OpenAI spelling');
  is($events[0]{input_tokens}, 1000, 'input tokens unaffected');

  $skeid->call_function('usage.record', {
    model => 'm', ok => 1, status_code => 200,
    metrics => { usage => { input => 10, output => 5, total => 15, cached => 3 } },
  });
  is($events[1]{cached_tokens}, 3, 'normalized cached name recorded');

  $skeid->call_function('usage.record', {
    model => 'm', ok => 1, status_code => 200,
    metrics => { usage => { input => 10, output => 5, total => 15 } },
  });
  is($events[2]{cached_tokens}, 0, 'absent cache field records 0, not undef');
  ok(defined($events[2]{cached_tokens}), 'cached_tokens is always defined on a fresh event');
}

# --- JsonLog: cached_tokens is written, reported, and old events read as zero ------------------
{
  my $dir = tempdir(CLEANUP => 1);
  my $skeid = Langertha::Skeid->new(usage_store => { backend => 'jsonlog', path => $dir });

  $skeid->call_function('usage.record', {
    api_key_id => 'k_a', model => 'gpt-4o-mini', ok => 1, status_code => 200,
    metrics => { usage => { prompt_tokens => 1000, completion_tokens => 20, total_tokens => 1020,
      prompt_tokens_details => { cached_tokens => 900 } } },
  });
  $skeid->call_function('usage.record', {
    api_key_id => 'k_a', model => 'gpt-4o-mini', ok => 1, status_code => 200,
    metrics => { usage => { input => 100, output => 10, total => 110 } },
  });

  my $report = $skeid->call_function('usage.report', {});
  is($report->{totals}{cached_tokens}, 900, 'jsonlog totals sum cached_tokens (900 + 0)');
  my ($cached_row) = grep { ($_->{cached_tokens} // -1) == 900 } @{$report->{recent}};
  ok($cached_row, 'jsonlog recent row carries cached_tokens');

  # An event file written before the field existed has no cached_tokens key at all.
  {
    open my $fh, '>', "$dir/legacy.json" or die $!;
    print $fh '{"created_at":"2020-01-01T00:00:00Z","api_key_id":"k_old","model":"m","ok":1,'
      . '"input_tokens":5,"output_tokens":5,"total_tokens":10}', "\n";
    close $fh;
  }
  my $report2 = $skeid->call_function('usage.report', {});
  is($report2->{totals}{cached_tokens}, 900, 'a legacy event with no cached_tokens counts as zero');
  is($report2->{totals}{requests}, 3, 'legacy event is still counted');
}

# --- SQLite: fresh schema has the column; insert writes it; report reflects it -----------------
SKIP: {
  eval { require DBI; require DBD::SQLite; 1 } or skip 'DBI/DBD::SQLite not available', 6;

  my $dir = tempdir(CLEANUP => 1);
  my $db  = "$dir/usage.sqlite";
  my $skeid = Langertha::Skeid->new(usage_store => { backend => 'sqlite', sqlite_path => $db });

  $skeid->call_function('usage.record', {
    api_key_id => 'k_db', model => 'served', ok => 1, status_code => 200,
    metrics => { usage => { prompt_tokens => 2000, completion_tokens => 60, total_tokens => 2060,
      prompt_tokens_details => { cached_tokens => 1500 } } },
  });

  my $report = $skeid->call_function('usage.report', { limit => 5 });
  is($report->{totals}{cached_tokens}, 1500, 'sqlite totals sum cached_tokens');
  is($report->{recent}[0]{cached_tokens}, 1500, 'sqlite recent row carries cached_tokens');

  my $dbh = DBI->connect("dbi:SQLite:dbname=$db", '', '', { RaiseError => 1, PrintError => 0 });
  my $cols = $dbh->selectall_arrayref('PRAGMA table_info(usage_events)', { Slice => {} });
  my @cached = grep { $_->{name} eq 'cached_tokens' } @$cols;
  is(scalar(@cached), 1, 'fresh sqlite schema has exactly one cached_tokens column');
  my ($stored) = $dbh->selectrow_array('SELECT cached_tokens FROM usage_events');
  is($stored, 1500, 'the value round-trips through the sqlite column');
  $dbh->disconnect;

  ok($report->{totals}{cached_tokens} == 1500, 'value is a number, not a string');
  is($report->{totals}{requests}, 1, 'one request recorded');
}

# --- SQLite migration: an old table gains the column additively; old rows read NULL ------------
SKIP: {
  eval { require DBI; require DBD::SQLite; 1 } or skip 'DBI/DBD::SQLite not available', 5;

  my $dir = tempdir(CLEANUP => 1);
  my $db  = "$dir/old.sqlite";

  # A table shaped like the schema *before* cached_tokens existed (it already has requested_model,
  # which the previous additive migration added -- this proves the two ALTERs stack).
  my $dbh = DBI->connect("dbi:SQLite:dbname=$db", '', '', { RaiseError => 1, PrintError => 0 });
  $dbh->do(q{
    CREATE TABLE usage_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      created_at TEXT NOT NULL, request_id TEXT, api_format TEXT, endpoint TEXT,
      api_key_id TEXT, provider TEXT, engine TEXT, model TEXT, requested_model TEXT,
      node_id TEXT, route_url TEXT, status_code INTEGER, ok INTEGER NOT NULL DEFAULT 0,
      duration_ms INTEGER, input_tokens INTEGER NOT NULL DEFAULT 0,
      output_tokens INTEGER NOT NULL DEFAULT 0, total_tokens INTEGER NOT NULL DEFAULT 0,
      tool_calls INTEGER NOT NULL DEFAULT 0, cost_input_usd REAL NOT NULL DEFAULT 0,
      cost_output_usd REAL NOT NULL DEFAULT 0, cost_total_usd REAL NOT NULL DEFAULT 0,
      error_type TEXT, error_message TEXT
    )
  });
  $dbh->do(q{INSERT INTO usage_events (created_at, api_key_id, model, ok, input_tokens, output_tokens, total_tokens)
             VALUES ('2020-01-01T00:00:00Z', 'k_legacy', 'legacy-model', 1, 10, 5, 15)});
  $dbh->disconnect;

  # prepare() runs on construction and must add the missing column without touching the old row.
  my $skeid = Langertha::Skeid->new(usage_store => { backend => 'sqlite', sqlite_path => $db });
  my $written = $skeid->call_function('usage.record', {
    api_key_id => 'k_new', model => 'new-model', ok => 1, status_code => 200,
    metrics => { usage => { prompt_tokens => 500, completion_tokens => 10, total_tokens => 510,
      prompt_tokens_details => { cached_tokens => 400 } } },
  });
  ok($written->{ok}, 'an event still writes against an upgraded table');

  my $dbh2 = DBI->connect("dbi:SQLite:dbname=$db", '', '', { RaiseError => 1, PrintError => 0 });
  my $legacy = $dbh2->selectrow_hashref(q{SELECT cached_tokens FROM usage_events WHERE api_key_id = 'k_legacy'});
  ok(!defined($legacy->{cached_tokens}), 'the pre-existing row reads NULL, not a spurious zero');
  my $fresh = $dbh2->selectrow_hashref(q{SELECT cached_tokens FROM usage_events WHERE api_key_id = 'k_new'});
  is($fresh->{cached_tokens}, 400, 'the new row carries the cache count');

  # Idempotent: a second prepare (a second process opening the same db) must not add it twice.
  Langertha::Skeid->new(usage_store => { backend => 'sqlite', sqlite_path => $db });
  my $cols = $dbh2->selectall_arrayref('PRAGMA table_info(usage_events)', { Slice => {} });
  my @cached = grep { $_->{name} eq 'cached_tokens' } @$cols;
  is(scalar(@cached), 1, 're-preparing does not duplicate the column');

  my $report = $skeid->call_function('usage.report', {});
  is($report->{totals}{cached_tokens}, 400, 'report sums cached across a mix of NULL and valued rows');
  $dbh2->disconnect;
}

# --- End to end, non-streaming: the count is pulled off the raw upstream JSON usage ------------
{
  my $upstream = Mojolicious->new;
  $upstream->log->level('fatal');
  $upstream->routes->post('/v1/chat/completions' => sub {
    my ($c) = @_;
    $c->render(json => {
      id => 'c1', model => 'served', object => 'chat.completion',
      choices => [{ index => 0, finish_reason => 'stop',
        message => { role => 'assistant', content => 'hi' } }],
      usage => { prompt_tokens => 1000, completion_tokens => 50, total_tokens => 1050,
        prompt_tokens_details => { cached_tokens => 800 } },
    });
  });
  my $up = Mojo::Server::Daemon->new(app => $upstream, listen => ['http://127.0.0.1'], silent => 1);
  $up->start;
  my $up_port = $up->ports->[0];

  my @events;
  my $skeid = Langertha::Skeid->new(
    store_usage_event => sub { push @events, $_[1]; return { ok => 1 } },
  );
  $skeid->add_node(id => 'json-1', url => "http://127.0.0.1:$up_port/v1",
    model => 'cache-model', engine => 'openai', healthy => 1, max_conns => 4);

  my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
  $proxy->log->level('fatal');
  my $pd = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
  $pd->start;
  my $p_port = $pd->ports->[0];

  # Drive the global IOLoop the daemons listen on -- a blocking $ua->post would spin the agent's
  # own loop, where the daemons are not registered, and never connect.
  my $ua = Mojo::UserAgent->new;
  my $tx = $ua->build_tx(POST => "http://127.0.0.1:$p_port/v1/chat/completions",
    { 'Content-Type' => 'application/json' },
    json => { model => 'cache-model', messages => [{ role => 'user', content => 'hi' }] });
  my $timeout = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->start($tx => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($timeout);

  is($tx->res->code, 200, 'non-streaming response returns 200');
  is(scalar(@events), 1, 'one usage event for one request');
  is($events[0]{cached_tokens}, 800, 'non-streaming: cached_tokens pulled off the raw upstream usage');
  is($events[0]{input_tokens}, 1000, 'non-streaming: input tokens still recorded');
}

# --- End to end, streaming: the count is accumulated from the final SSE usage frame ------------
{
  my @FRAMES = (
    qq{data: {"id":"c1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":"Hi"},"finish_reason":null}]}\n\n},
    qq{data: {"id":"c1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{},"finish_reason":"stop"}],"usage":{"prompt_tokens":1000,"completion_tokens":5,"total_tokens":1005,"prompt_tokens_details":{"cached_tokens":700}}}\n\n},
    qq{data: [DONE]\n\n},
  );

  my $upstream = Mojolicious->new;
  $upstream->log->level('fatal');
  $upstream->routes->post('/v1/chat/completions' => sub {
    my ($c) = @_;
    $c->render_later;
    $c->res->code(200);
    $c->res->headers->content_type('text/event-stream');
    my @pending = @FRAMES;
    my $write;
    $write = sub {
      my $frame = shift @pending;
      return $c->finish unless defined $frame;
      $c->write_chunk($frame => sub { $write->() });
    };
    Mojo::IOLoop->timer(0.05 => $write);
  });
  my $up = Mojo::Server::Daemon->new(app => $upstream, listen => ['http://127.0.0.1'], silent => 1);
  $up->start;
  my $up_port = $up->ports->[0];

  my @events;
  my $skeid = Langertha::Skeid->new(
    store_usage_event => sub { push @events, $_[1]; return { ok => 1 } },
  );
  $skeid->add_node(id => 'stream-1', url => "http://127.0.0.1:$up_port/v1",
    model => 'stream-model', engine => 'openai', healthy => 1, max_conns => 4);

  my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
  $proxy->log->level('fatal');
  my $pd = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
  $pd->start;
  my $p_port = $pd->ports->[0];

  my $ua = Mojo::UserAgent->new;
  my $tx = $ua->build_tx(POST => "http://127.0.0.1:$p_port/v1/chat/completions",
    { 'Content-Type' => 'application/json' },
    json => { model => 'stream-model', stream => \1, messages => [{ role => 'user', content => 'hi' }] });
  $tx->res->content->unsubscribe('read')->on(read => sub { });

  my $timeout = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->start($tx => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($timeout);

  is($tx->res->code, 200, 'streamed response returns 200');
  is(scalar(@events), 1, 'one usage event for one streamed request');
  is($events[0]{cached_tokens}, 700, 'streaming: cached_tokens accumulated from the final SSE usage frame');
  is($events[0]{input_tokens}, 1000, 'streaming: input tokens still accumulated');
}

done_testing;
