# vim:set filetype=perl sw=4 et:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 181;
use Carp;

BEGIN { use_ok 'Lingua::Zompist::Cadhinor', 'adj'; }

sub form_ok {
    croak 'usage: form_ok($adj, $is, $should)' unless @_ >= 3;
    my($adj, $is, $should) = @_;

    is($is->[0][0], $should->[0][0], "masc.nom.sg. of $adj");
    is($is->[0][1], $should->[0][1], "masc.gen.sg. of $adj");
    is($is->[0][2], $should->[0][2], "masc.acc.sg. of $adj");
    is($is->[0][3], $should->[0][3], "masc.dat.sg. of $adj");
    is($is->[0][4], $should->[0][4], "masc.abl.sg. of $adj");
    is($is->[0][5], $should->[0][5], "masc.nom.pl. of $adj");
    is($is->[0][6], $should->[0][6], "masc.gen.pl. of $adj");
    is($is->[0][7], $should->[0][7], "masc.acc.pl. of $adj");
    is($is->[0][8], $should->[0][8], "masc.dat.pl. of $adj");
    is($is->[0][9], $should->[0][9], "masc.abl.pl. of $adj");
    is($is->[1][0], $should->[1][0], "neut.nom.sg. of $adj");
    is($is->[1][1], $should->[1][1], "neut.gen.sg. of $adj");
    is($is->[1][2], $should->[1][2], "neut.acc.sg. of $adj");
    is($is->[1][3], $should->[1][3], "neut.dat.sg. of $adj");
    is($is->[1][4], $should->[1][4], "neut.abl.sg. of $adj");
    is($is->[1][5], $should->[1][5], "neut.nom.pl. of $adj");
    is($is->[1][6], $should->[1][6], "neut.gen.pl. of $adj");
    is($is->[1][7], $should->[1][7], "neut.acc.pl. of $adj");
    is($is->[1][8], $should->[1][8], "neut.dat.pl. of $adj");
    is($is->[1][9], $should->[1][9], "neut.abl.pl. of $adj");
    is($is->[2][0], $should->[2][0], "fem.nom.sg. of $adj");
    is($is->[2][1], $should->[2][1], "fem.gen.sg. of $adj");
    is($is->[2][2], $should->[2][2], "fem.acc.sg. of $adj");
    is($is->[2][3], $should->[2][3], "fem.dat.sg. of $adj");
    is($is->[2][4], $should->[2][4], "fem.abl.sg. of $adj");
    is($is->[2][5], $should->[2][5], "fem.nom.pl. of $adj");
    is($is->[2][6], $should->[2][6], "fem.gen.pl. of $adj");
    is($is->[2][7], $should->[2][7], "fem.acc.pl. of $adj");
    is($is->[2][8], $should->[2][8], "fem.dat.pl. of $adj");
    is($is->[2][9], $should->[2][9], "fem.abl.pl. of $adj");
}

form_ok('ZOL', adj('ZOL'), [ [ qw( ZOL ZOLEI ZOL ZOLAN ZOLOTH
                                   ZOLIT ZOLIE ZOLI ZOLIN ZOLITH ) ],
                             [ qw( ZOLO ZOLOI ZOLOM ZOLON ZOLOTH
                                   ZOLOI ZOLOIE ZOLOIM ZOLOIN ZOLOITH ) ],
                             [ qw( ZOLA ZOLAE ZOLAA ZOLAN ZOLAD
                                   ZOLET ZOLEIE ZOLEIM ZOLEIN ZOLEID ) ] ]);

form_ok('ALETES', adj('ALETES'), [ [ qw( ALETES ALETEI ALETE ALETEN ALETETH
                                         ALETEIT ALETEIE ALETEI ALETEIN ALETEITH ) ],
                                   [ qw( ALETE ALETEI ALETEM ALETEN ALETETH
                                         ALETEI ALETEIE ALETEIM ALETEIN ALETEITH ) ],
                                   [ qw( ALETIES ALETIAE ALETEA ALETEN ALETED
                                         ALETET ALETEIE ALETEIM ALETEIN ALETEID ) ] ]);

form_ok('ILIS', adj('ILIS'), [ [ qw( ILIS ILII ILI ILIN ILITH
                                     ILUIT ILUIE ILUI ILUIN ILUITH ) ],
                               [ qw( ILIS ILII ILIM ILIN ILITH
                                     ILUI ILUIE ILUIM ILUIN ILUITH ) ],
                               [ qw( ILIS ILIE ILIA ILIN ILID
                                     ILIAT ILIAE ILIAM ILIAN ILIAD ) ] ]);

# test general forms
form_ok('GGG', adj('GGG'), [ [ qw( GGG GGGEI GGG GGGAN GGGOTH
                                   GGGIT GGGIE GGGI GGGIN GGGITH ) ],
                             [ qw( GGGO GGGOI GGGOM GGGON GGGOTH
                                   GGGOI GGGOIE GGGOIM GGGOIN GGGOITH ) ],
                             [ qw( GGGA GGGAE GGGAA GGGAN GGGAD
                                   GGGET GGGEIE GGGEIM GGGEIN GGGEID ) ] ]);

form_ok('GGGES', adj('GGGES'), [ [ qw( GGGES GGGEI GGGE GGGEN GGGETH
                                       GGGEIT GGGEIE GGGEI GGGEIN GGGEITH ) ],
                                 [ qw( GGGE GGGEI GGGEM GGGEN GGGETH
                                       GGGEI GGGEIE GGGEIM GGGEIN GGGEITH ) ],
                                 [ qw( GGGIES GGGIAE GGGEA GGGEN GGGED
                                       GGGET GGGEIE GGGEIM GGGEIN GGGEID ) ] ]);

form_ok('GGGIS', adj('GGGIS'), [ [ qw( GGGIS GGGII GGGI GGGIN GGGITH
                                       GGGUIT GGGUIE GGGUI GGGUIN GGGUITH ) ],
                                 [ qw( GGGIS GGGII GGGIM GGGIN GGGITH
                                       GGGUI GGGUIE GGGUIM GGGUIN GGGUITH ) ],
                                 [ qw( GGGIS GGGIE GGGIA GGGIN GGGID
                                       GGGIAT GGGIAE GGGIAM GGGIAN GGGIAD ) ] ]);
