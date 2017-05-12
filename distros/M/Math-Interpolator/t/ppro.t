use warnings;
use strict;

use Test::More tests => 17;

BEGIN { use_ok "Math::Interpolator::Linear"; }
BEGIN { use_ok "Math::Interpolator::Knot"; }
BEGIN { use_ok "Math::Interpolator::Source"; }

sub pt(@) { Math::Interpolator::Knot->new(@_) }
sub proto(@) { Math::Interpolator::Source->new(@_) }

my $a6_called = 0;
sub a6() {
	$a6_called++;
	return [ pt(4, 6), pt(6, 7) ];
}

my $a5_called = 0;
sub a5() {
	$a5_called++;
	return [ pt(1, 0), pt(3, 5), proto(\&a6, 6), pt(9, 7.75) ];
}

my $ipl = Math::Interpolator::Linear->new(pt(0, 1), proto(\&a5, 5), pt(10, 8));

is $a5_called, 0;
is $a6_called, 0;
is $ipl->y(0.25), 0.75;
is $a5_called, 1;
is $a6_called, 0;
is $ipl->y(2), 2.5;
is $a5_called, 1;
is $a6_called, 0;
is $ipl->y(3.5), 5.5;
is $a5_called, 1;
is $a6_called, 1;
is $ipl->y(5), 6.5;
is $a5_called, 1;
is $a6_called, 1;

1;
