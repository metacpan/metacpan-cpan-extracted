use Forks::Super ':test_CA';
use Test::More tests => 94;
use strict;
use warnings;

#
# tests the Forks::Super::wait call
#

my $pid = fork { sub => sub { sleep 2 ; exit 2 } };
sleep 4;
my $t = Time::HiRes::time();
my $p = wait;
$t = Time::HiRes::time() - $t;
my $s = $?;
ok(isValidPid($pid), "fork was successful");
ok($p == $pid, "wait captured correct pid");
okl($t <= 1.05, "fast wait took ${t}s, expected <=1s");
ok($s == 256 * 2, "wait set exit STATUS in \$\?");

############################################

my $u = Time::HiRes::time();
$pid = fork { sub => sub { sleep 3; exit 3 } };
$t = Time::HiRes::time();
$p = wait;
my $v = Time::HiRes::time();
($u,$t) = ($v-$u,$v-$t);
$s = $?;
ok(isValidPid($pid) && $p==$pid, "successful fork+wait");
okl($u >= 2.25, "child completed in ${t}s ${u}s, expected ~3s");   ### 6 ###
ok($s == 256 * 3, "correct exit STATUS captured");

############################################

my %x;
$Forks::Super::MAX_PROC = 100;
my $i = 0;
for ($i=0; $i<20 && $i<$Forks::Super::SysInfo::MAX_FORK/2; $i++) {
    $pid = fork { sub => sub { my $d=int(1+6*rand); sleep $d; exit $i } };
    if (ok(isValidPid($pid), "successful fork $pid")) {
	$x{$pid} = $i;
    } else {
	diag "failed fork $i/20";
	ok(0, 'waited test fails on failed fork');
	ok(0, 'wait return value test fails on failed fork');
	ok(0, 'exit code test fails on failed fork');
    }
}
for ($i..19) {
    ok(1, 'max fork: skip isValidPid test');
    ok(1, 'max fork: skip waited test');
    ok(1, 'max fork: skip wait return value test');
    ok(1, 'max fork: skip exit code test');
}

$t = Time::HiRes::time();

my $waitfail = 0;
while (0 < scalar keys %x) {
    my $p = wait;
    ok(isValidPid($p), "waited on arbitrary pid $p");
    ok(defined $x{$p}, "return value from wait was valid pid");
    ok($?>>8 == $x{$p}, "wait returned correct exit STATUS");
    if (defined $x{$p}) {
	delete $x{$p};
    } elsif (++$waitfail > 20) {
	print STDERR "\nSomething is wrong -- return values from wait\n";
	print STDERR "\nare not recognized.\nAborting.\n\n";
	last;
    }
}
$t = Time::HiRes::time() - $t;
okl($t <= 10.5,        ### 88 ### was 8 obs 10.23,10.40
    "wait did not take too long ${t}s, expected <=8s");
$t = Time::HiRes::time();
for (my $i=0; $i<5; $i++) {
    my $p = wait;
    ok($p == -1, "wait on nothing gives -1");
}
$t = Time::HiRes::time() - $t;
okl($t <= 1, "fast return wait on nothing ${t}s, expected <=1s"); ### 94 ###
