# vim:set filetype=perl sw=4 et:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 216;
use Carp;

BEGIN { use_ok 'Lingua::Zompist::Cadhinor', 'noun', 'adj'; }

sub form_ok {
    croak 'usage: form_ok($noun, $is, $should)' unless @_ >= 3;
    my($noun, $is, $should) = @_;

    is($is->[0], $should->[0], "nom.sg. of $noun");
    is($is->[1], $should->[1], "gen.sg. of $noun");
    is($is->[2], $should->[2], "acc.sg. of $noun");
    is($is->[3], $should->[3], "dat.sg. of $noun");
    is($is->[4], $should->[4], "abl.sg. of $noun");
    is($is->[5], $should->[5], "nom.pl. of $noun");
    is($is->[6], $should->[6], "gen.pl. of $noun");
    is($is->[7], $should->[7], "acc.pl. of $noun");
    is($is->[8], $should->[8], "dat.pl. of $noun");
    is($is->[9], $should->[9], "abl.pl. of $noun");
}

sub sg_form_ok {
    croak 'usage: form_ok($noun, $is, $should)' unless @_ >= 3;
    my($noun, $is, $should) = @_;

    is($is->[0], $should->[0], "nom. of $noun");
    is($is->[1], $should->[1], "gen. of $noun");
    is($is->[2], $should->[2], "acc. of $noun");
    is($is->[3], $should->[3], "dat. of $noun");
    is($is->[4], $should->[4], "abl. of $noun");
}

sub adj_form_ok {
    croak 'usage: form_ok($adj, $is, $should)' unless @_ >= 3;
    my($adj, $is, $should) = @_;

    is($is->[0][0], $should->[0][0], "masc.nom.sg. of $adj");
    is($is->[0][1], $should->[0][1], "masc.gen.sg. of $adj");
    is($is->[0][2], $should->[0][2], "masc.acc.sg. of $adj");
    is($is->[0][3], $should->[0][3], "masc.dat.sg. of $adj");
    is($is->[0][4], $should->[0][4], "masc.abl.sg. of $adj");
    is($is->[0][5], undef,           "masc.nom.pl. of $adj");
    is($is->[0][6], undef,           "masc.gen.pl. of $adj");
    is($is->[0][7], undef,           "masc.acc.pl. of $adj");
    is($is->[0][8], undef,           "masc.dat.pl. of $adj");
    is($is->[0][9], undef,           "masc.abl.pl. of $adj");
    is($is->[1][0], $should->[1][0], "neut.nom.sg. of $adj");
    is($is->[1][1], $should->[1][1], "neut.gen.sg. of $adj");
    is($is->[1][2], $should->[1][2], "neut.acc.sg. of $adj");
    is($is->[1][3], $should->[1][3], "neut.dat.sg. of $adj");
    is($is->[1][4], $should->[1][4], "neut.abl.sg. of $adj");
    is($is->[1][5], undef,           "neut.nom.pl. of $adj");
    is($is->[1][6], undef,           "neut.gen.pl. of $adj");
    is($is->[1][7], undef,           "neut.acc.pl. of $adj");
    is($is->[1][8], undef,           "neut.dat.pl. of $adj");
    is($is->[1][9], undef,           "neut.abl.pl. of $adj");
    is($is->[2][0], $should->[2][0], "fem.nom.sg. of $adj");
    is($is->[2][1], $should->[2][1], "fem.gen.sg. of $adj");
    is($is->[2][2], $should->[2][2], "fem.acc.sg. of $adj");
    is($is->[2][3], $should->[2][3], "fem.dat.sg. of $adj");
    is($is->[2][4], $should->[2][4], "fem.abl.sg. of $adj");
    is($is->[2][5], undef,           "fem.nom.pl. of $adj");
    is($is->[2][6], undef,           "fem.gen.pl. of $adj");
    is($is->[2][7], undef,           "fem.acc.pl. of $adj");
    is($is->[2][8], undef,           "fem.dat.pl. of $adj");
    is($is->[2][9], undef,           "fem.abl.pl. of $adj");
}



# Personal pronouns

form_ok('SEO', noun('SEO'), [ qw( SEO  EAE  ETH  SEON ED
                                  TAS  TAIE TAIM TAUN TAD   ) ]);
form_ok('LET', noun('LET'), [ qw( LET  LEAE EK   LUN  LETH
                                  MUKH MUIE MUIM MUIN MUOTH ) ]);
form_ok('TU',  noun('TU' ), [ qw( TU   TUAE TUA  TUN  TOTH
                                  CAI  CAIE CAIM CAIN CAITH ) ]);
form_ok('ZE', noun('ZE'), [ undef, qw( ZEHIE ZETH  ZEHUN ZEHOTH ),
                            undef, qw( ZAHIE ZAHAM ZAHAN ZAHATH ) ]);


# Relative and interrogative pronouns

sg_form_ok('AELU', noun('AELU'), [ qw( AELU AELUI AELETH AELUN AELOTH ) ]);
sg_form_ok('AELO', noun('AELO'), [ qw( AELO AELOI AELOR  AELON AELOTH ) ]);
sg_form_ok('AELA', noun('AELA'), [ qw( AELA AELAE AELEA  AELAN AELAD  ) ]);
sg_form_ok('ILLU', noun('ILLU'), [ qw( ILLU ILLUI ILLETH ILLUN ILLOTH ) ]);
sg_form_ok('ILLO', noun('ILLO'), [ qw( ILLO ILLOI ILLO   ILLON ILLOTH ) ]);
sg_form_ok('ILLA', noun('ILLA'), [ qw( ILLA ILLAE ILLEA  ILLAN ILLAD  ) ]);

adj_form_ok('AELU', adj('AELU'), [ [ qw( AELU AELUI AELETH AELUN AELOTH ) ],
                                   [ qw( AELO AELOI AELOR  AELON AELOTH ) ],
                                   [ qw( AELA AELAE AELEA  AELAN AELAD  ) ] ]);
adj_form_ok('ILLU', adj('ILLU'), [ [ qw( ILLU ILLUI ILLETH ILLUN ILLOTH ) ],
                                   [ qw( ILLO ILLOI ILLO   ILLON ILLOTH ) ],
                                   [ qw( ILLA ILLAE ILLEA  ILLAN ILLAD  ) ] ]);

sg_form_ok('AECTA', noun('AECTA'), [ qw( AECTA AECTAE AECTAA AECTAN AECTAD ) ]);
sg_form_ok('CESTA', noun('CESTA'), [ qw( CESTA CESTAE CESTAA CESTAN CESTAD ) ]);

form_ok('KAE', noun('KAE'), [ qw( KAE  KAIE  KAETH KAEN  KAETH
                                  KAHE KAHIE KAHAM KAHAN KAHATH ) ]);
sg_form_ok( 'KETTOS', noun( 'KETTOS'), [ qw(  KETTOS  KETTEI  KETTOT  KETTAN  KETTOTH ) ]);
sg_form_ok( 'AETTOS', noun( 'AETTOS'), [ qw(  AETTOS  AETTEI  AETTOT  AETTAN  AETTOTH ) ]);
sg_form_ok(  'TOTOS', noun(  'TOTOS'), [ qw(   TOTOS   TOTEI     TOT   TOTAN   TOTOTH ) ]);
sg_form_ok( 'NIKTOS', noun( 'NIKTOS'), [ qw(  NIKTOS  NIKTEI  NIKTOT  NIKTAN  NIKTOTH ) ]);
sg_form_ok( 'NISIOS', noun( 'NISIOS'), [ qw(  NISIOS  NISIEI  NISIOT  NISIAN  NISIOTH ) ]);
sg_form_ok('THISIOS', noun('THISIOS'), [ qw( THISIOS THISIEI THISIOT THISIAN THISIOTH ) ]);

sg_form_ok(   'KEDIE',  noun(   'KEDIE' ), [ qw(    KEDIE    KEDIEI    KEDIA    KEDIEN    KEDID ) ]);
sg_form_ok('THIKEDIE',  noun('THIKEDIE' ), [ qw( THIKEDIE THIKEDIEI THIKEDIA THIKEDIEN THIKEDID ) ]);

sg_form_ok( 'NIES', noun( 'NIES'), [ qw(  NIES  NIEI  NIET  NIEN  NIETH ) ]);
sg_form_ok('PSIES', noun('PSIES'), [ qw( PSIES PSIEI PSIET PSIEN PSIETH ) ]);

sg_form_ok('PSIAT', noun('PSIAT'), [ qw( PSIAT PSIE PSIAT PSIAN PSIAD ) ]);

sg_form_ok('NIKUDA', noun('NIKUDA'), [ qw( NIKUDA NIKUDAE NIKUDAA NIKUDAN NIKUDAD ) ]);
sg_form_ok('PSUDA',  noun('PSUDA' ), [ qw(  PSUDA  PSUDAE  PSUDAA  PSUDAN  PSUDAD ) ]);
