use Forks::Super ':test';
use Test::More tests => 10;
use Carp;
use strict;
use warnings;

#
# complex commands (with pipes) that expect
# input require special handling
#
$ENV{TEST_LENIENT} = 1 if $^O =~ /freebsd|midnightbsd|netbsd/i;

#######################################################

my $command1 = "$^X t/external-command.pl -s=2 -y=2";
my $command2 = "$^X t/external-command.pl -y=10 -y=4";
my $cmd = "$command1 | $command2";
my $msg = sprintf "%x", rand() * 99999999;

my $pid = fork [$cmd], timeout => 10, child_fh => "all";

ok(isValidPid($pid), "$$\\fork successful");
ok(defined $Forks::Super::CHILD_STDIN{$pid},  "\%CHILD_STDIN defined");
ok(defined $Forks::Super::CHILD_STDOUT{$pid}, "\%CHILD_STDOUT defined");
ok(defined $Forks::Super::CHILD_STDERR{$pid}, "\%CHILD_STDERR defined");

my $fh_in = $Forks::Super::CHILD_STDIN{$pid};
my $z = print $fh_in "$msg\n";
Forks::Super::close_fh($pid,'stdin');
ok($z > 0, "print to child STDIN successful");

my $t = Time::HiRes::time();
waitpid $pid, 0;
$t = Time::HiRes::time() - $t;
okl($t > 1.05 && $t < 6.18, #obs 6.17       ### 6 ###
   "compound command took ${t}s, expected ~2s");
sleep 1;

my @out = Forks::Super::read_stdout($pid);
my @err = Forks::Super::read_stderr($pid);
ok(@out == 15,                             ### 7 ###
   "expect 15, got " . scalar @out . " lines of output");

# stderr could receive 2 or 3 lines, depending on whether 
# error from $command1 is concatenated to $command2 or
# goes to actual standard error.
ok(@err == 2 || @err == 3, 
   "expect 2-3, got " . scalar @err . " lines of error");

if (@out != 15 || (@err != 2 && @err != 3)) {
    print STDERR "\@out:\n @out\n-----------------\nerr:\n @err\n----------\n";
}

ok($out[0] eq "$msg\n", "got expected output from child");
ok($err[0] =~ /received message $msg/, "got expected error from child");

#############################################################################

waitall;

