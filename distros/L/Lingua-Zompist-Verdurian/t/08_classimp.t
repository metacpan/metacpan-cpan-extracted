# vim:set filetype=perl:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 67;
use Carp;

use Lingua::Zompist::Verdurian 'classimp';

sub form_ok {
    croak 'usage: form_ok($verb, $is, $should)' unless @_ >= 3;
    my($verb, $is, $should) = @_;

    is($is->[0], undef, "I.sg. of $verb");
    is($is->[1], $should->[0], "II.sg. of $verb");
    is($is->[2], undef, "III.sg. of $verb");
    is($is->[3], undef, "I.pl. of $verb");
    is($is->[4], $should->[1], "II.pl. of $verb");
    is($is->[5], undef, "III.pl. of $verb");
}

form_ok('lelen', classimp('lelen'), [ qw( leli lelil ) ]);
form_ok('badhir', classimp('badhir'), [ qw( badhu badhul ) ]);
form_ok('elirec', classimp('elirec'), [ qw( elire elirel ) ]);

form_ok('esan', classimp('esan'), [ qw( esi esil ) ]);

# test the general replacements
form_ok('xxxan', classimp('xxxan'), [ qw( xxxi xxxil ) ]);
form_ok('xxxen', classimp('xxxen'), [ qw( xxxi xxxil ) ]);
form_ok('xxxir', classimp('xxxir'), [ qw( xxxu xxxul ) ]);
form_ok('xxxer', classimp('xxxer'), [ qw( xxxu xxxul ) ]);
form_ok('xxxec', classimp('xxxec'), [ qw( xxxe xxxel ) ]);

form_ok('dan', classimp('dan'), [ qw( di dil ) ]);
is(classimp('kies'), undef, 'Imperative of "kies" is undef');

# I think 'fassec' should conjugate like this:
form_ok('fassec', classimp('fassec'), [ qw( fasse fassel ) ]);
