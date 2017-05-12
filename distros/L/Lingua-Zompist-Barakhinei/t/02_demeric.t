# vim:set filetype=perl:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 02_demeric.t'

#########################

use Test::More tests => 134;
use Carp;

BEGIN { use_ok 'Lingua::Zompist::Barakhinei', 'demeric' }

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

form_ok('elirê',  demeric('elirê',  1), [ qw( elira elirû  elirê  eliru  eliru  elirôn  ) ]);
form_ok('rikha',  demeric('rikha',  2), [ qw( rikhâ rikhê  rikhê  rikha  rikhu  rikhôn  ) ]);
form_ok('lelê',   demeric('lelê',   3), [ qw( lelâ  lelê   lelê   lela   lelu   lelên   ) ]);
form_ok('bêshti', demeric('bêshti', 4), [ qw( bêch  bêshtû bêshti bêkchu bêkchu bêshtîn ) ]);
form_ok('habê',   demeric('habê',   5), [ qw( hap   habû   habê   habu   habu   habun   ) ]);

form_ok('grochê', demeric('grochê', 1), [ qw( groga grochû grochê grogu  grogu  grogôn  ) ]);
form_ok('foka',   demeric('foka',   2), [ qw( fokâ  fochê  fochê  foka   foku   fokôn   ) ]);
form_ok('nochê',  demeric('nochê',  3), [ qw( nogâ  nochê  nochê  nocha  nochu  nochên  ) ]);
form_ok('faichi', demeric('faichi', 4), [ qw( faok  faochû faichi faoku  faoku  faichîn ) ]);
form_ok('klachê', demeric('klachê', 5), [ qw( klak  klachû klachê klagu  klagu  klagun  ) ]);

form_ok('eza',     demeric('eza'    ), [ qw( sâ      sê    ê     eza     ezu     sôn      ) ]);
form_ok('epeza',   demeric('epeza'  ), [ qw( ûzâ     ûzê   epê   epeza   epezu   ûzôn     ) ]);
form_ok('foli',    demeric('foli'   ), [ qw( ful     ful   fut   folu    folu    folîn    ) ]);
form_ok('lhibê',   demeric('lhibê'  ), [ qw( lhua    lhû   lhu   lhubu   lhubu   lôn      ) ]);
form_ok('kedhê',   demeric('kedhê'  ), [ qw( kedhâ   kedhê kedhu kedha   kedhu   kên      ) ]);
form_ok('nhê',     demeric('nhê'    ), [ qw( nhe     ni    ni    nheza   nhezu   nhên     ) ]);
form_ok('shkrivê', demeric('shkrivê'), [ qw( shkriva shkri shkri shkrivu shkrivu shkrivôn ) ]);
form_ok('shtanê',  demeric('shtanê' ), [ qw( shtâ    shtê  shtê  shtana  shtanu  shtôn    ) ]);
form_ok('fâli',    demeric('fâli'   ), [ qw( fâl     fêl   fêl   fâlu    fâlu    fâlîn    ) ]);
form_ok('hizi',    demeric('hizi'   ), [ qw( huz     hu    hut   hizu    hizu    hizîn    ) ]);
form_ok('oi',      demeric('oi'     ), [ qw( oh      fi    fit   ou      ou      oîn      ) ]);

is(demeric('chura', 2)->[1], 'chirê', 'II.sg of chura');
form_ok('sidê', demeric('sidê', 5), [ qw( sidh sidû sidê sidhu sidhu sidhun ) ]);
