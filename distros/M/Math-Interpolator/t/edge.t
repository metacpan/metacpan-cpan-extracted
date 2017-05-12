use warnings;
use strict;

use Test::More tests => 3 + 3*8;

BEGIN { use_ok "Math::Interpolator::Linear"; }
BEGIN { use_ok "Math::Interpolator::Knot"; }
BEGIN { use_ok "Math::Interpolator::Source"; }

sub pt(@) { Math::Interpolator::Knot->new(@_) }
sub proto(@) { Math::Interpolator::Source->new(@_) }

my $a5_called = 0;
sub a5() {
	$a5_called++;
	return [ pt(4, 6), pt(6, 7) ];
}

my $ipl;

$ipl = Math::Interpolator::Linear->new(pt(0, 1), pt(1, 0), pt(3, 5),
					proto(\&a5, 5));
is $a5_called, 0;
is $ipl->y(3.5), 5.5;
is $a5_called, 1;

$ipl = Math::Interpolator::Linear->new(pt(0, 1), pt(1, 0), pt(3, 5),
					proto(\&a5, 5));
is $a5_called, 1;
is $ipl->y(4.5), 6.25;
is $a5_called, 2;

$ipl = Math::Interpolator::Linear->new(pt(0, 1), pt(1, 0), pt(3, 5),
					proto(\&a5, 5));
is $a5_called, 2;
is $ipl->y(5.5), 6.75;
is $a5_called, 3;

$ipl = Math::Interpolator::Linear->new(pt(0, 1), pt(1, 0), pt(3, 5),
					proto(\&a5, 5));
is $a5_called, 3;
eval { $ipl->y(6.5); };
like $@, qr/\Adata does not extend to x=6\.5 /;
is $a5_called, 4;

$ipl = Math::Interpolator::Linear->new(proto(\&a5, 5), pt(7, 8), pt(8, 1));
is $a5_called, 4;
eval { $ipl->y(3.5); };
like $@, qr/\Adata does not extend to x=3\.5 /;
is $a5_called, 5;

$ipl = Math::Interpolator::Linear->new(proto(\&a5, 5), pt(7, 8), pt(8, 1));
is $a5_called, 5;
is $ipl->y(4.5), 6.25;
is $a5_called, 6;

$ipl = Math::Interpolator::Linear->new(proto(\&a5, 5), pt(7, 8), pt(8, 1));
is $a5_called, 6;
is $ipl->y(5.5), 6.75;
is $a5_called, 7;

$ipl = Math::Interpolator::Linear->new(proto(\&a5, 5), pt(7, 8), pt(8, 1));
is $a5_called, 7;
is $ipl->y(6.5), 7.5;
is $a5_called, 8;

1;
