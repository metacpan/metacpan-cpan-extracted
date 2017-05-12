# vim:set filetype=perl:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 109;
use Carp;

BEGIN { use_ok 'Lingua::Zompist::Cadhinor', 'scrifel'; }

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

form_ok('DUMEC',  scrifel('DUMEC' ), [ qw( DUMI   DUMIUS  DUMU   DUMUM   DUMUS   DUMIUNT  ) ]);
form_ok('KEKAN',  scrifel('KEKAN' ), [ qw( KEKIO  KEKIOS  KEKAE  KEKUOM  KEKUOS  KEKIONT  ) ]);
form_ok('NOMEN',  scrifel('NOMEN' ), [ qw( NOMIO  NOMIOS  NOMAE  NOMUOM  NOMUES  NOMIONT  ) ]);
form_ok('CLAGER', scrifel('CLAGER'), [ qw( CLAGIE CLAGIES CLAGE  CLAGEM  CLAGES  CLAGIENT ) ]);
form_ok('PARIR',  scrifel('PARIR' ), [ qw( PARIE  PARIES  PARAE  PAREM   PARES   PARIENT  ) ]);

form_ok('ESAN',   scrifel('ESAN'  ), [ qw( FUIO   FUIOS   FUAE   FUOM    FUOS    FUNT     ) ]);
form_ok('EPESAN', scrifel('EPESAN'), [ qw( EUSIO  EUSIOS  EPAE   EUSUOM  EUSUOS  EUSIONT  ) ]);
form_ok('KETHEN', scrifel('KETHEN'), [ qw( KIO/KETHIO KETHIOS KIAE KETHUOM KETHUES KETHIONT ) ]);
form_ok('NEN',    scrifel('NEN'   ), [ qw( NIO    NIOS    NAE    NESUOM  NESUES  NIONT    ) ]);

form_ok('KREDEC', scrifel('KREDEC'), [ qw( KREDI  KREDIUS KREDHU KREDHUM KREDHUS KREDIUNT ) ]);
form_ok('SUTEC',  scrifel('SUTEC' ), [ qw( SUTI   SUTIUS  SUTHU  SUTHUM  SUTHUS  SUTIUNT  ) ]);

# test general forms
form_ok('GGGEC', scrifel('GGGEC'), [ qw( GGGI  GGGIUS GGGU  GGGUM  GGGUS  GGGIUNT ) ]);
form_ok('GGGAN', scrifel('GGGAN'), [ qw( GGGIO GGGIOS GGGAE GGGUOM GGGUOS GGGIONT ) ]);
form_ok('GGGEN', scrifel('GGGEN'), [ qw( GGGIO GGGIOS GGGAE GGGUOM GGGUES GGGIONT ) ]);
form_ok('GGGER', scrifel('GGGER'), [ qw( GGGIE GGGIES GGGE  GGGEM  GGGES  GGGIENT ) ]);
form_ok('GGGIR', scrifel('GGGIR'), [ qw( GGGIE GGGIES GGGAE GGGEM  GGGES  GGGIENT ) ]);

form_ok('ADEC', scrifel('ADEC'), [ qw( ADI  ADIUS ADHU ADHUM ADHUS ADIUNT ) ]);
form_ok('ATEC', scrifel('ATEC'), [ qw( ATI  ATIUS ATHU ATHUM ATHUS ATIUNT ) ]);
