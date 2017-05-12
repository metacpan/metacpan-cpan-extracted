# vim:set filetype=perl:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 67;
use Carp;

use Lingua::Zompist::Verdurian 'befel';

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

form_ok('lelen', befel('lelen'), [ qw( lelenai lelenei lelene lelenam leleno lelenu ) ]);
form_ok('badhir', befel('badhir'), [ qw( badhiru badhireu badhire badhirum badhiro badhirü ) ]);
form_ok('elirec', befel('elirec'), [ qw( elirecao elireceo elirece elirecom elireco elirecu ) ]);

form_ok('esan', befel('esan'), [ qw( esanai esanei esane esanam esano esanu ) ]);

# test the general replacements
form_ok('xxxan', befel('xxxan'), [ qw( xxxanai xxxanei xxxane xxxanam xxxano xxxanu ) ]);
form_ok('xxxen', befel('xxxen'), [ qw( xxxenai xxxenei xxxene xxxenam xxxeno xxxenu ) ]);
form_ok('xxxir', befel('xxxir'), [ qw( xxxiru xxxireu xxxire xxxirum xxxiro xxxirü ) ]);
form_ok('xxxer', befel('xxxer'), [ qw( xxxeru xxxereu xxxere xxxerum xxxero xxxerü ) ]);
form_ok('xxxec', befel('xxxec'), [ qw( xxxecao xxxeceo xxxece xxxecom xxxeco xxxecu ) ]);

form_ok('dan', befel('dan'), [ qw( danai danei dane danam dano danu ) ]);
is(befel('kies'), undef, 'Imperative of "kies" is undef');

# I think 'fassec' should conjugate like this:
form_ok('fassec', befel('fassec'), [ qw( fassecao fasseceo fassece fassecom fasseco fassecu ) ]);
