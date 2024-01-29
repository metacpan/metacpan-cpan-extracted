use strict;
use warnings;
use Math::JS;
use Test::More;

my $ryu = Math::JS::USE_RYU;
if($ryu) {
  warn "\nFYI: Stringifying the values of Math::JS objects uses the Ryu algorithm\n";
}
else {
  warn "\nFYI: Stringifying the values of Math::JS objects uses sprintf(\"%.17g\", val)\n";
}

my $pinf = 2 ** 1500;
my $ninf = -$pinf;
my $nan = $pinf / $ninf;

cmp_ok($nan, '!=', $nan, "NaN != NaN");

my $js = Math::JS->new($pinf);
cmp_ok("$js", 'eq', 'Infinity', "Inf displays as expected");

$js = Math::JS->new($ninf);
cmp_ok("$js", 'eq', '-Infinity', "-Inf displays as expected");

$js = Math::JS->new($nan);
cmp_ok("$js", 'eq', 'nan', "NaN displays as expected");

$js = Math::JS->new(1 / 10);
my $got = $ryu ? '0.1' : '0.10000000000000001';
cmp_ok("$js", 'eq', $got, "0.1 displays as expected");

$js = Math::JS->new(2 ** 0.5);
cmp_ok("$js", 'eq', '1.4142135623730951' , "sqrt(2) displays as expected");

$js = Math::JS->new(1.4 / 10);
cmp_ok("$js", 'eq', '0.13999999999999999' , "1.4 / 10 displays as expected");

$js = Math::JS->new(1e+23);
$got = $ryu ? '1e+23' : sprintf("%.17g", 1e+23);
cmp_ok("$js", 'eq', $got, "1e+23 displays as expected");

$js = Math::JS->new(2 ** -1074);
$got = $ryu ? '5e-324' : sprintf("%.17g", 2 ** -1074);
cmp_ok("$js", 'eq', $got, "2 ** -1074 displays as expected");

$js = Math::JS->new(0.123);
cmp_ok("$js", 'eq', '0.123', "0.123 displays as expected");

$js = Math::JS->new(0.1234);
cmp_ok("$js", 'eq', '0.1234', "0.1234 displays as expected");

$js = Math::JS->new((2 ** 53) - 1);
cmp_ok("$js", 'eq', '9007199254740991', "9007199254740991 displays as expected");

$js = Math::JS->new(9007199254740991.0);
cmp_ok("$js", 'eq', '9007199254740991', "9007199254740991.0 displays as expected");

$js = Math::JS->new(4294967297);
cmp_ok("$js", 'eq', '4294967297', "4294967297 displays as expected");

$js = Math::JS->new(1e19);
cmp_ok("$js", 'eq', '1' . '0' x 19, "1e+19 displays as expected");

$js = Math::JS->new(9e20);
cmp_ok("$js", 'eq', '9' . '0' x 20, "9e+20 displays as expected");

$js = Math::JS->new(1e21);
cmp_ok("$js", 'eq', '1e+21', "1e+21 displays as expected");


done_testing();

__END__


