use warnings;
use strict;

use Test::More tests => 6;

BEGIN { use_ok "Math::Interpolator"; }

BEGIN { use_ok "Math::Interpolator::Knot"; }

my @pts = map { Math::Interpolator::Knot->new($_, $_+1) } 0..10;

my $ipl = Math::Interpolator->new(@pts);

is_deeply [ $ipl->nhood_x(3.5, 1) ], [ @pts[3..4] ];
is_deeply [ $ipl->nhood_x(5.5, 2) ], [ @pts[4..7] ];
is_deeply [ $ipl->nhood_x(6.5, 3) ], [ @pts[4..9] ];
is_deeply [ $ipl->nhood_y(5.5, 2) ], [ @pts[3..6] ];

1;
