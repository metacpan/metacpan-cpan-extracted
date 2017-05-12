use Forks::Super qw(:test overload);
use Test::More tests => 12;
use strict;
use warnings;

$Forks::Super::EMULATION_MODE = 1;

my $pid = fork {
    child_fh => 'in,out',
    sub => sub {
	print STDOUT "hELLO\n";
	sleep 4;
	print STDOUT "wORLD\n";
	sleep 4;
	print STDOUT "abc\n123\n";
    },
};

ok(isValidPid($pid), "$$\\job launched");
sleep 2;
my $t = Time::HiRes::time();
my $y = $pid->read_stdout();
$t = Time::HiRes::time() - $t;
ok($y eq "hELLO\n", "\$obj->read_stdout() ok");
okl($t <= 3.05, 
    "fast return [1] ${t}s expected <=1s"); ### 3 ### was 1,obs 3.03

$t = Time::HiRes::time();
my $z = $pid->read_stdout();
$t = Time::HiRes::time() - $t;
ok($z eq "wORLD\n",
    "\$obj->read_stdout() not waiting, not empty")
    or diag("Got '$z', expected 'wORLD\n'");
okl($t <= 1, "fast return [2] ${t}s expected <= 1s");

$t = Time::HiRes::time();
$z = <$pid>;
$t = Time::HiRes::time() - $t;
ok($z ne '', "<\$obj> not waiting, not empty");
okl($t <= 1, "fast return [3] ${t}s expected <= 1s");
sleep 4;

$t = Time::HiRes::time();
while (<$pid>) {
    last;
}
$t = Time::HiRes::time() - $t;
ok($_ eq "123\n",
   "while (<\$obj>) auto-assign to \$_")
    or diag("got '$_', expected '123\n'");
okl($t <= 1.3, "fast return [4] ${t}s expected <= 1s");    ### 9 ### obs 1.28

$t = Time::HiRes::time();
$z = <$pid>;
$t = Time::HiRes::time() - $t;
ok(!defined($z) || $z eq '',
   "$pid output stream is empty so <\$pid> is empty");
okl($t <= 1, "fast return [5] ${t}s expected <= 1s");
waitall;

for (1 .. 4) {
    $z = <$pid>;
    last if !defined $z;
    sleep 2;
}

ok(!defined($z), "<\$pid> undef on empty stream")          ### 14 ###
  or diag("\$z was \"$z\"");
