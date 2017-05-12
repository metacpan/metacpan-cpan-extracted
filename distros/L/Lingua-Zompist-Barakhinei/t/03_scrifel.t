# vim:set filetype=perl:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 03_scrifel.t'

#########################

use Test::More tests => 81;
use Carp;

BEGIN { use_ok 'Lingua::Zompist::Barakhinei', 'scrifel' }

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

form_ok('elirê',  scrifel('elirê',  1), [ qw( eliri  elirî  elir   elirê  elirê  elirîn  ) ]);
form_ok('rikha',  scrifel('rikha',  2), [ qw( rikhi  rikhi  rikhâ  rikhu  rikhê  rikhîn  ) ]);
form_ok('lelê',   scrifel('lelê',   3), [ qw( leli   leli   lelâ   lelu   lelê   lelîn   ) ]);
form_ok('bêshti', scrifel('bêshti', 4), [ qw( bêshti bêshtê bêshtâ bêshtê bêshtê bêshtên ) ]);
form_ok('habê',   scrifel('habê',   5), [ qw( habi   habê   hap    habê   habê   habên   ) ]);

form_ok('grochê', scrifel('grochê', 1), [ qw( grochi grochî grok   grogê  grogê  grochîn ) ]);
form_ok('foka',   scrifel('foka',   2), [ qw( fochi  fochi  fokâ   foku   fokê   fochîn  ) ]);
form_ok('nochê',  scrifel('nochê',  3), [ qw( nochi  nochi  nogâ   nogu   nogê   nochîn  ) ]);
form_ok('faichi', scrifel('faichi', 4), [ qw( faichi faichê faokâ  faichê faichê faichên ) ]);
form_ok('klachê', scrifel('klachê', 5), [ qw( klachi klachê klach  klachê klachê klachên ) ]);

form_ok('eza',   scrifel('eza'  ), [ qw( fuch  fuch  fâ  fu    fuê   fûn    ) ]);
form_ok('epeza', scrifel('epeza'), [ qw( ûzi   ûzi   epâ ûzu   ûzê   ûzîn   ) ]);
form_ok('kedhê', scrifel('kedhê'), [ qw( kedhi kedhi kiâ kedhu kedhê kedhîn ) ]);

is(scrifel('têshtê', 1)->[2], 'têch',  'III.sg of têshtê');
is(scrifel('rhedê',  1)->[2], 'rhedh', 'III.sg of rhedê' );

#form_ok('foli',    scrifel('foli'   ), [ qw( ful     ful   fut   folu    folu    folîn    ) ]);
#form_ok('lhibê',   scrifel('lhibê'  ), [ qw( lhua    lhû   lhu   lhubu   lhubu   lôn      ) ]);
#form_ok('nhê',     scrifel('nhê'    ), [ qw( nhe     ni    ni    nheza   nhezu   nhê      ) ]);
#form_ok('shkrivê', scrifel('shkrivê'), [ qw( shkriva shkri shkri shkrivu shkrivu shkrivôn ) ]);
#form_ok('shtanê',  scrifel('shtanê' ), [ qw( shtâ    shtê  shtê  shtana  shtanu  shtôn    ) ]);
#form_ok('fâli',    scrifel('fâli'   ), [ qw( fâl     fêl   fêl   fâlu    fâlu    fâlîn    ) ]);
#form_ok('hizi',    scrifel('hizi'   ), [ qw( huz     hu    hut   hizu    hizu    hizîn    ) ]);
#form_ok('oi',      scrifel('oi'     ), [ qw( oh      fi    fit   ou      ou      oîn      ) ]);
