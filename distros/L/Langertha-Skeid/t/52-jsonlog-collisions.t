use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use JSON::MaybeXS qw(decode_json);
use Errno qw(EIO);

use Langertha::Skeid::UsageStore::JsonLog;

sub read_event {
  my ($file) = @_;
  open my $fh, '<', $file or die "Cannot read $file: $!";
  local $/;
  return decode_json(<$fh>);
}

# A restarted process may have the same PID and wall-clock second as the old
# one, particularly in separate PID namespaces. Fresh generator state must add
# a process nonce rather than restarting the same PID/sequence id series.
{
  my @nonces = ('a' x 32, 'b' x 32);
  no warnings 'redefine';
  local *Langertha::Skeid::UsageStore::JsonLog::strftime = sub { 'fixed-time' };
  local *Langertha::Skeid::UsageStore::JsonLog::_new_process_nonce = sub {
    return shift @nonces // die 'unexpected extra nonce request';
  };
  local %Langertha::Skeid::UsageStore::JsonLog::EVENT_ID_STATE = ();

  my $first = Langertha::Skeid::UsageStore::JsonLog::_event_id();
  %Langertha::Skeid::UsageStore::JsonLog::EVENT_ID_STATE = ();
  my $second = Langertha::Skeid::UsageStore::JsonLog::_event_id();

  is($first, "fixed-time-$$-" . ('a' x 32) . '-0000000001', 'fresh generator uses its process nonce');
  is($second, "fixed-time-$$-" . ('b' x 32) . '-0000000001', 'restarted generator uses a new process nonce');
  isnt($second, $first, 'same PID and time produce distinct ids after process restart');
}

# File mode has no exclusive event file to reject a duplicate id. Two process
# initialisations with the same PID/time therefore rely on the process nonce.
{
  my $dir = tempdir(CLEANUP => 1);
  my $file = "$dir/usage.jsonl";
  my $store = Langertha::Skeid::UsageStore::JsonLog->new(path => $file, mode => 'file');
  my @nonces = ('c' x 32, 'd' x 32);

  no warnings 'redefine';
  local *Langertha::Skeid::UsageStore::JsonLog::strftime = sub { 'fixed-time' };
  local *Langertha::Skeid::UsageStore::JsonLog::_new_process_nonce = sub {
    return shift @nonces // die 'unexpected extra nonce request';
  };
  local %Langertha::Skeid::UsageStore::JsonLog::EVENT_ID_STATE = ();

  my $first = $store->store({ marker => 'first-process' });
  %Langertha::Skeid::UsageStore::JsonLog::EVENT_ID_STATE = ();
  my $second = $store->store({ marker => 'second-process' });

  ok($first->{ok} && $second->{ok}, 'file-mode events from both process initialisations are stored');
  isnt($second->{id}, $first->{id}, 'file-mode event ids remain distinct across process restarts');

  open my $fh, '<', $file or die "Cannot read $file: $!";
  my @events = map { decode_json($_) } <$fh>;
  close $fh or die "Cannot close $file: $!";
  is_deeply(
    [map { $_->{id} } @events],
    [$first->{id}, $second->{id}],
    'file-mode lines retain both returned event ids',
  );
  is_deeply(
    [map { $_->{marker} } @events],
    ['first-process', 'second-process'],
    'file-mode lines retain both usage events',
  );
}

# An exclusive create must reject the second fixed name, then retry with a new
# id. Opening with truncation instead makes these two successful stores retain
# only the second usage event.
{
  my $dir = tempdir(CLEANUP => 1);
  my $store = Langertha::Skeid::UsageStore::JsonLog->new(path => $dir);
  my @ids = qw(fixed-id fixed-id retry-id);

  no warnings 'redefine';
  local *Langertha::Skeid::UsageStore::JsonLog::_event_id = sub {
    return shift @ids // die 'unexpected extra id attempt';
  };

  my $first  = $store->store({ marker => 'first' });
  my $second = $store->store({ marker => 'second' });

  ok($first->{ok}, 'first colliding event is stored');
  ok($second->{ok}, 'second colliding event retries successfully');
  isnt($second->{id}, $first->{id}, 'retry returns the id it actually stored');

  my @files = sort glob("$dir/*.json");
  is(scalar(@files), 2, 'both usage events remain on disk');
  is_deeply(
    [ sort map { read_event($_)->{marker} } @files ],
    [qw(first second)],
    'a collision never truncates the first usage event',
  );
}

# Repeated collisions have a finite failure path and leave the existing event
# byte-for-byte intact.
{
  my $dir = tempdir(CLEANUP => 1);
  my $file = "$dir/occupied-id.json";
  my $original = qq({"id":"occupied-id","marker":"original"}\n);
  open my $fh, '>', $file or die "Cannot seed $file: $!";
  print {$fh} $original or die "Cannot seed $file: $!";
  close $fh or die "Cannot seed $file: $!";

  my $store = Langertha::Skeid::UsageStore::JsonLog->new(path => $dir);
  my $attempts = 0;
  no warnings 'redefine';
  local *Langertha::Skeid::UsageStore::JsonLog::_event_id = sub {
    $attempts++;
    return 'occupied-id';
  };

  my $res = $store->store({ marker => 'replacement' });
  ok(!$res->{ok}, 'exhausted collisions are reported as a failure');
  like($res->{error}, qr/collision/i, 'failure identifies event id collisions');
  cmp_ok($attempts, '>', 1, 'a collision is retried');
  is($attempts, 16, 'collision retries stop at the configured bound');

  open my $saved_fh, '<', $file or die "Cannot read $file: $!";
  local $/;
  is(<$saved_fh>, $original, 'exhausted retries never overwrite the existing event');
  close $saved_fh or die "Cannot close $file: $!";
  my @files = glob("$dir/*.json");
  is(scalar(@files), 1, 'exhausted retries create no replacement file');
}

# A real buffered write failure commonly surfaces only from close. It must not
# be reported as a persisted usage event.
SKIP: {
  skip '/dev/full is unavailable on this platform', 2 unless -e '/dev/full';

  my $store = Langertha::Skeid::UsageStore::JsonLog->new(
    path => '/dev/full',
    mode => 'file',
  );
  my $res = $store->store({ payload => ('x' x 131_072) });
  ok(!$res->{ok}, 'file-mode write or close failure is reported');
  like($res->{error}, qr/Cannot append \/dev\/full:/, 'file-mode I/O failure identifies the path');
}

# fsync can fail even after every byte reached the PerlIO buffer.
{
  my $dir = tempdir(CLEANUP => 1);
  my $store = Langertha::Skeid::UsageStore::JsonLog->new(path => $dir, fsync => 1);

  no warnings 'redefine';
  local *IO::Handle::sync = sub {
    $! = EIO;
    return;
  };

  my $res = $store->store({ marker => 'sync-failure' });
  ok(!$res->{ok}, 'fsync failure is not reported as persistence success');
  like($res->{error}, qr/Cannot sync .*: Input\/output error/, 'fsync failure is identified');
}

# Induce a real close(2) failure after a successful flush/sync by closing the
# descriptor inside the sync boundary. The store must check close itself.
{
  my $dir = tempdir(CLEANUP => 1);
  my $store = Langertha::Skeid::UsageStore::JsonLog->new(path => $dir, fsync => 1);

  no warnings 'redefine';
  local *IO::Handle::sync = sub {
    my $fd = fileno($_[0]);
    POSIX::close($fd) == 0 or die "Cannot induce close failure: $!";
    return 1;
  };

  my $res = $store->store({ marker => 'close-failure' });
  ok(!$res->{ok}, 'close failure is not reported as persistence success');
  like($res->{error}, qr/Cannot close .*: Bad file descriptor/, 'close failure is identified');
}

# Forked workers inherit generator state. The first child id must detect the PID
# change, reset its sequence and obtain a fresh process nonce.
SKIP: {
  require Config;
  skip 'fork is unavailable on this platform', 3 unless $Config::Config{d_fork};

  pipe(my $read_fh, my $write_fh) or die "Cannot create id pipe: $!";
  no warnings 'redefine';
  local *Langertha::Skeid::UsageStore::JsonLog::strftime = sub { 'fixed-time' };
  local *Langertha::Skeid::UsageStore::JsonLog::_new_process_nonce = sub {
    return sprintf('%032x', $$);
  };
  local %Langertha::Skeid::UsageStore::JsonLog::EVENT_ID_STATE = ();
  my $parent_id = Langertha::Skeid::UsageStore::JsonLog::_event_id();

  my $pid = fork();
  die "Cannot fork id generator: $!" unless defined $pid;
  if (!$pid) {
    close $read_fh;
    my $id = Langertha::Skeid::UsageStore::JsonLog::_event_id();
    print {$write_fh} "$id\n";
    close $write_fh;
    POSIX::_exit(0);
  }

  close $write_fh;
  my $child_id = <$read_fh>;
  close $read_fh;
  waitpid($pid, 0);
  chomp $child_id if defined $child_id;

  is($?, 0, 'forked id generator exits successfully');
  is(
    $child_id,
    sprintf('fixed-time-%d-%032x-0000000001', $pid, $pid),
    'forked worker refreshes its process nonce and sequence',
  );
  isnt($child_id, $parent_id, 'forked workers generate distinct event ids');
}

done_testing;
