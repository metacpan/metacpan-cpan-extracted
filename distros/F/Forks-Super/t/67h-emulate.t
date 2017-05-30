use Forks::Super qw(:test overload);
use Test::More tests => 10;
use strict;
use warnings;

$Forks::Super::EMULATION_MODE = 1;

my ($t,$y,$z);

my $pid = fork {
    child_fh => 'in,out,block',
    sub => sub {
	print STDOUT "hELLO\n";
	sleep 4;
	print STDOUT "wORLD\n";
	sleep 4;
	print STDOUT "abc\n123\n";
    }
};

ok(isValidPid($pid), "$$\\job launched");
sleep 1;
$t = Time::HiRes::time();
$y = $pid->read_stdout();
$t = Time::HiRes::time() - $t;
ok($y eq "hELLO\n", "\$obj->read_stdout() ok");
okl($t <= 1, "fast return [11] ${t}s expected <=1s");   ### 17 ###

$t = Time::HiRes::time();
$y = $pid->read_stdout(block => 0);
$t = Time::HiRes::time() - $t;
ok($y eq "wORLD\n", "\$obj->read_stdout(), no block empty in emulation");
okl($t <= 1, "fast return [12] ${t}s expected <=1s");

$t = Time::HiRes::time();
while (<$pid>) {
    last;
}

$t = Time::HiRes::time() - $t;
ok($_ eq "abc\n", "while (<\$obj>) auto-assign to \$_");
okl($t < 2.0, "no blocking read[2] in emulation mode");

$t = Time::HiRes::time();
$z = <$pid>;
$t = Time::HiRes::time() - $t;
ok($z eq "123\n", "<\$pid> ok");
okl($t <= 1, "fast return [5] ${t}s expected <= 1s");
waitall;

$z = <$pid>;
if (defined $z) {
    sleep 5;
    $z = <$pid>;
}
ok(!defined($z), "<\$pid> undef on empty stream")
    or diag("\$z was \"$z\"");
