# vim:set filetype=perl encoding=utf-8 fileencoding=utf-8 sw=4 et keymap=cuezi:
#########################

use Test::More tests => 1;
use Carp;

ok(1);

__END__

BEGIN { use_ok 'Lingua::Zompist::Cuezi', 'scrifel'; }

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

form_ok('LIUBEC', scrifel('LIUBEC'), [ qw( LIUBI  LIUBIUS LIUBU  LIUBUM  LIUBUS  LIUBIUNT ) ]);
form_ok('LAUDAN', scrifel('LAUDAN'), [ qw( LAUDIO LAUDIOS LAUDAE LAUDUOM LAUDUOS LAUDIONT ) ]);
form_ok('LEILEN', scrifel('LEILEN'), [ qw( LEILIO LEILIOS LEILAE LEILUOM LEILUES LEILIONT ) ]);
form_ok('CLAGER', scrifel('CLAGER'), [ qw( CLAGIE CLAGIES CLAGE  CLAGEM  CLAGES  CLAGIENT ) ]);
form_ok('NURIR',  scrifel('NURIR' ), [ qw( NURIE  NURIES  NURAE  NUREM   NURES   NURIENT  ) ]);

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
