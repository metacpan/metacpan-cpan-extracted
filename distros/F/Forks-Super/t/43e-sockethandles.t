use Forks::Super ':test';
use Forks::Super::Util qw(is_socket);
use Test::More tests => 13;
use Carp;
use strict;
use warnings;

#
# complex commands (with pipes) that expect
# input require special handling
#

#######################################################

my $command1 = "$^X t/external-command.pl -s=3 -y=1 -y=1";
my $command2 = "$^X t/external-command.pl -s=1 -y=10 -y=4";
my $cmd = "$command1 | $command2";
my $msg = sprintf "%x", rand() * 99999999;

my $pid = fork { cmd => $cmd, timeout => 10, child_fh => "all,socket" };

ok(isValidPid($pid), "$$\\fork successful");
ok(defined $Forks::Super::CHILD_STDIN{$pid},  "\%CHILD_STDIN defined");
ok(defined $Forks::Super::CHILD_STDOUT{$pid}, "\%CHILD_STDOUT defined");
ok(defined $Forks::Super::CHILD_STDERR{$pid}, "\%CHILD_STDERR defined");

if ($^O eq 'MSWin32' && defined($Forks::Super::IPC_DIR)) {
    ok(!is_socket($Forks::Super::CHILD_STDIN{$pid}),                  ### 5 ###
       "CHILD_STDIN is not a socket for cmd-style fork on MSWin32");
    ok(!is_socket($Forks::Super::CHILD_STDOUT{$pid}),
       "CHILD_STDOUT is not a socket for cmd-style fork on MSWin32");
} else {
    ok(is_socket($Forks::Super::CHILD_STDIN{$pid}),                   ### 5 ###
       "CHILD_STDIN is a socket for cmd-style fork");
    ok(is_socket($Forks::Super::CHILD_STDOUT{$pid}),
       "CHILD_STDOUT is a socket for cmd-style fork");
}

my $fh_in = $Forks::Super::CHILD_STDIN{$pid};
my $z = print $fh_in "$msg\n";
ok($z > 0, "print to child STDIN successful");
$z = print {$fh_in} "Whirled peas\n";
ok($z > 0, "2nd print to child STDIN successful");
$pid->close_fh('stdin');

my $t = Time::HiRes::time();
waitpid $pid, 0;
$t = Time::HiRes::time() - $t;
okl($t > 1.01 && $t < 6.25,              ### 9 ### was 1.25/5.05,obs 1.05/6.12
   "compound command took ${t}s, expected ~2s");
sleep 1;

my @out = Forks::Super::read_stdout($pid);
my @err = Forks::Super::read_stderr($pid);
ok(@out == 15, "got 15==" . scalar @out . " lines of output")
	or diag("Output was:\n-------\n",@out,"--------\n");

# could be 2 or 4 lines of error output, it's OS-dependent.
# It depends on whether the error from $command1
# makes it to the $cmd error output stream.

ok(@err == 2 || @err==4, "got " . scalar @err . "==2 or 4 lines of error")
	or diag("Error was:\n------\n@err\n-------\n");
ok($out[0] eq "$msg\n", "got expected output from child");
ok($err[0] =~ /received message $msg/, "got expected error from child");
Forks::Super::close_fh($pid, 'stdin');
waitall;
