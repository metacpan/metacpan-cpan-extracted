use v5.36;
use strict;
use warnings;

use Test2::V0;
use POSIX qw(WIFEXITED WEXITSTATUS);

use Linux::Event;

BEGIN {
  eval { require Linux::FD::Pid; 1 } or plan skip_all => "Linux::FD::Pid not installed";
}

my $loop = Linux::Event->new( model => 'reactor' );

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
