use Forks::Super ':test';
use Test::More tests => 19;
use strict;
use warnings;

#
# test forking and invoking a shell command
#

my $output = "t/out/test11.$$";
my @cmd = ($^X,"t/external-command.pl",
	"-o=$output", "-e=Hello,", "-e=Whirled",
	"-p", "-x=0");
my $cmd = "@cmd";

unlink $output;
my $pid = fork {cmd => \@cmd, emulate => 1 };
diag "emulate pid is $pid";
ok(isValidPid($pid), "$$\\fork to \@command successful");
ok(defined($Forks::Super::ALL_JOBS{$pid}), "job is in \%ALL_JOBS");
ok($pid->is_complete, 'emulated job is already complete');
ok(!$pid->is_reaped, 'emulated job is not already reaped');
my $p = Forks::Super::wait;
ok($pid == $p, "wait reaped child $pid == $p");
ok($? == 0, "child STATUS \$? == 0")            ### 6 ###
   or diag("Child status was $?, expected 0");
my $z = do { my $fh; open($fh, "<", $output); join '', <$fh> };
$z =~ s/\s+$//;
my $target_z = "Hello, Whirled $pid";
$target_z = "Hello, Whirled $$";
ok($z eq $target_z, 
	"child produced child output \'$z\' vs. \'$target_z\'");

##################################################################

# test that timing of reap is correct

my $u = Time::HiRes::time();
$pid = fork { cmd => [ $^X, "t/external-command.pl", "-s=5" ], emulate => 1 };
ok(isValidPid($pid), "fork to external command");
my $t = Time::HiRes::time();
$p = wait;
my $v = Time::HiRes::time();
($t,$u) = ($v-$t, $v-$u);
ok($p == $pid, "wait reaped correct pid");
okl($u >= 4.23 && $t <= 9.35,             ### 10 ###
   "background command ran for ${t}s ${u}s, expected 5-6s");

##################################################################

# test exit status

$pid = fork { cmd => [ $^X, "t/external-command.pl", "-x=0" ], emulate => 1 };
ok(isValidPid($pid), "fork to external command");
$p = wait;
ok($p == $pid, "wait reaped correct pid");
ok($? == 0, "captured correct zero STATUS")   ### 16 ###
    or diag("Expected \$?=0 got $?");

#############################################################################

# test with command with metacharacters

$pid = fork { exec => [ $^X, "t/external command.pl", "-x=5" ], emulate => 1 };
ok(isValidPid($pid), "fork to external command");
$p = wait;
ok($p == $pid, "wait reaped correct pid");
ok(($?>>8) == 5, "captured correct non-zero STATUS  $?")  ### 13 ###
    or diag("Expected \$?=",5<<8," got $?");

##################################################################

# test fork [@cmd] syntax

$pid = fork [ $^X, "t/external-command.pl", "-x=3" ], emulate => 1;
ok(isValidPid($pid), "fork [\@cmd] syntax ok");
$p = wait;
ok($p == $pid, "wait reaped correct pid");
ok($?>>8 == 3, "captured correct non-zero STATUS")    ### 19 ###
    or diag("Expected \$?=",3<<8," got $?");

#############################################################################

unlink $output;
