# vim:set filetype=perl sw=4 et:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 14.t'

#########################

use Test::More tests => 290;
use Carp;

BEGIN {use_ok 'Lingua::Zompist::Verdurian', 'noun', 'adj'; }

sub noun_form_ok {
    croak 'usage: noun_form_ok($noun, $is, $should)' unless @_ == 3;
    my($noun, $is, $should) = @_;

    is($is->[0], $should->[0], "nom.sg. of $noun");
    is($is->[1], $should->[1], "gen.sg. of $noun");
    is($is->[2], $should->[2], "acc.sg. of $noun");
    is($is->[3], $should->[3], "dat.sg. of $noun");
    is($is->[4], $should->[4], "nom.pl. of $noun");
    is($is->[5], $should->[5], "gen.pl. of $noun");
    is($is->[6], $should->[6], "acc.pl. of $noun");
    is($is->[7], $should->[7], "dat.pl. of $noun");
}

sub adj_form_ok {
    croak 'usage: adj_form_ok($adj, $is, $should)' unless @_ == 3;
    my($adj, $is, $should) = @_;

    is($is->[0][0], $should->[0][0], "masc.nom.sg. of $adj");
    is($is->[0][1], $should->[0][1], "masc.gen.sg. of $adj");
    is($is->[0][2], $should->[0][2], "masc.acc.sg. of $adj");
    is($is->[0][3], $should->[0][3], "masc.dat.sg. of $adj");
    is($is->[0][4], $should->[0][4], "masc.nom.pl. of $adj");
    is($is->[0][5], $should->[0][5], "masc.gen.pl. of $adj");
    is($is->[0][6], $should->[0][6], "masc.acc.pl. of $adj");
    is($is->[0][7], $should->[0][7], "masc.dat.pl. of $adj");
    is($is->[1][0], $should->[1][0], "fem.nom.sg. of $adj");
    is($is->[1][1], $should->[1][1], "fem.gen.sg. of $adj");
    is($is->[1][2], $should->[1][2], "fem.acc.sg. of $adj");
    is($is->[1][3], $should->[1][3], "fem.dat.sg. of $adj");
    is($is->[1][4], $should->[1][4], "fem.nom.pl. of $adj");
    is($is->[1][5], $should->[1][5], "fem.gen.pl. of $adj");
    is($is->[1][6], $should->[1][6], "fem.acc.pl. of $adj");
    is($is->[1][7], $should->[1][7], "fem.dat.pl. of $adj");
}

# Test default (should be on)

is($Lingua::Zompist::Verdurian::keep_accents, 1, 'keep_accents == 1');

noun_form_ok('lavísia', noun('lavísia'), [ qw( lavísia lavísë lavísiam lavísian
                                               lavísiî lavísië lavísem lavísen ) ]);
noun_form_ok('barsúc', noun('barsúc'), [ qw( barsúc barsúcei barsúc barsucán
                                             barsúsî barsúsië barsúsi barsúsin ) ]);
noun_form_ok('ecelóg', noun('ecelóg'), [ qw( ecelóg ecelógei ecelóg ecelogán
                                             ecelózhi ecelózhië ecelózhi ecelózhin ) ]);
noun_form_ok('etalóg', noun('etalóg'), [ qw( etalóg etalógei etalóg etalogán
                                             etalózhi etalózhië etalózhi etalózhin ) ]);
noun_form_ok('pé', noun('pé'), [ qw( pé péi pá pén pí pië pém pén ) ]);
noun_form_ok('aknó', noun('aknó'), [ qw( aknó aknéi aknám aknón
                                         aknói aknoë aknóm aknóin ) ]);
noun_form_ok('gggó', noun('gggó'), [ qw( gggó gggéi gggám gggón
                                         gggói gggoë gggóm gggóin ) ]);
noun_form_ok('gggú', noun('gggú'), [ qw( gggú gggúi gggúm gggún
                                         gggí ggguë gggóm gggúin ) ]);
noun_form_ok('gggíy', noun('gggíy'), [ qw( gggíy gggíi gggíim gggiín
                                           gggíî gggíë gggíom gggíuin ) ]);
noun_form_ok('gggé', noun('gggé'), [ qw( gggé gggéi gggá gggén
                                         gggí gggië gggém gggén ) ]);
adj_form_ok('munénë', adj('munénë'), [ [ qw( munénë munénëi munénä munenén
                                             munénëi munénëë munenóm munénëin ) ],
                                       [ qw( munéna munéne munéna munénan
                                             munénî munénië munénem munénen ) ] ]);


# explicit keep on

$Lingua::Zompist::Verdurian::keep_accents = 1;

noun_form_ok('lavísia', noun('lavísia'), [ qw( lavísia lavísë lavísiam lavísian
                                               lavísiî lavísië lavísem lavísen ) ]);
noun_form_ok('barsúc', noun('barsúc'), [ qw( barsúc barsúcei barsúc barsucán
                                             barsúsî barsúsië barsúsi barsúsin ) ]);
noun_form_ok('ecelóg', noun('ecelóg'), [ qw( ecelóg ecelógei ecelóg ecelogán
                                             ecelózhi ecelózhië ecelózhi ecelózhin ) ]);
noun_form_ok('etalóg', noun('etalóg'), [ qw( etalóg etalógei etalóg etalogán
                                             etalózhi etalózhië etalózhi etalózhin ) ]);
noun_form_ok('pé', noun('pé'), [ qw( pé péi pá pén pí pië pém pén ) ]);
noun_form_ok('aknó', noun('aknó'), [ qw( aknó aknéi aknám aknón
                                         aknói aknoë aknóm aknóin ) ]);
noun_form_ok('gggó', noun('gggó'), [ qw( gggó gggéi gggám gggón
                                         gggói gggoë gggóm gggóin ) ]);
noun_form_ok('gggú', noun('gggú'), [ qw( gggú gggúi gggúm gggún
                                         gggí ggguë gggóm gggúin ) ]);
noun_form_ok('gggíy', noun('gggíy'), [ qw( gggíy gggíi gggíim gggiín
                                           gggíî gggíë gggíom gggíuin ) ]);
noun_form_ok('gggé', noun('gggé'), [ qw( gggé gggéi gggá gggén
                                         gggí gggië gggém gggén ) ]);
adj_form_ok('munénë', adj('munénë'), [ [ qw( munénë munénëi munénä munenén
                                             munénëi munénëë munenóm munénëin ) ],
                                       [ qw( munéna munéne munéna munénan
                                             munénî munénië munénem munénen ) ] ]);

# explicit keep off

$Lingua::Zompist::Verdurian::keep_accents = 0;

noun_form_ok('lavísia', noun('lavísia'), [ qw( lavísia lavísë lavísiam lavísian
                                               lavísiî lavísië lavisem lavisen ) ]);
noun_form_ok('barsúc', noun('barsúc'), [ qw( barsúc barsúcei barsúc barsucán
                                             barsusî barsúsië barsusi barsusin ) ]);
noun_form_ok('ecelóg', noun('ecelóg'), [ qw( ecelóg ecelógei ecelóg ecelogán
                                             ecelozhi ecelózhië ecelozhi ecelozhin ) ]);
noun_form_ok('etalóg', noun('etalóg'), [ qw( etalóg etalógei etalóg etalogán
                                             etalozhi etalózhië etalozhi etalozhin ) ]);
noun_form_ok('pé', noun('pé'), [ qw( pé pei pá pén pí pië pém pén ) ]);
noun_form_ok('aknó', noun('aknó'), [ qw( aknó aknei aknám aknón
                                         aknoi aknoë aknóm aknoin ) ]);
noun_form_ok('gggó', noun('gggó'), [ qw( gggó gggei gggám gggón
                                         gggoi gggoë gggóm gggoin ) ]);
noun_form_ok('gggú', noun('gggú'), [ qw( gggú gggui gggúm gggún
                                         gggí ggguë gggóm ggguin ) ]);
noun_form_ok('gggíy', noun('gggíy'), [ qw( gggíy gggii gggiim gggiín
                                           gggiî gggíë gggiom gggíuin ) ]);
noun_form_ok('gggé', noun('gggé'), [ qw( gggé gggei gggá gggén
                                         gggí gggië gggém gggén ) ]);
adj_form_ok('munénë', adj('munénë'), [ [ qw( munénë munénëi munénä munenén
                                             munénëi munénëë munenóm munénëin ) ],
                                       [ qw( munena munene munena munenan
                                             munenî munénië munenem munenen ) ] ]);
