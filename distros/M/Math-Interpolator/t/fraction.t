use warnings;
use strict;

use Test::More tests => 11;

BEGIN { use_ok "Math::Interpolator::Linear"; }

BEGIN { use_ok "Math::Interpolator::Knot"; }

sub pt(@) { Math::Interpolator::Knot->new(@_) }

my $ipl = Math::Interpolator::Linear->new(pt(0.3, 5), pt(0.4, 6), pt(0.6, 5),
		pt(0.9, 5.75));

eval { $ipl->y(0.25); };
like $@, qr/\Adata does not extend to x=0\.25 /;

is $ipl->y(0.3), 5;
is $ipl->y(0.325), 5.25;
is $ipl->y(0.4), 6;
is $ipl->y(0.425), 5.875;
is $ipl->y(0.6), 5;
is $ipl->y(0.65), 5.125;
is $ipl->y(0.9), 5.75;

eval { $ipl->y(0.95); };
like $@, qr/\Adata does not extend to x=0\.95 /;

1;
