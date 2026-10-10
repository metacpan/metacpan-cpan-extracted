package SecTest;
# Helper for the security regression tests: runs a code ref in a forked child
# so that a crash (SIGSEGV/SIGABRT) is reported as a test failure instead of
# killing the whole test harness.
use strict;
use warnings;
use POSIX ();
use Exporter 'import';
our @EXPORT_OK = qw(isolated);

# Returns a hashref: { signal => N, exit => N, ok => bool, result => "...", error => "..." }
sub isolated {
  my ($code, $timeout) = @_;
  $timeout ||= 60;
  pipe(my $r, my $w) or die "pipe: $!";
  my $pid = fork();
  die "fork: $!" if not defined $pid;
  if (not $pid) {
    close $r;
    open STDERR, '>', '/dev/null';
    alarm($timeout);
    my @res = eval { $code->() };
    my $err = $@;
    print $w ($err ? "ERR:$err" : "OK:" . join(",", map {defined $_ ? $_ : 'undef'} @res));
    close $w;
    POSIX::_exit(0);
  }
  close $w;
  my $out = do { local $/; <$r> };
  $out = '' if not defined $out;
  waitpid($pid, 0);
  my $st = $?;
  return {
    signal => ($st & 127),
    exit   => ($st >> 8),
    ok     => ($st == 0 && $out =~ /^OK:/) ? 1 : 0,
    died   => ($out =~ /^ERR:/) ? 1 : 0,
    result => ($out =~ /^OK:(.*)\z/s ? $1 : undef),
    error  => ($out =~ /^ERR:(.*)\z/s ? $1 : undef),
  };
}

1;
