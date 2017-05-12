# vim:set filetype=perl encoding=utf-8 fileencoding=utf-8 sw=4 et keymap=cuezi:
#########################

use Test::More tests => 1;
use Carp;

ok(1);

__END__

BEGIN { use_ok 'Lingua::Zompist::Cuezi', 'demeric'; }

sub form_ok {
    croak 'usage: form_ok($verb, $is, $should)' unless @_ >= 3;
    my($verb, $is, $should) = @_;

    is($is->[0], $should->[0], "I.sg. of $verb");
    is($is->[1], $should->[1], "II.sg. of $verb");
    is($is->[2], $should->[2], "III.sg. of $verb");
    is($is->[3], $should->[3], "I.pl. of $verb");
    is($is->[4], $should->[4], "II.pl. of $verb");
    is($is->[5], $should->[5], "III.pl. of $verb");
}

form_ok('LIUBEC', demeric('LIUBEC'), [ qw( LIUO/LIUBAO LIUOS/LIUBEOS LIUS/LIUBES LIUBOM LIUBOUS LIUBONT ) ]);
form_ok('LAUDAN', demeric('LAUDAN'), [ qw( LAUDAI LAUDEIS LAUDET LAUDAM LAUDUS  LAUDONT ) ]);
form_ok('LEILEN', demeric('LEILEN'), [ qw( LEILAI LEILEIS LEILET LEILEM LEILES  LEILENT ) ]);
form_ok('CLAGER', demeric('CLAGER'), [ qw( CLAGU  CLAGEUS CLAGIT CLAGUM CLAGUS  CLAGINT ) ]);
form_ok('NURIR',  demeric('NURIR' ), [ qw( NURU   NUREUS  NURET  NURUM  NURUS   NURUNT  ) ]);

form_ok('ESAN',   demeric('ESAN'  ), [ qw( SAI    SEIS    ES     ESAM   ESOS    SONT    ) ]);
form_ok('EPESAN', demeric('EPESAN'), [ qw( EUSAI  EUSEIS  EPES   EPESAM EPESOS  EUSONT  ) ]);
form_ok('CTANEN', demeric('CTANEN'), [ qw( CTAI   CTES    CTET   CTANAM CTANUS  CTANONT ) ]);
form_ok('FAR',    demeric('FAR'   ), [ qw( FAEU   FAES    FAET   FASCOM FASCOUS FASCONT ) ]);
form_ok('IUSIR',  demeric('IUSIR' ), [ qw( IUSU   IUS     IUT    IUSUM  IUSUS   IUINT   ) ]);
form_ok('LIUBEC', demeric('LIUBEC'), [ qw( LIUO/LIUBAO LIUOS/LIUBEOS LIUS/LIUBES LIUBOM LIUBOUS LIUBONT ) ]);
form_ok('KETHEN', demeric('KETHEN'), [ qw( KETHUI KETHUS  KETHUT KETHEM KETHES  KENT    ) ]);
form_ok('CULLIR', demeric('CULLIR'), [ qw( CULLU  CULS    CULT   CULLUM CULLUS  CULLINT ) ]);
form_ok('OHIR',   demeric('OHIR'  ), [ qw( OHU    UIS     UIT    OHUM   OHUS    OHINT   ) ]);
form_ok('SCRIFEC', demeric('SCRIFEC'), [ qw( SCRIFAO SCRIS SCRIT SCRIFOM SCRIFOUS SCRIFONT ) ]);
form_ok('NEN',    demeric('NEN'   ), [ qw( NEI    NIS     NIT    NESEM  NESES   NENT    ) ]);
form_ok('KES',    demeric('KES'   ), [ qw( KEAI   KIES    KIET   KEHAM  KEHUS   KEHONT  ) ]);
form_ok('VOLIR',  demeric('VOLIR' ), [ qw( VULU   VULS    VULT   VOLUM  VOLUS   VOLINT  ) ]);
form_ok('FAUCIR', demeric('FAUCIR'), [ qw( FAU    FEUS    FEUT   FAUCUM FAUCUS  FAUCINT ) ]);
form_ok('FAILIR', demeric('FAILIR'), [ qw( FAILU  FELS    FELT   FAILUM FAILUS  FAILINT ) ]);

form_ok('CLAETER', demeric('CLAETER'), [ qw( CLAETHU CLAETEUS CLAETIT CLAETHUM CLAETHUS CLAETINT ) ]);
form_ok('CADIR', demeric('CADIR'), [ qw( CADHU CADEUS CADET CADHUM CADHUS CADHUNT ) ]);

# test general forms
form_ok('GGGEC', demeric('GGGEC'), [ qw( GGGAO GGGEOS GGGES GGGOM GGGOUS GGGONT ) ]);
form_ok('GGGAN', demeric('GGGAN'), [ qw( GGGAI GGGEIS GGGET GGGAM GGGUS  GGGONT ) ]);
form_ok('GGGEN', demeric('GGGEN'), [ qw( GGGAI GGGEIS GGGET GGGEM GGGES  GGGENT ) ]);
form_ok('GGGER', demeric('GGGER'), [ qw( GGGU  GGGEUS GGGIT GGGUM GGGUS  GGGINT ) ]);
form_ok('GGGIR', demeric('GGGIR'), [ qw( GGGU  GGGEUS GGGET GGGUM GGGUS  GGGUNT ) ]);

form_ok('ATER', demeric('ATER'), [ qw( ATHU  ATEUS ATIT ATHUM ATHUS  ATINT ) ]);
form_ok('ADER', demeric('ADER'), [ qw( ADHU  ADEUS ADIT ADHUM ADHUS  ADINT ) ]);
form_ok('ETIR', demeric('ETIR'), [ qw( ETHU  ETEUS ETET ETHUM ETHUS  ETHUNT ) ]);
form_ok('ADIR', demeric('ADIR'), [ qw( ADHU  ADEUS ADET ADHUM ADHUS  ADHUNT ) ]);
