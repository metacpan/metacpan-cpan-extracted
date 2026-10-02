use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Test::File::ShareDir -share => {
  -dist => { 'Langertha-Skeid' => 'share' },
};
use Langertha::Skeid;
use Langertha::Skeid::UsageStore::DBI;

my $tmp = tempdir(CLEANUP => 1);
my $db  = "$tmp/usage.sqlite";

my $skeid = Langertha::Skeid->new(
  usage_store => {
    backend     => 'sqlite',
    sqlite_path => $db,
  },
);

ok(-f $db, 'sqlite usage db created');

my $metrics = $skeid->call_function('metrics.normalize', {
  provider    => 'skeid',
  engine      => 'openaibase',
  model       => 'qwen2.5-7b-instruct',
  route       => '/v1/chat/completions',
  duration_ms => 37,
  usage       => { prompt_tokens => 120, completion_tokens => 30, total_tokens => 150 },
  tool_calls  => [{ function => { name => 'lookup' } }],
});

my $saved = $skeid->call_function('usage.record', {
  api_format   => 'openai',
  endpoint     => '/v1/chat/completions',
  api_key_id   => 'k_demo',
  provider     => 'skeid',
  engine       => 'openaibase',
  model        => 'qwen2.5-7b-instruct',
  node_id      => 'n1',
  status_code  => 200,
  ok           => 1,
  duration_ms  => 37,
  metrics      => $metrics,
});
ok($saved->{ok}, 'usage.record succeeded');

my $report = $skeid->call_function('usage.report', { limit => 10 });
ok($report->{ok}, 'usage.report succeeded');
is($report->{backend}, 'sqlite', 'backend reported');
is($report->{totals}{requests}, 1, 'one request recorded');
is($report->{totals}{input_tokens}, 120, 'input tokens aggregated');
is($report->{totals}{output_tokens}, 30, 'output tokens aggregated');
is($report->{totals}{tool_calls}, 1, 'tool calls aggregated');
ok(($report->{totals}{total_cost_usd} // 0) >= 0, 'cost present');
is($report->{by_key}[0]{api_key_id}, 'k_demo', 'grouped by key');
is($report->{by_model}[0]{model}, 'qwen2.5-7b-instruct', 'grouped by model');
is(scalar(@{$report->{recent}}), 1, 'recent rows returned');

# The DBI backends apply a shipped schema at configure time, so both files have to be
# findable from a working copy as well as from an installed sharedir.
for my $backend (qw(sqlite postgresql)) {
  my $store = Langertha::Skeid::UsageStore::DBI->new(backend => $backend, dsn => '');
  ok(-f $store->shipped_schema_file, "$backend schema file exists");
}

# An upgrade meets a table that already exists, and CREATE TABLE IF NOT EXISTS does nothing to
# it. Without an explicit column add, every insert naming a new column fails -- and usage
# failures are reported rather than thrown, so the symptom is billing data quietly going
# missing, not a crash.
SKIP: {
  eval { require DBI; require DBD::SQLite; 1 } or skip 'DBI/DBD::SQLite not available', 3;

  my $dir = tempdir(CLEANUP => 1);
  my $db  = "$dir/old.sqlite";

  my $dbh = DBI->connect("dbi:SQLite:dbname=$db", '', '', { RaiseError => 1, PrintError => 0 });
  $dbh->do(q{
    CREATE TABLE usage_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      created_at TEXT NOT NULL, request_id TEXT, api_format TEXT, endpoint TEXT,
      api_key_id TEXT, provider TEXT, engine TEXT, model TEXT, node_id TEXT, route_url TEXT,
      status_code INTEGER, ok INTEGER NOT NULL DEFAULT 0, duration_ms INTEGER,
      input_tokens INTEGER NOT NULL DEFAULT 0, output_tokens INTEGER NOT NULL DEFAULT 0,
      total_tokens INTEGER NOT NULL DEFAULT 0, tool_calls INTEGER NOT NULL DEFAULT 0,
      cost_input_usd REAL NOT NULL DEFAULT 0, cost_output_usd REAL NOT NULL DEFAULT 0,
      cost_total_usd REAL NOT NULL DEFAULT 0, error_type TEXT, error_message TEXT
    )
  });
  $dbh->disconnect;

  my $upgraded = Langertha::Skeid->new(usage_store => { backend => 'sqlite', sqlite_path => $db });
  my $written = $upgraded->call_function('usage.record', {
    api_key_id      => 'k_migrate',
    model           => 'served-model',
    requested_model => 'house-model',
    status_code     => 200,
    ok              => 1,
    metrics         => { usage => { input => 1, output => 1, total => 2 } },
  });
  ok($written->{ok}, 'an event still writes against a pre-existing table');

  my $report = $upgraded->call_function('usage.report', { limit => 1 });
  is($report->{recent}[0]{model}, 'served-model', 'served model round-trips');
  is($report->{recent}[0]{requested_model}, 'house-model', 'and so does the column the upgrade added');
}

done_testing;
