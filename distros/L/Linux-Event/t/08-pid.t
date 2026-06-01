use v5.36;
use strict;
use warnings;

use Test2::V0;
use Errno qw(ENOSYS EPERM EINVAL);
use POSIX qw(WIFEXITED WEXITSTATUS);

use Linux::Event;

BEGIN {
  eval { require Linux::FD::Pid; 1 } or plan skip_all => "Linux::FD::Pid not installed";
}

my $pidfd_probe = eval { Linux::FD::Pid->new($$, 'non-blocking') };
if (!$pidfd_probe) {
  my $err = 0 + $!;
  plan skip_all => "pidfd is not available in this environment: $!"
    if $err == ENOSYS || $err == EPERM || $err == EINVAL;
  die $@ if $@;
  die "pidfd probe failed: $!";
}
undef $pidfd_probe;

my $loop = Linux::Event->new;

my $pid = fork();
if (!defined $pid) {
  plan skip_all => "fork() not available: $!";
}

if ($pid == 0) {
  exit 42;
}

my $seen;
my $sub = $loop->pid($pid, sub ($loop, $pid, $status, $data) {
  $seen = $status;
  $loop->stop;
});

$loop->run;

ok(defined $seen, "got wait status");
ok(WIFEXITED($seen), "child exited normally");
is(WEXITSTATUS($seen), 42, "exit code");

done_testing;
