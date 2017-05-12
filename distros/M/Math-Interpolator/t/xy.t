use warnings;
use strict;

use Test::More tests => 20;

BEGIN { use_ok "Math::Interpolator::Linear"; }

BEGIN { use_ok "Math::Interpolator::Knot"; }

sub pt(@) { Math::Interpolator::Knot->new(@_) }

my $ipl = Math::Interpolator::Linear->new(pt(3, 5), pt(4, 6), pt(6, 7),
			pt(9, 7.75));

eval { $ipl->y(2.5); };
like $@, qr/\Adata does not extend to x=2\.5 /;

eval { $ipl->y(9.5); };
like $@, qr/\Adata does not extend to x=9\.5 /;

eval { $ipl->x(4.5); };
like $@, qr/\Adata does not extend to y=4\.5 /;

eval { $ipl->x(8); };
like $@, qr/\Adata does not extend to y=8 /;

sub check($$) {
	my($x, $y) = @_;
	is $ipl->y($x), $y;
	is $ipl->x($y), $x;
}

check(3, 5);
check(3.25, 5.25);
check(4, 6);
check(4.25, 6.125);
check(6, 7);
check(6.5, 7.125);
check(9, 7.75);

1;
