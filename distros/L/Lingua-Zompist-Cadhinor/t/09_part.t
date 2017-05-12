# vim:set filetype=perl sw=4 et:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 31;
use Carp;

BEGIN { use_ok 'Lingua::Zompist::Cadhinor', 'part'; }

sub form_ok {
    croak 'usage: form_ok($verb, $is, $should)' unless @_ >= 3;
    my($verb, $is, $should) = @_;

    is($is->[0], $should->[0], "present participle of $verb");
    is($is->[1], $should->[1], "past participle of $verb");
    is($is->[2], $should->[2], "gerund of $verb");
}

form_ok('DUMEC',  part('DUMEC' ), [ qw( DUMILES DUMEL  DUMIM   ) ]);
form_ok('KEKAN',  part('KEKAN' ), [ qw( KEKEC   KEKUL  KEKAUM  ) ]);
form_ok('NOMEN',  part('NOMEN' ), [ qw( NOMEC   NOMUL  NOMAUM  ) ]);
form_ok('CLAGER', part('CLAGER'), [ qw( CLAGEC  CLAGEL CLAGIM  ) ]);
form_ok('PARIR',  part('PARIR' ), [ qw( PARIC   PARUL  PARAUM  ) ]);

# test general forms
form_ok('GGGEC',  part('GGGEC' ), [ qw( GGGILES  GGGEL  GGGIM   ) ]);
form_ok('GGGAN',  part('GGGAN' ), [ qw( GGGEC    GGGUL  GGGAUM  ) ]);
form_ok('GGGEN',  part('GGGEN' ), [ qw( GGGEC    GGGUL  GGGAUM  ) ]);
form_ok('GGGER',  part('GGGER' ), [ qw( GGGEC    GGGEL  GGGIM   ) ]);
form_ok('GGGIR',  part('GGGIR' ), [ qw( GGGIC    GGGUL  GGGAUM  ) ]);
