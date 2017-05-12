use Test;
use strict;
use warnings;

BEGIN { plan tests => 196 };

use Math::Trig::Units qw(dsin dcos tan sec csc cot asin acos atan asec acsc acot sinh cosh tanh sech csch coth asinh acosh atanh asech acsch acoth );

ok(1);

my $pi = atan2(1,1)*4;

# degrees
Math::Trig::Units::units('degrees');
test_to_from( 0, 30, 45, 60, 90 );

# gradians
Math::Trig::Units::units('gradians');
test_to_from( 0, 25, 50, 75, 100 );

# radians
Math::Trig::Units::units('radians');
test_to_from( 0, $pi/8, $pi/6, $pi/4, $pi/2 );

sub test_to_from {
    my @range = @_;
    for my $x ( @range ) {
        ok( r2dp(asin(dsin($x))), r2dp($x) );
        ok( r2dp(acos(dcos($x))), r2dp($x) );
        ok( r2dp(atan(tan($x))), r2dp($x) );
        ok( r2dp(asec(sec($x))), r2dp($x) );
        ok( r2dp(acsc(csc($x))), r2dp($x) );
        ok( r2dp(acot(cot($x))), r2dp($x) );
        ok( r2dp(asinh(sinh($x))), r2dp($x) );
        ok( r2dp(acosh(cosh($x))), r2dp($x) );
        ok( r2dp(atanh(tanh($x))), r2dp($x) );
        ok( r2dp(asech(sech($x))), r2dp($x) );
        ok( r2dp(acsch(csch($x))), r2dp($x) );
        ok( r2dp(acoth(coth($x))), r2dp($x) );
        ok( r2dp(Math::Trig::Units::rad_to_units(Math::Trig::Units::units_to_rad($x))), r2dp($x) );
    }
}

# remove last 2 decimal places to avoid abberant test failures due to
# the inherrent inaccuracy of floating point math on a computer.
sub r2dp {
    my $num = shift;
    chop $num;
    chop $num;
  return $num;
}

