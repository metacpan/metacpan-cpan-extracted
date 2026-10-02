use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use JSON::MaybeXS qw(encode_json);
use Test::File::ShareDir -share => {
  -dist => { 'Langertha-Skeid' => 'share' },
};
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# A streamed request is billed exactly like the same request answered in one piece (skeid #41).
# The usage event is the billing unit (ADR 0004); a stream whose event carried cost 0 gave every
# streaming customer their tokens for free. The stream keeps the upstream's usage block verbatim
# and prices it through the same metrics.normalize call (Langertha::Usage + Langertha::Pricing)
# as a non-streamed answer, cache rates included (ADR 0013 update) -- on every client face,
# since the face is a translation at the edge (ADR 0001) and must not change the bill.
# Usage counts on a stream are running totals: a block split over frames is completed, and a
# total repeated on every chunk is not summed into a multiple of itself.

my $CORE_PRICES_CACHE = Langertha::Cost->can('cache_read_usd') ? 1 : 0;

sub near {
  my ($got, $expected, $name) = @_;
  my $ok = defined($got) && abs($got - $expected) < 1e-12;
  ok($ok, $name) or diag(sprintf('got %s, expected %.10f', $got // 'undef', $expected));
}

my %RULE = (
  input_per_million        => 3,
  output_per_million       => 15,
  cached_input_per_million => 0.30,
  cache_write_per_million  => 3.75,
);
my %PLAIN_RULE = (input_per_million => 3, output_per_million => 15);

# OpenAI Chat: 1000 prompt tokens, of which 800 cache reads and 100 cache writes, 50 output.
my %OPENAI_USAGE = (prompt_tokens => 1000, completion_tokens => 50, total_tokens => 1050,
  prompt_tokens_details => { cached_tokens => 800, cache_write_tokens => 100 });
# Anthropic spelling: 200 fresh input beside 800 cache reads and 400 cache writes, 50 output.
my %ANTHROPIC_USAGE = (input_tokens => 200, output_tokens => 50,
  cache_read_input_tokens => 800, cache_creation_input_tokens => 400);

# The usage the non-streamed answer carries, per model.
my %USAGE = (
  'openai-model'       => \%OPENAI_USAGE,
  'anthropic-model'    => \%ANTHROPIC_USAGE,
  'split-model'        => \%OPENAI_USAGE,
  'running-model'      => \%OPENAI_USAGE,
  'cut-after-usage'    => \%OPENAI_USAGE,
  'cut-before-usage'   => \%OPENAI_USAGE,
);

# The usage frames each model's stream carries, in order, one per content chunk plus the final
# frame (undef = no usage on that frame).
my %STREAM_USAGE = (
  # OpenAI include_usage: only the final frame carries it.
  'openai-model'    => [ undef, undef, undef, { %OPENAI_USAGE } ],
  'anthropic-model' => [ undef, undef, undef, { %ANTHROPIC_USAGE } ],
  # Input on the first frame, output on the last: neither alone is the bill.
  'split-model' => [
    { prompt_tokens => 1000, prompt_tokens_details => { cached_tokens => 800, cache_write_tokens => 100 } },
    undef, undef,
    { completion_tokens => 50, total_tokens => 1050 },
  ],
  # A running total on every chunk (continuous usage stats): the last one is the bill.
  'running-model' => [
    map({ +{ %OPENAI_USAGE, completion_tokens => $_, total_tokens => 1000 + $_ } } 10, 20, 30),
    { %OPENAI_USAGE },
  ],
  'cut-after-usage'  => [ undef, undef, undef, { %OPENAI_USAGE } ],
  'cut-before-usage' => [ undef, undef, undef ],
);

my %CUT = ('cut-after-usage' => 1, 'cut-before-usage' => 1);

# --- An upstream answering every model streamed or in one piece --------------------------------
my $upstream = Mojolicious->new;
$upstream->log->level('fatal');
$upstream->routes->post('/v1/chat/completions' => sub {
  my ($c) = @_;
  my $req = $c->req->json || {};
  my $model = $req->{model};
  unless ($req->{stream}) {
    return $c->render(json => {
      id => 'c1', model => $model, object => 'chat.completion',
      choices => [{ index => 0, finish_reason => 'stop', message => { role => 'assistant', content => 'abc' } }],
      usage => $USAGE{$model},
    });
  }
  $c->render_later;
  $c->res->code(200);
  $c->res->headers->content_type('text/event-stream');
  my @usage = @{ $STREAM_USAGE{$model} };
  my @frames;
  for my $i (0 .. $#usage) {
    my $is_final = !$CUT{$model} && $i == $#usage;
    my $frame = { id => 'c1', object => 'chat.completion.chunk', model => $model,
      choices => $is_final ? [] : [{ index => 0, delta => { content => substr('abc', $i, 1) }, finish_reason => undef }] };
    $frame->{usage} = $usage[$i] if $usage[$i];
    push @frames, 'data: ' . encode_json($frame) . "\n\n";
  }
  push @frames, "data: [DONE]\n\n" unless $CUT{$model};
  my $write;
  $write = sub {
    my $frame = shift @frames;
    unless (defined $frame) {
      return $c->finish unless $CUT{$model};
      # Drop the connection: the chunked body never gets its terminator.
      Mojo::IOLoop->stream($c->tx->connection)->close;
      return;
    }
    $c->write_chunk($frame => sub { Mojo::IOLoop->timer(0.01 => $write) });
  };
  Mojo::IOLoop->timer(0.01 => $write);
});
my $up = Mojo::Server::Daemon->new(app => $upstream, listen => ['http://127.0.0.1'], silent => 1);
$up->start;
my $UP_URL = 'http://127.0.0.1:' . $up->ports->[0] . '/v1';

sub config_for {
  my (%pricing) = @_;
  return {
    pricing => \%pricing,
    nodes => [ map { +{ id => "n-$_", url => $UP_URL, model => $_, engine => 'openai',
      healthy => 1, max_conns => 4 } } sort keys %USAGE ],
  };
}

my %FACE = (
  openai    => sub { ('/v1/chat/completions', { model => $_[0], messages => [{ role => 'user', content => 'hi' }] }) },
  anthropic => sub { ('/v1/messages', { model => $_[0], max_tokens => 64, messages => [{ role => 'user', content => 'hi' }] }) },
  ollama    => sub { ('/api/chat', { model => $_[0], messages => [{ role => 'user', content => 'hi' }] }) },
  # /api/generate shares /api/chat's metering (skeid #43); a second Ollama route must not be a
  # second, unpriced way in.
  ollama_generate => sub { ('/api/generate', { model => $_[0], prompt => 'hi' }) },
);

# One request through a fresh proxy over a fresh Skeid with the given pricing; returns the
# response code and the usage event it recorded.
sub request_through {
  my (%args) = @_;
  my @events;
  my $skeid = $args{skeid} || Langertha::Skeid->new(
    route_wait_poll_ms => 5,
    config_loader      => sub { config_for('*' => { %{ $args{rule} } }) },
    store_usage_event  => sub { push @events, $_[1]; return { ok => 1 } },
  );
  my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
  $proxy->log->level('fatal');
  my $pd = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
  $pd->start;
  my ($path, $payload) = $FACE{ $args{face} }->($args{model});
  $payload->{stream} = $args{stream} ? JSON::MaybeXS::true : JSON::MaybeXS::false;
  my $ua = Mojo::UserAgent->new;
  my $tx = $ua->build_tx(POST => 'http://127.0.0.1:' . $pd->ports->[0] . $path,
    { 'Content-Type' => 'application/json' }, json => $payload);
  my $timeout = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->start($tx => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($timeout);
  $pd->stop;
  return ($tx->res->code, $events[0] || {}, scalar(@events));
}

my @COUNTS = qw(input_tokens output_tokens total_tokens cached_tokens cache_write_tokens);
my @COSTS  = qw(cost_input_usd cost_output_usd cost_cache_read_usd cost_cache_write_usd cost_total_usd);

# The count Langertha::Usage (or, on 0.503, the raw fallback) reads for each shape.
my %WRITES = ('anthropic-model' => 400);

my @rules = (['plain rule', \%PLAIN_RULE]);
push @rules, ['cache rule', \%RULE] if $CORE_PRICES_CACHE;

for my $r (@rules) {
  my ($rule_name, $rule) = @$r;
  for my $face (qw(openai anthropic ollama ollama_generate)) {
    for my $model (qw(openai-model anthropic-model split-model running-model)) {
      my $label = "$rule_name, $face face, $model";
      my ($json_code, $json_ev) = request_through(rule => $rule, face => $face, model => $model);
      my ($code, $ev, $n) = request_through(rule => $rule, face => $face, model => $model, stream => 1);
      is($json_code, 200, "$label: non-streamed served");
      is($code, 200, "$label: streamed served");
      is($n, 1, "$label: one usage event for the stream");
      is($ev->{ok}, 1, "$label: the stream is ok");
      # Same usage, same bill -- to the last digit, not approximately.
      is($ev->{$_}, $json_ev->{$_}, "$label: streamed $_ equals non-streamed") for @COUNTS, @COSTS;
      ok($ev->{cost_total_usd} > 0, "$label: the stream is priced, not free");
      is($ev->{cached_tokens}, 800, "$label: cache reads counted");
      is($ev->{cache_write_tokens}, $WRITES{$model} // 100, "$label: cache writes counted");
      is($ev->{input_tokens}, $model eq 'anthropic-model' ? 200 : 1000, "$label: input not summed across frames");
      is($ev->{output_tokens}, 50, "$label: output is the final running total");
    }
  }
}

# --- Exact amounts -------------------------------------------------------------------------------
# Base pricing works on every core: OpenAI-shaped usage under a rule without cache rates bills
# every prompt token at the input rate, streamed as before non-streamed.
{
  my ($code, $ev) = request_through(rule => \%PLAIN_RULE, face => 'openai', model => 'openai-model', stream => 1);
  near($ev->{cost_input_usd}, 1000 / 1e6 * 3, 'plain rule, stream: every prompt token at the input rate');
  near($ev->{cost_output_usd}, 50 / 1e6 * 15, 'plain rule, stream: output at the output rate');
  near($ev->{cost_total_usd}, 1000 / 1e6 * 3 + 50 / 1e6 * 15, 'plain rule, stream: total');
  is($ev->{cost_cache_read_usd}, 0, 'plain rule, stream: no cache read amount');
  is($ev->{cost_cache_write_usd}, 0, 'plain rule, stream: no cache write amount');
}

SKIP: {
  skip 'this Langertha cannot price prompt-cache tokens (needs Langertha::Cost cache amounts)', 1
    unless $CORE_PRICES_CACHE;
  my %EXPECT = (
    # 1000 inside: 800 reads, 100 writes, 100 uncached.
    'openai-model'    => { input => 100 / 1e6 * 3, read => 800 / 1e6 * 0.30, write => 100 / 1e6 * 3.75 },
    'split-model'     => { input => 100 / 1e6 * 3, read => 800 / 1e6 * 0.30, write => 100 / 1e6 * 3.75 },
    'running-model'   => { input => 100 / 1e6 * 3, read => 800 / 1e6 * 0.30, write => 100 / 1e6 * 3.75 },
    # 200 uncached beside 800 reads and 400 writes.
    'anthropic-model' => { input => 200 / 1e6 * 3, read => 800 / 1e6 * 0.30, write => 400 / 1e6 * 3.75 },
  );
  my $output = 50 / 1e6 * 15;
  for my $face (qw(openai anthropic ollama ollama_generate)) {
    for my $model (sort keys %EXPECT) {
      my $want = $EXPECT{$model};
      my ($code, $ev) = request_through(rule => \%RULE, face => $face, model => $model, stream => 1);
      my $label = "cache rule, $face face, $model stream";
      near($ev->{cost_input_usd}, $want->{input}, "$label: uncached input at the input rate");
      near($ev->{cost_output_usd}, $output, "$label: output at the output rate");
      near($ev->{cost_cache_read_usd}, $want->{read}, "$label: cache reads at cached_input_per_million");
      near($ev->{cost_cache_write_usd}, $want->{write}, "$label: cache writes at cache_write_per_million");
      near($ev->{cost_total_usd}, $want->{input} + $output + $want->{read} + $want->{write}, "$label: total");
    }
  }
}

# --- A cut stream: priced from the usage it carried, and still a failure ------------------------
for my $face (qw(openai anthropic ollama ollama_generate)) {
  my ($json_code, $json_ev) = request_through(rule => \%PLAIN_RULE, face => $face, model => 'cut-after-usage');
  my (undef, $ev) = request_through(rule => \%PLAIN_RULE, face => $face, model => 'cut-after-usage', stream => 1);
  is($ev->{ok}, 0, "$face face: a stream cut after its usage frame failed");
  is($ev->{$_}, $json_ev->{$_}, "$face face: ... and its $_ is what the usage frame reported") for @COUNTS, @COSTS;
  ok($ev->{cost_total_usd} > 0, "$face face: ... which is billed, not dropped");

  my (undef, $bare) = request_through(rule => \%PLAIN_RULE, face => $face, model => 'cut-before-usage', stream => 1);
  is($bare->{ok}, 0, "$face face: a stream cut before any usage frame failed");
  is($bare->{$_}, 0, "$face face: ... with $_ 0, nothing invented") for @COUNTS, @COSTS;
}

# --- SQLite: cache_write_tokens is a nullable column, added to an old table ---------------------
SKIP: {
  eval { require DBI; require DBD::SQLite; 1 } or skip 'DBI/DBD::SQLite not available', 6;

  my $dir = tempdir(CLEANUP => 1);
  my $db  = "$dir/old.sqlite";
  my $dbh = DBI->connect("dbi:SQLite:dbname=$db", '', '', { RaiseError => 1, PrintError => 0 });
  # The schema before skeid #41 (after skeid #28).
  $dbh->do(q{
    CREATE TABLE usage_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      created_at TEXT NOT NULL, request_id TEXT, api_format TEXT, endpoint TEXT,
      api_key_id TEXT, provider TEXT, engine TEXT, model TEXT, requested_model TEXT,
      node_id TEXT, route_url TEXT, status_code INTEGER, ok INTEGER NOT NULL DEFAULT 0,
      duration_ms INTEGER, input_tokens INTEGER NOT NULL DEFAULT 0,
      output_tokens INTEGER NOT NULL DEFAULT 0, total_tokens INTEGER NOT NULL DEFAULT 0,
      cached_tokens INTEGER, content_bytes INTEGER,
      tool_calls INTEGER NOT NULL DEFAULT 0, cost_input_usd REAL NOT NULL DEFAULT 0,
      cost_output_usd REAL NOT NULL DEFAULT 0, cost_total_usd REAL NOT NULL DEFAULT 0,
      cost_cache_read_usd REAL, cost_cache_write_usd REAL,
      error_type TEXT, error_message TEXT
    )
  });
  $dbh->do(q{INSERT INTO usage_events (created_at, api_key_id, model, ok) VALUES ('2020-01-01T00:00:00Z', 'k_legacy', 'm', 1)});
  $dbh->disconnect;

  my $cfg = config_for('*' => {%PLAIN_RULE});
  $cfg->{usage_store} = { backend => 'sqlite', sqlite_path => $db };
  my $skeid = Langertha::Skeid->new(config_loader => sub { $cfg });
  my ($code) = request_through(skeid => $skeid, face => 'openai', model => 'openai-model', stream => 1);
  is($code, 200, 'sqlite: streamed request served');

  $dbh = DBI->connect("dbi:SQLite:dbname=$db", '', '', { RaiseError => 1, PrintError => 0 });
  my $legacy = $dbh->selectrow_hashref(q{SELECT * FROM usage_events WHERE api_key_id = 'k_legacy'});
  ok(!defined($legacy->{cache_write_tokens}), 'sqlite: the pre-existing row reads NULL for cache writes');
  my $row = $dbh->selectrow_hashref(q{SELECT * FROM usage_events WHERE model = 'openai-model'});
  is($row->{cache_write_tokens}, 100, 'sqlite: the stream stored its cache write count');
  near($row->{cost_total_usd}, 1000 / 1e6 * 3 + 50 / 1e6 * 15, 'sqlite: the stream stored its cost');
  $dbh->disconnect;

  my $report = $skeid->usage_report;
  is($report->{totals}{cache_write_tokens}, 100, 'sqlite report: totals carry cache writes');
  is($report->{recent}[0]{cache_write_tokens}, 100, 'sqlite report: recent events carry cache writes');
}

$up->stop;
done_testing;
