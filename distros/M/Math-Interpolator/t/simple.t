use warnings;
use strict;

use Test::More tests => 11;

BEGIN { use_ok "Math::Interpolator::Linear"; }

BEGIN { use_ok "Math::Interpolator::Knot"; }

sub pt(@) { Math::Interpolator::Knot->new(@_) }

my $ipl = Math::Interpolator::Linear->new(pt(3, 5), pt(4, 6), pt(6, 5),
		pt(9, 5.75));

eval { $ipl->y(2.5); };
like $@, qr/\Adata does not extend to x=2\.5 /;

is $ipl->y(3), 5;
is $ipl->y(3.25), 5.25;
is $ipl->y(4), 6;
is $ipl->y(4.25), 5.875;
is $ipl->y(6), 5;
is $ipl->y(6.5), 5.125;
is $ipl->y(9), 5.75;

eval { $ipl->y(9.5); };
like $@, qr/\Adata does not extend to x=9\.5 /;

1;
