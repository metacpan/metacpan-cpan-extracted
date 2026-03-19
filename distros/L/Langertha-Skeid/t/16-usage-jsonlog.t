use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Langertha::Skeid;

# --- Directory mode (one file per event, default/recommended) ---
{
  my $dir = tempdir(CLEANUP => 1);

  my $skeid = Langertha::Skeid->new(
    usage_store => { backend => 'jsonlog', path => $dir },
  );

  my $r1 = $skeid->call_function('usage.record', {
    api_format  => 'openai',
    api_key_id  => 'k_alice',
    model       => 'gpt-4o-mini',
    status_code => 200,
    ok          => 1,
    duration_ms => 42,
    metrics     => { usage => { input => 100, output => 25, total => 125 } },
  });
  ok($r1->{ok}, 'dir mode: record 1 ok');
  ok(length($r1->{id}), 'dir mode: got event id');

  my $r2 = $skeid->call_function('usage.record', {
    api_format  => 'openai',
    api_key_id  => 'k_bob',
    model       => 'claude-3-haiku',
    status_code => 200,
    ok          => 1,
    duration_ms => 55,
    metrics     => { usage => { input => 200, output => 50, total => 250 } },
  });
  ok($r2->{ok}, 'dir mode: record 2 ok');

  # Check files were created
  my @files = glob("$dir/*.json");
  is(scalar(@files), 2, 'dir mode: two json files created');

  # Report — all events
  my $report = $skeid->call_function('usage.report', {});
  ok($report->{ok}, 'dir mode: report ok');
  is($report->{backend}, 'jsonlog', 'dir mode: backend is jsonlog');
  is($report->{totals}{requests}, 2, 'dir mode: 2 requests total');
  is($report->{totals}{input_tokens}, 300, 'dir mode: input tokens summed');
  is($report->{totals}{output_tokens}, 75, 'dir mode: output tokens summed');
  is(scalar(@{$report->{by_key}}), 2, 'dir mode: 2 keys');
  is(scalar(@{$report->{by_model}}), 2, 'dir mode: 2 models');
  is(scalar(@{$report->{recent}}), 2, 'dir mode: 2 recent');

  # Report — filtered by model
  my $filtered = $skeid->call_function('usage.report', { model => 'gpt-4o-mini' });
  is($filtered->{totals}{requests}, 1, 'dir mode: filtered to 1 request');

  # Report — filtered by api_key_id
  my $by_key = $skeid->call_function('usage.report', { api_key_id => 'k_bob' });
  is($by_key->{totals}{requests}, 1, 'dir mode: filtered by key');
  is($by_key->{totals}{input_tokens}, 200, 'dir mode: correct tokens for key');
}

# --- File mode (JSON lines, single file) ---
{
  my $dir  = tempdir(CLEANUP => 1);
  my $file = "$dir/usage.jsonl";

  my $skeid = Langertha::Skeid->new(
    usage_store => { backend => 'jsonlog', path => $file, mode => 'file' },
  );

  $skeid->call_function('usage.record', {
    api_key_id  => 'k_test',
    model       => 'test-model',
    status_code => 200,
    ok          => 1,
    metrics     => { usage => { input => 10, output => 5, total => 15 } },
  });
  $skeid->call_function('usage.record', {
    api_key_id  => 'k_test',
    model       => 'test-model',
    status_code => 500,
    ok          => 0,
    metrics     => { usage => { input => 20, output => 0, total => 20 } },
  });

  ok(-f $file, 'file mode: jsonl file created');

  # Count lines
  open my $fh, '<', $file or die $!;
  my @lines = <$fh>;
  close $fh;
  is(scalar(@lines), 2, 'file mode: 2 lines in jsonl');

  my $report = $skeid->call_function('usage.report', { limit => 1 });
  ok($report->{ok}, 'file mode: report ok');
  is($report->{totals}{requests}, 2, 'file mode: 2 total requests');
  is(scalar(@{$report->{recent}}), 1, 'file mode: limit respected');
}

# --- Auto-detect dir mode from trailing slash ---
{
  my $dir = tempdir(CLEANUP => 1);
  my $path = "$dir/events/";

  my $skeid = Langertha::Skeid->new(
    usage_store => { backend => 'jsonlog', path => $path },
  );

  ok(-d $path, 'trailing slash: directory created');

  $skeid->call_function('usage.record', {
    model   => 'test',
    metrics => { usage => { input => 1, output => 1, total => 2 } },
  });

  my @files = glob("$path*.json");
  is(scalar(@files), 1, 'trailing slash: event written as file');
}

done_testing;
