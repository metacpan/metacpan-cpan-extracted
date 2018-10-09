use Forks::Super ':test';
use Test::More tests => 24;
use strict;
use warnings;

#
# test forking and invoking a shell command
#

my $output = "t/out/test11.$$";
my @cmd = ($^X,"t/external-command.pl",
	"-o=$output", "-e=Hello,", "-e=Whirled",
	"-p", "-x=0");
my @cmdx = ($^X,"t/external command.pl",
	"-o=$output", "-e=Hello,", "-e=Whirled",
	"-p", "-x=0");
my $cmd = "@cmd";

# test  fork  cmd => \@

unlink $output;
my $pid = fork {cmd => \@cmd };
ok(isValidPid($pid), "$$\\fork to \@command successful");
my $p = Forks::Super::wait;
ok($pid == $p, "wait reaped child $pid == $p");
ok($? == 0, "child STATUS \$? == 0")
   or diag("Child status was $?, expected 0");
my $z = do { my $fh; open($fh, "<", $output); join '', <$fh> };
$z =~ s/\s+$//;
my $target_z = "Hello, Whirled $pid";
ok($z eq $target_z, 
	"child produced child output \'$z\' vs. \'$target_z\'");

#############################################################################

# test fork cmd with metacharacter

$pid = fork {cmd => \@cmdx };
ok(isValidPid($pid), "$$\\fork to \@command (with special chars) successful");
$p = Forks::Super::wait;
ok($pid == $p, "wait reaped child $pid == $p");
ok($? == 0, "child STATUS \$? == 0")
   or diag("Child status was $?, expected 0");
$z = do { my $fh; open($fh, "<", $output); join '', <$fh> };
$z =~ s/\s+$//;
$target_z = "Hello, Whirled $pid";
ok($z eq $target_z, 
	"child produced child output \'$z\' vs. \'$target_z\'");

#############################################################################

# test  fork  cmd => $

unlink $output;
$pid = fork { cmd => $cmd };
ok(isValidPid($pid), "fork to \$command successful");
$p = wait;
ok($pid == $p, "wait reaped child $pid == $p");
ok($? == 0, "child STATUS \$? == 0") or diag("status was $?, expected 0");
$z = do { open my $fh, "<", $output; join '', <$fh> };
$z =~ s/\s+$//;
$target_z = "Hello, Whirled $pid";
ok($z eq $target_z,
	"child produced child output \'$z\' vs. \'$target_z\'");    ### 8 ###

##################################################################

# test that timing of reap is correct

my $u = Time::HiRes::time();
$pid = fork { cmd => [ $^X, "t/external-command.pl", "-s=5" ] };
ok(isValidPid($pid), "fork to external command");
my $t = Time::HiRes::time();
$p = wait;
my $v = Time::HiRes::time();
($t,$u) = ($v-$t, $v-$u);
ok($p == $pid, "wait reaped correct pid");
okl($u >= 3.75 && $t <= 9.35,             ### 11 ### was 6.5 obs 9.33,8.98,3.86
   "background command ran for ${t}s ${u}s, expected 5-6s");

##################################################################

# test exit status

$pid = fork { cmd => [ $^X, "t/external-command.pl", "-x=5" ] };
ok(isValidPid($pid), "fork to external command");
$p = wait;
ok($p == $pid, "wait reaped correct pid");
ok(($?>>8) == 5, "captured correct non-zero STATUS  $?");

##################################################################

$pid = fork { cmd => [ $^X, "t/external command.pl", "-x=0" ] };
ok(isValidPid($pid), "fork to external command (with special char)");
$p = wait;
ok($p == $pid, "wait reaped correct pid");
ok($? == 0, "captured correct zero STATUS");

#############################################################################

# test fork [@cmd] syntax

$pid = fork [ $^X, "t/external-command.pl", "-x=3" ];
ok(isValidPid($pid), "fork [\@cmd] syntax ok");
$p = wait;
ok($p == $pid, "wait reaped correct pid");
ok($?>>8 == 3, "captured correct non-zero STATUS");

#############################################################################

unlink $output;

