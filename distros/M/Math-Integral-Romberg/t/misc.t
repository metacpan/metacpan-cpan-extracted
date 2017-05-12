use Test;
use Math::Integral::Romberg 'integral';

BEGIN {
  plan (tests => 2);
}

my ($expected, $actual);

$expected = 0.49996832875817;
$actual = integral(\&gaussian, 0, 4);

ok (abs($expected - $actual) < 1e-10);

$expected = sinex(3) - sinex(-1);
$actual = integral(\&dsinex, -1, 3, 1e-6, 1e-6, 6, 6);

my $expected_error = -0.005350074;

my $actual_error = $actual - $expected;

ok (abs($actual_error - $expected_error) < 1e-8);

sub gaussian { exp(-$_[0]**2/2)/sqrt(2 * 3.14159265358979) }
sub sinex { sin(exp($_[0])) }
sub dsinex { exp($_[0]) * cos(exp($_[0])) }
