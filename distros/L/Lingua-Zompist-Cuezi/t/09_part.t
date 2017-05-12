# vim:set filetype=perl sw=4 et encoding=utf-8 fileencoding=utf-8 keymap=cuezi:
#########################

use Test::More tests => 2;
use Carp;

BEGIN { use_ok 'Lingua::Zompist::Cuezi', 'part'; }

ok(1);

__END__

sub form_ok {
    croak 'usage: form_ok($verb, $is, $should)' unless @_ >= 3;
    my($verb, $is, $should) = @_;

    is($is->[0], $should->[0], "present participle of $verb");
    is($is->[1], $should->[1], "past participle of $verb");
    is($is->[2], $should->[2], "gerund of $verb");
}

form_ok('LIUBEC', part('LIUBEC'), [ qw( LIUBILES LIUBEL LIUBIM  ) ]);
form_ok('LAUDAN', part('LAUDAN'), [ qw( LAUDEC   LAUDUL LAUDAUM ) ]);
form_ok('LEILEN', part('LEILEN'), [ qw( LEILEC   LEILUL LEILAUM ) ]);
form_ok('CLAGER', part('CLAGER'), [ qw( CLAGEC   CLAGEL CLAGIM  ) ]);
form_ok('NURIR',  part('NURIR' ), [ qw( NURIC    NURUL  NURAUM  ) ]);

# test general forms
form_ok('GGGEC',  part('GGGEC' ), [ qw( GGGILES  GGGEL  GGGIM   ) ]);
form_ok('GGGAN',  part('GGGAN' ), [ qw( GGGEC    GGGUL  GGGAUM  ) ]);
form_ok('GGGEN',  part('GGGEN' ), [ qw( GGGEC    GGGUL  GGGAUM  ) ]);
form_ok('GGGER',  part('GGGER' ), [ qw( GGGEC    GGGEL  GGGIM   ) ]);
form_ok('GGGIR',  part('GGGIR' ), [ qw( GGGIC    GGGUL  GGGAUM  ) ]);
