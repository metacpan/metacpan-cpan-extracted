# vim:set filetype=perl encoding=utf-8 fileencoding=utf-8 sw=4 et keymap=cuezi:
#########################

use Test::More tests => 1;
use Carp;

ok(1);

__END__

BEGIN { use_ok 'Lingua::Zompist::Cuezi', 'bubefel'; }

sub form_ok {
    croak 'usage: form_ok($verb, $is, $should)' unless @_ >= 3;
    my($verb, $is, $should) = @_;

    is($is->[0], undef,        "I.sg. of $verb");
    is($is->[1], $should->[0], "II.sg. of $verb");
    is($is->[2], $should->[1], "III.sg. of $verb");
    is($is->[3], undef,        "I.pl. of $verb");
    is($is->[4], $should->[2], "II.pl. of $verb");
    is($is->[5], $should->[3], "III.pl. of $verb");
}

form_ok('LIUBEC', bubefel('LIUBEC'), [ qw( LIUBE LIUBUAS LIUBEL LIUBUANT ) ]);
form_ok('LAUDAN', bubefel('LAUDAN'), [ qw( LAUDI LAUDUAT LAUDIL LAUDUANT ) ]);
form_ok('LEILEN', bubefel('LEILEN'), [ qw( LEILI LEILUAT LEILIL LEILUANT ) ]);
form_ok('CLAGER', bubefel('CLAGER'), [ qw( CLAGU CLAGAS  CLAGUL CLAGANT  ) ]);
form_ok('NURIR',  bubefel('NURIR' ), [ qw( NURU  NURUAT  NURUL  NURUANT  ) ]);

# test general forms
form_ok('GGGEC',  bubefel('GGGEC' ), [ qw( GGGE  GGGUAS  GGGEL  GGGUANT  ) ]);
form_ok('GGGAN',  bubefel('GGGAN' ), [ qw( GGGI  GGGUAT  GGGIL  GGGUANT  ) ]);
form_ok('GGGEN',  bubefel('GGGEN' ), [ qw( GGGI  GGGUAT  GGGIL  GGGUANT  ) ]);
form_ok('GGGER',  bubefel('GGGER' ), [ qw( GGGU  GGGAS   GGGUL  GGGANT   ) ]);
form_ok('GGGIR',  bubefel('GGGIR' ), [ qw( GGGU  GGGUAT  GGGUL  GGGUANT  ) ]);
