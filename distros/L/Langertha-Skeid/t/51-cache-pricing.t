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

# Cached prompt tokens are billed at the cache rates the pricing rule states (skeid #28, ADR 0013
# update). The usage event is the billing unit (ADR 0004): a cache hit billed at the full input
# rate overcharges the customer, a cache write billed at it undercharges. The cost is priced by
# Langertha::Pricing from the upstream's own usage block, so every wire spelling -- OpenAI's
# nested count inside prompt_tokens, Anthropic's flat counts beside input_tokens, an
# /anthropic shim that spells them the Anthropic way but counts them inside -- prices each token
# once. A rule without cache rates, or a Langertha that cannot price the cache (0.503), must bill
# exactly as before.

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

# One usage block per upstream shape, all for 200 fresh input tokens, 800 cache reads and 50
# output tokens (plus 400 cache writes where the wire reports them).
my %USAGE = (
  # OpenAI Chat: the cache read is nested in prompt_tokens_details and counted inside prompt_tokens.
  'openai-model' => { prompt_tokens => 1000, completion_tokens => 50, total_tokens => 1050,
    prompt_tokens_details => { cached_tokens => 800 } },
  # Anthropic: flat counts, beside input_tokens.
  'anthropic-model' => { input_tokens => 200, output_tokens => 50,
    cache_read_input_tokens => 800, cache_creation_input_tokens => 400 },
  # AKIAnthropic: Anthropic spelling, but the counts are inside input_tokens.
  'akianthropic-model' => { input_tokens => 1400, output_tokens => 50,
    cache_read_input_tokens => 800, cache_creation_input_tokens => 400, input_includes_cache => 1 },
  'plain-model' => { prompt_tokens => 1000, completion_tokens => 50, total_tokens => 1050,
    prompt_tokens_details => { cached_tokens => 800 } },
);

# Cost at the full input rate for 1000 input + 50 output tokens: what OpenAI-shaped usage has
# always been billed under a rule without cache rates.
my $FULL_RATE_TOTAL = 1000 / 1e6 * 3 + 50 / 1e6 * 15;

# --- An upstream answering every model with its own usage block, and a proxy in front ----------
my $upstream = Mojolicious->new;
$upstream->log->level('fatal');
$upstream->routes->post('/v1/chat/completions' => sub {
  my ($c) = @_;
  my $model = $c->req->json->{model};
  $c->render(json => {
    id => 'c1', model => $model, object => 'chat.completion',
    choices => [{ index => 0, finish_reason => 'stop', message => { role => 'assistant', content => 'hi' } }],
    usage => $USAGE{$model},
  });
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

# Sends one non-streaming request through a proxy over $skeid and returns the response code.
sub request_through {
  my ($skeid, $model) = @_;
  my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
  $proxy->log->level('fatal');
  my $pd = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
  $pd->start;
  my $ua = Mojo::UserAgent->new;
  my $tx = $ua->build_tx(POST => 'http://127.0.0.1:' . $pd->ports->[0] . '/v1/chat/completions',
    { 'Content-Type' => 'application/json' },
    json => { model => $model, messages => [{ role => 'user', content => 'hi' }] });
  my $timeout = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->start($tx => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($timeout);
  $pd->stop;
  return $tx->res->code;
}

# --- A Langertha that cannot price the cache: rates accepted, ignored, warned about once --------
# Runs first: the warning is once per process. On 0.503 this is the real behavior; on a newer
# core the capability check is forced off to prove Skeid's side of the fallback.
{
  no warnings 'redefine';
  local *Langertha::Skeid::_core_prices_cache = sub { 0 };

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  my @events;
  my $skeid = Langertha::Skeid->new(
    config_loader     => sub { config_for('*' => {%RULE}) },
    store_usage_event => sub { push @events, $_[1]; return { ok => 1 } },
  );
  my @cache_warnings = grep { /cached_input_per_million/ } @warnings;
  is(scalar(@cache_warnings), 1, 'old core: the cache rates are warned about at config load');
  like($cache_warnings[0] // '', qr/ignored/, 'old core: the warning says they are ignored');

  my $rule = $skeid->pricing_for_model('openai-model');
  is_deeply($rule, \%PLAIN_RULE, 'old core: the stored rule has no cache rates');

  Langertha::Skeid->new(config_loader => sub { config_for('*' => {%RULE}) });
  is(scalar(grep { /cached_input_per_million/ } @warnings), 1, 'old core: warned once per process, not per load');

  is(request_through($skeid, 'openai-model'), 200, 'old core: request served');
  near($events[0]{cost_total_usd}, $FULL_RATE_TOTAL, 'old core: cached tokens bill at the input rate, as before');
  near($events[0]{cost_input_usd}, 1000 / 1e6 * 3, 'old core: all input tokens in cost_input_usd');
  is($events[0]{cost_cache_read_usd}, 0, 'old core: no cache read amount');
  is($events[0]{cost_cache_write_usd}, 0, 'old core: no cache write amount');
  is($events[0]{cached_tokens}, 800, 'old core: the cache count is still recorded');
}

# --- Config validation: a cache rate must be a number >= 0 --------------------------------------
{
  my $skeid = Langertha::Skeid->new;
  for my $bad (-1, 'cheap', [0.3]) {
    my $shown = ref($bad) ? 'a reference' : "'$bad'";
    ok(!eval { $skeid->set_model_pricing('m', { %PLAIN_RULE, cached_input_per_million => $bad }); 1 },
      "cached_input_per_million $shown is refused");
    like($@, qr/cached_input_per_million must be a number >= 0/, "... with a message naming the key ($shown)");
    ok(!eval { $skeid->set_model_pricing('m', { %PLAIN_RULE, cache_write_per_million => $bad }); 1 },
      "cache_write_per_million $shown is refused");
  }
  ok(!exists $skeid->model_pricing->{m}, 'a refused rule stores nothing');
  ok(eval { $skeid->set_model_pricing('m', { %PLAIN_RULE, cached_input_per_million => 0 }); 1 },
    'a zero cache rate is valid');

  # A bad rate in a reloaded config is a failed reload: the previous pricing stays in force.
  my $cfg = config_for('*' => {%PLAIN_RULE});
  my $loaded = Langertha::Skeid->new(config_loader => sub { $cfg });
  $cfg = config_for('*' => { %PLAIN_RULE, cache_write_per_million => -2 });
  ok(!eval { $loaded->reload_config; 1 }, 'a config with a negative cache rate fails to load');
  is_deeply($loaded->pricing_for_model('x'), \%PLAIN_RULE, 'the previous pricing is kept');
}

SKIP: {
  skip 'this Langertha cannot price prompt-cache tokens (needs Langertha::Cost cache amounts)', 1
    unless $CORE_PRICES_CACHE;

  # --- The rule keeps its cache rates --------------------------------------------------------
  {
    my $skeid = Langertha::Skeid->new(config_loader => sub { config_for('*' => {%RULE}) });
    is_deeply($skeid->pricing_for_model('openai-model'), \%RULE, 'pricing_for_model returns the cache rates');
  }

  # --- Each upstream shape prices every token once, end to end --------------------------------
  my %EXPECT = (
    # 200 uncached (1000 - 800 inside), 800 reads, no writes reported.
    'openai-model' => { input => 200 / 1e6 * 3, read => 800 / 1e6 * 0.30, write => 0 },
    # 200 uncached beside 800 reads and 400 writes.
    'anthropic-model' => { input => 200 / 1e6 * 3, read => 800 / 1e6 * 0.30, write => 400 / 1e6 * 3.75 },
    # 1400 inside minus 800 reads and 400 writes: the same 200 uncached.
    'akianthropic-model' => { input => 200 / 1e6 * 3, read => 800 / 1e6 * 0.30, write => 400 / 1e6 * 3.75 },
  );
  my $output = 50 / 1e6 * 15;

  for my $model (sort keys %EXPECT) {
    my $want = $EXPECT{$model};
    my @events;
    my $skeid = Langertha::Skeid->new(
      config_loader     => sub { config_for('*' => {%RULE}) },
      store_usage_event => sub { push @events, $_[1]; return { ok => 1 } },
    );
    is(request_through($skeid, $model), 200, "$model: request served");
    my $ev = $events[0] || {};
    near($ev->{cost_input_usd}, $want->{input}, "$model: only uncached input at the input rate");
    near($ev->{cost_output_usd}, $output, "$model: output unchanged");
    near($ev->{cost_cache_read_usd}, $want->{read}, "$model: cache reads at cached_input_per_million");
    near($ev->{cost_cache_write_usd}, $want->{write}, "$model: cache writes at cache_write_per_million");
    near($ev->{cost_total_usd}, $want->{input} + $output + $want->{read} + $want->{write},
      "$model: total includes the cache amounts");
    is($ev->{cached_tokens}, 800, "$model: the event's cache count is the one that was priced");
  }

  # The inclusive shim and the exclusive Anthropic wire are the same traffic: same bill.
  {
    my %bill;
    for my $model (qw(anthropic-model akianthropic-model)) {
      my @events;
      my $skeid = Langertha::Skeid->new(
        config_loader     => sub { config_for('*' => {%RULE}) },
        store_usage_event => sub { push @events, $_[1]; return { ok => 1 } },
      );
      request_through($skeid, $model);
      $bill{$model} = $events[0]{cost_total_usd};
    }
    near($bill{'akianthropic-model'}, $bill{'anthropic-model'},
      'inside-counted and beside-counted cache tokens bill the same');
  }

  # --- A rule without cache rates bills exactly as before -------------------------------------
  {
    my @events;
    my $skeid = Langertha::Skeid->new(
      config_loader     => sub { config_for('*' => {%PLAIN_RULE}) },
      store_usage_event => sub { push @events, $_[1]; return { ok => 1 } },
    );
    request_through($skeid, 'plain-model');
    near($events[0]{cost_total_usd}, $FULL_RATE_TOTAL, 'no cache rates: cached tokens bill at the input rate');
    near($events[0]{cost_input_usd}, 1000 / 1e6 * 3, 'no cache rates: all input in cost_input_usd');
    is($events[0]{cost_cache_read_usd}, 0, 'no cache rates: no cache read amount');
    is($events[0]{cost_cache_write_usd}, 0, 'no cache rates: no cache write amount');
  }

  # --- Only one cache rate: the other falls back to the input rate, no invented discount ------
  {
    my @events;
    my $skeid = Langertha::Skeid->new(
      config_loader     => sub { config_for('*' => { %PLAIN_RULE, cached_input_per_million => 0.30 }) },
      store_usage_event => sub { push @events, $_[1]; return { ok => 1 } },
    );
    request_through($skeid, 'anthropic-model');
    near($events[0]{cost_cache_write_usd}, 400 / 1e6 * 3, 'a missing write rate bills writes at the input rate');
  }

  # --- SQLite: the amounts land in their columns; an old table gains them, old rows read NULL -
  SKIP: {
    eval { require DBI; require DBD::SQLite; 1 } or skip 'DBI/DBD::SQLite not available', 6;

    my $dir = tempdir(CLEANUP => 1);
    my $db  = "$dir/old.sqlite";
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db", '', '', { RaiseError => 1, PrintError => 0 });
    # The schema before skeid #28 (after k27 and skeid #36).
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
        error_type TEXT, error_message TEXT
      )
    });
    $dbh->do(q{INSERT INTO usage_events (created_at, api_key_id, model, ok) VALUES ('2020-01-01T00:00:00Z', 'k_legacy', 'm', 1)});
    $dbh->disconnect;

    my $cfg = config_for('*' => {%RULE});
    $cfg->{usage_store} = { backend => 'sqlite', sqlite_path => $db };
    my $skeid = Langertha::Skeid->new(config_loader => sub { $cfg });
    is(request_through($skeid, 'anthropic-model'), 200, 'sqlite: request served');

    $dbh = DBI->connect("dbi:SQLite:dbname=$db", '', '', { RaiseError => 1, PrintError => 0 });
    my $legacy = $dbh->selectrow_hashref(q{SELECT * FROM usage_events WHERE api_key_id = 'k_legacy'});
    ok(!defined($legacy->{cost_cache_read_usd}), 'sqlite: the pre-existing row reads NULL for cache reads');
    ok(!defined($legacy->{cost_cache_write_usd}), 'sqlite: ... and for cache writes');
    my $row = $dbh->selectrow_hashref(q{SELECT * FROM usage_events WHERE model = 'anthropic-model'});
    near($row->{cost_cache_read_usd}, 800 / 1e6 * 0.30, 'sqlite: cache read amount stored');
    near($row->{cost_cache_write_usd}, 400 / 1e6 * 3.75, 'sqlite: cache write amount stored');
    near($row->{cost_total_usd}, (200 / 1e6 * 3) + (50 / 1e6 * 15) + (800 / 1e6 * 0.30) + (400 / 1e6 * 3.75),
      'sqlite: total includes the cache amounts');
    $dbh->disconnect;
  }
}

$up->stop;
done_testing;
