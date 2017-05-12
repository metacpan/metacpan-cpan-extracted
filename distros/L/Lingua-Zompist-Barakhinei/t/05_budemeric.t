# vim:set filetype=perl:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 05_budemeric.t'

#########################

use Test::More tests => 37;
use Carp;

BEGIN { use_ok 'Lingua::Zompist::Barakhinei', 'budemeric' }

sub form_ok ($$$) {
    # croak 'usage: form_ok($verb, $is, $should)' unless @_ >= 3;
    my($verb, $is, $should) = @_;

    is($is->[0], $should->[0], "I.sg. of $verb");
    is($is->[1], $should->[1], "II.sg. of $verb");
    is($is->[2], $should->[2], "III.sg. of $verb");
    is($is->[3], $should->[3], "I.pl. of $verb");
    is($is->[4], $should->[4], "II.pl. of $verb");
    is($is->[5], $should->[5], "III.pl. of $verb");
}

form_ok('elirê',  budemeric('elirê',  1), [ qw( elirta   elirtê   elirtê elirtu  elirtu  elirtôn ) ]);
form_ok('rikha',  budemeric('rikha',  2), [ qw( rikhmâ   rikhmê   rikhmê rikhma  rikhmu  rikhmôn ) ]);
form_ok('lelê',   budemeric('lelê',   3), [ qw( lelmâ    lelmê    lelmê  lelma   lelmu   lelmên  ) ]);
form_ok('bêshti', budemeric('bêshti', 4), [ qw( bêshtech bêshtech bêshti bêshchu bêshchu bêshtîn ) ]);
form_ok('habê',   budemeric('habê',   5), [ qw( habech   habech   habti  habchu  habchu  habtîn  ) ]);

#form_ok('grochê', izhcrifel('grochê', 1), [ qw( grochi grochî grok   grogê  grogê  grochîn ) ]);
#form_ok('foka',   izhcrifel('foka',   2), [ qw( fochi  fochi  fokâ   foku   fokê   fochîn  ) ]);
#form_ok('nochê',  izhcrifel('nochê',  3), [ qw( nochi  nochi  nogâ   nogu   nogê   nochîn  ) ]);
#form_ok('faichi', izhcrifel('faichi', 4), [ qw( faichi faichê faokâ  faichê faichê faichên ) ]);
#form_ok('klachê', izhcrifel('klachê', 5), [ qw( klachi klachê klach  klachê klachê klachên ) ]);

form_ok('eza',  budemeric('eza'), [ qw( êshta êshtê êshtê êshta êshtu êshtôn ) ]);

#form_ok('epeza', izhcrifel('epeza'), [ qw( ûzi   ûzi   epâ ûzu   ûzê   ûzîn   ) ]);
#form_ok('kedhê', izhcrifel('kedhê'), [ qw( kedhi kedhi kiâ kedhu kedhê kedhîn ) ]);

#form_ok('foli',    izhcrifel('foli'   ), [ qw( ful     ful   fut   folu    folu    folîn    ) ]);
#form_ok('lhibê',   izhcrifel('lhibê'  ), [ qw( lhua    lhû   lhu   lhubu   lhubu   lôn      ) ]);
#form_ok('nhê',     izhcrifel('nhê'    ), [ qw( nhe     ni    ni    nheza   nhezu   nhê      ) ]);
#form_ok('shkrivê', izhcrifel('shkrivê'), [ qw( shkriva shkri shkri shkrivu shkrivu shkrivôn ) ]);
#form_ok('shtanê',  izhcrifel('shtanê' ), [ qw( shtâ    shtê  shtê  shtana  shtanu  shtôn    ) ]);
#form_ok('fâli',    izhcrifel('fâli'   ), [ qw( fâl     fêl   fêl   fâlu    fâlu    fâlîn    ) ]);
#form_ok('hizi',    izhcrifel('hizi'   ), [ qw( huz     hu    hut   hizu    hizu    hizîn    ) ]);
#form_ok('oi',      izhcrifel('oi'     ), [ qw( oh      fi    fit   ou      ou      oîn      ) ]);
