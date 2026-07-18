#!perl
#
# Regression coverage for the stall watchdog: a mime helper that makes no I/O progress
# (blocked on a fifo, a deadlocked pipe, a surviving grandchild, ...) must be killed so
# unpacking can never hang forever - while a helper that IS making progress must be left
# alone. See File::Unpack2::run()/_kill_family and the "stall_timeout" attribute.

use strict;
use warnings;
use Test::More;
use FindBin;
BEGIN { unshift @INC, "$1/../blib/lib" if $FindBin::Bin =~ m{(.*)} };
use File::Unpack2;
use File::Temp qw(tempdir);
use File::Find;
use POSIX ();

plan skip_all => 'stall detection needs Linux /proc'        unless -d '/proc' && -r "/proc/$$/fd";
plan skip_all => 'need /bin/sh'                              unless -x '/bin/sh';
my $have_gzip = -x '/usr/bin/gzip' || -x '/bin/gzip';
plan skip_all => 'need gzip to build a non-text fixture'    unless $have_gzip;

# Run $code with a hard wall-clock guard so a *regression* (helper never killed) fails the
# test at $secs instead of hanging the whole suite. Returns 1 if it completed in time.
sub guarded {
  my ($secs, $code) = @_;
  my $done = eval {
    local $SIG{ALRM} = sub { die "ALARM\n" };
    alarm $secs;
    $code->();
    alarm 0;
    1;
  };
  alarm 0;
  return $done ? 1 : 0;
}

# Build a File::Unpack2 whose helper for a real (non-text) source archive is replaced by $argv.
# Returns ($u, $src_archive, $destdir). stall_timeout is short so the tests run in a few seconds.
sub stall_setup {
  my ($argv) = @_;
  my $dest   = tempdir("FU_10d_XXXXXX", TMPDIR => 1, CLEANUP => 1);
  my $srcdir = tempdir("FU_10s_XXXXXX", TMPDIR => 1, CLEANUP => 1);
  my $src    = "$srcdir/payload.gz";
  system('/bin/sh', '-c', "echo hello-file-unpack2 | gzip -c > '$src'") == 0 or return;

  my $u = File::Unpack2->new(destdir => $dest, verbose => 0, logfile => '/dev/null', stall_timeout => 2);
  my $mime = $u->mime($src)->[0];
  return if !defined $mime || $mime eq 'text/plain' || $mime eq '';
  $u->mime_helper($mime, undef, $argv);    # our helper now wins for this mime
  return ($u, $src, $dest);
}

# Safety net: never leave a runaway helper/grandchild behind, even if an assertion fails.
END { kill 'KILL', File::Unpack2::_descendant_pids($$) }

subtest 'a stalled helper is killed instead of hanging forever' => sub {
  my ($u, $src) = stall_setup(['/bin/sh', '-c', 'exec sleep 999']);
  plan skip_all => 'could not build fixture' unless $u;

  my $done = guarded(30, sub { $u->unpack($src) });
  ok($done, 'unpack() returned (stalled helper was killed, did not hang)');
  is(scalar(File::Unpack2::_descendant_pids($$)), 0, 'no helper process left running');
};

subtest 'a helper making steady progress is NOT killed' => sub {
  # Holds one output fd open and advances it every 0.4s for ~3.2s - longer than stall_timeout.
  # A naive timeout would kill it; the I/O-progress detector must let it finish.
  my ($u, $src, $dest) = stall_setup(
    [$^X, '-e', 'open my $f, ">", "progress.out" or die $!; for (1..8) { syswrite $f, "x" x 4096; select undef, undef, undef, 0.4 }']);
  plan skip_all => 'could not build fixture' unless $u;

  my $done = guarded(30, sub { $u->unpack($src) });
  ok($done, 'unpack() returned');
  my $out;
  find(sub { $out = $File::Find::name if $_ eq 'progress.out' }, $dest);
  ok($out, 'progressing helper ran (output present)');
  is((-s $out // 0), 8 * 4096, 'full output written - helper was never killed mid-run') if $out;
};

subtest 'a grandchild holding the pipe is reaped too' => sub {
  # sh backgrounds sleep (which inherits the pipe) then waits. Killing only the direct child
  # would leave the grandchild holding the pipe open and finish() would hang.
  my ($u, $src) = stall_setup(['/bin/sh', '-c', 'sleep 999 & wait']);
  plan skip_all => 'could not build fixture' unless $u;

  my $done = guarded(30, sub { $u->unpack($src) });
  ok($done, 'unpack() returned despite a grandchild holding the pipe');
  is(scalar(File::Unpack2::_descendant_pids($$)), 0, 'grandchild reaped, nothing left running');
};

subtest 'an archive containing a fifo does not hang and the fifo is skipped' => sub {
  my $have_tar = -x '/usr/bin/tar' || -x '/bin/tar';
  plan skip_all => 'need tar' unless $have_tar;
  my $srcdir = tempdir("FU_10f_XXXXXX", TMPDIR => 1, CLEANUP => 1);
  my $payload = "$srcdir/tree";
  mkdir $payload;
  eval { POSIX::mkfifo("$payload/a_fifo", 0600) } or plan skip_all => 'mkfifo unavailable';
  open my $reg, '>', "$payload/regular.txt" or die $!;
  print $reg "just text\n";
  close $reg;
  my $tar = "$srcdir/withfifo.tar";
  system('sh', '-c', "cd '$payload' && tar cf '$tar' .") == 0 or plan skip_all => 'could not build tar';

  my $dest = tempdir("FU_10fd_XXXXXX", TMPDIR => 1, CLEANUP => 1);
  my $u = File::Unpack2->new(destdir => $dest, verbose => 0, logfile => '/dev/null', stall_timeout => 5);
  my $done = guarded(30, sub { $u->unpack($tar) });
  ok($done, 'unpack() of a fifo-bearing archive completed without hanging');
  ok(($u->{skipped}{device_node} || 0) >= 1, 'the fifo was skipped as a special file');
};

subtest 'a helper streaming only to a pipe is NOT killed (pipe output counts as progress)' => sub {
  # It writes only to STDERR (a pipe: fdinfo pos stays 0, so the fd-position detector sees no
  # progress) every 0.3s for ~3s, then writes a marker file at the very end. With stall_timeout=2,
  # if pipe output did not count as progress it would be killed at ~2s and the marker never written.
  my ($u, $src, $dest) = stall_setup(
    [$^X, '-e', 'for (1..10) { print STDERR "x"; select undef,undef,undef,0.3 } open my $f, ">", "pipe.done" or die; print $f "ok"; close $f']);
  plan skip_all => 'could not build fixture' unless $u;

  my $done = guarded(30, sub { $u->unpack($src) });
  ok($done, 'unpack() returned');
  my $marker;
  find(sub { $marker = $File::Find::name if $_ eq 'pipe.done' }, $dest);
  ok($marker, 'a pipe-only helper ran to completion - pipe output kept it alive, not falsely killed');
};

subtest 'a reparented grandchild holding the pipe is reaped via its process group' => sub {
  # The direct child backgrounds a grandchild (which inherits the stdout pipe and the helper's
  # process group) and then exits, so the grandchild reparents to init - invisible to the ppid walk.
  # Only killing the captured process group reaps it; otherwise finish() blocks on the still-open
  # pipe forever (caught by the alarm as a failure).
  my ($u, $src) = stall_setup(['/bin/sh', '-c', 'sleep 999 & exit 0']);
  plan skip_all => 'could not build fixture' unless $u;

  my $done = guarded(30, sub { $u->unpack($src) });
  ok($done, 'unpack() returned (reparented grandchild was group-killed; finish did not hang)');
};

subtest 'stall_timeout config: default 120, env override, and 0 disables' => sub {
  my $mk = sub { File::Unpack2->new(destdir => tempdir(CLEANUP => 1), verbose => 0, logfile => '/dev/null', @_) };
  {
    local $ENV{FILE_UNPACK2_STALL_TIMEOUT};
    delete $ENV{FILE_UNPACK2_STALL_TIMEOUT};
    is($mk->()->{stall_timeout}, 120, 'default is 120s');
  }
  {
    local $ENV{FILE_UNPACK2_STALL_TIMEOUT} = 45;
    is($mk->()->{stall_timeout}, 45, 'env override honoured');
  }
  {
    local $ENV{FILE_UNPACK2_STALL_TIMEOUT} = 0;
    is($mk->()->{stall_timeout}, 0, 'env "0" disables (not silently defaulted back to 120)');
  }
  is($mk->(stall_timeout => 0)->{stall_timeout}, 0, 'explicit 0 disables');
};

done_testing;
