use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use JSON::MaybeXS qw(decode_json);

use Langertha::Skeid;
use Langertha::Skeid::UsageStore::JsonLog;

# The jsonlog writer does not fsync by default -- ADR 0004 already accepts that
# one in-flight event is lost on a crash, and paying fsync on every event is a
# throughput cost most deployments should not take. `fsync: true` is the opt-in
# for ops who need an already-answered request's event to survive a crash (k20).
#
# fsync(2) leaves no observable trace on a normal filesystem, so these tests spy
# on IO::Handle::sync to prove the syscall fires exactly when the flag is set,
# and separately prove the event bytes are still written correctly.

# --- Default is off: no sync, event still written (dir mode) ---
{
  my $dir = tempdir(CLEANUP => 1);
  my $store = Langertha::Skeid::UsageStore::JsonLog->new(path => $dir);
  is($store->fsync, 0, 'fsync defaults off');

  my $calls = 0;
  no warnings 'redefine';
  local *IO::Handle::sync = sub { $calls++; return 1 };

  my $res = $store->store({ model => 'm', input_tokens => 5 });
  ok($res->{ok}, 'default off: event written');
  is($calls, 0, 'default off: fsync not called');
}

# --- Opt in (dir mode): sync fires, event round-trips ---
{
  my $dir = tempdir(CLEANUP => 1);
  my $store = Langertha::Skeid::UsageStore::JsonLog->new(path => $dir, fsync => 1);
  is($store->fsync, 1, 'fsync enabled via constructor');

  my $res = do {
    my $calls = 0;
    no warnings 'redefine';
    local *IO::Handle::sync = sub { $calls++; return 1 };
    my $r = $store->store({ model => 'm', input_tokens => 7 });
    ok($r->{ok}, 'fsync on: event written');
    ok($calls >= 1, 'fsync on: sync called on the event file');
    $r;
  };

  my @files = glob("$dir/*.json");
  is(scalar(@files), 1, 'fsync on: exactly one event file');
  my $ev = decode_json(do { open my $fh, '<', $files[0] or die $!; local $/; <$fh> });
  is($ev->{input_tokens}, 7, 'fsync on: the written event is intact');
  is($ev->{id}, $res->{id}, 'fsync on: file carries the returned id');
}

# --- Opt in (file mode): sync fires there too ---
{
  my $dir  = tempdir(CLEANUP => 1);
  my $file = "$dir/usage.jsonl";
  my $store = Langertha::Skeid::UsageStore::JsonLog->new(path => $file, mode => 'file', fsync => 1);

  my $calls = 0;
  no warnings 'redefine';
  local *IO::Handle::sync = sub { $calls++; return 1 };

  my $r = $store->store({ model => 'm', output_tokens => 2 });
  ok($r->{ok}, 'file mode fsync on: event appended');
  ok($calls >= 1, 'file mode fsync on: sync called');
}

# --- Config plumbing: fsync survives normalize_config, both ways ---
{
  my $dir = tempdir(CLEANUP => 1);
  my $on = Langertha::Skeid->new(
    usage_store => { backend => 'jsonlog', path => $dir, fsync => 1 },
  );
  is($on->usage_store->{fsync}, 1, 'normalize_config carries fsync => 1');

  my $dir2 = tempdir(CLEANUP => 1);
  my $off = Langertha::Skeid->new(
    usage_store => { backend => 'jsonlog', path => $dir2 },
  );
  is($off->usage_store->{fsync}, 0, 'normalize_config defaults fsync off');

  my $calls = 0;
  no warnings 'redefine';
  local *IO::Handle::sync = sub { $calls++; return 1 };
  my $rec = $on->call_function('usage.record', {
    model   => 'm',
    metrics => { usage => { input => 1, output => 1, total => 2 } },
  });
  ok($rec->{ok}, 'configured Skeid with fsync: record ok');
  ok($calls >= 1, 'configured Skeid with fsync: the write was fsync\'d');
}

done_testing;
