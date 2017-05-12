# vim:set filetype=perl sw=4 et encoding=utf-8 fileencoding=utf-8 keymap=cuezi:
#########################

use Test::More no_plan => ; # tests => 216;
use Carp;

BEGIN { use_ok 'Lingua::Zompist::Cuezi', 'noun', 'adj'; }

sub form_ok {
    croak 'usage: form_ok($noun, $is, $should)' unless @_ >= 3;
    my($noun, $is, $should) = @_;

    is($is->[0], $should->[0], "nom.sg. of $noun");
    is($is->[1], $should->[1], "gen.sg. of $noun");
    is($is->[2], $should->[2], "acc.sg. of $noun");
    is($is->[3], $should->[3], "dat.sg. of $noun");
    is($is->[4], $should->[4], "abl.sg. of $noun");
    is($is->[5], $should->[5], "ins.sg. of $noun");
    is($is->[6], $should->[6], "nom.pl. of $noun");
    is($is->[7], $should->[7], "gen.pl. of $noun");
    is($is->[8], $should->[8], "acc.pl. of $noun");
    is($is->[9], $should->[9], "dat.pl. of $noun");
    is($is->[10], $should->[10], "abl.pl. of $noun");
    is($is->[11], $should->[11], "ins.pl. of $noun");
}

sub sg_form_ok {
    croak 'usage: form_ok($noun, $is, $should)' unless @_ >= 3;
    my($noun, $is, $should) = @_;

    is($is->[0], $should->[0], "nom. of $noun");
    is($is->[1], $should->[1], "gen. of $noun");
    is($is->[2], $should->[2], "acc. of $noun");
    is($is->[3], $should->[3], "dat. of $noun");
    is($is->[4], $should->[4], "abl. of $noun");
    is($is->[5], $should->[5], "ins. of $noun");
}


# Personal pronouns

sg_form_ok('sēo', noun('sēo'), [ qw( sēo soex  etu  sēnu  sētu  sēco  ) ]);
sg_form_ok('sēi', noun('sēi'), [ qw( sēi soē   etu  sēnu  sēdi  sēlu  ) ]);
sg_form_ok('led', noun('led'), [ qw( led loex  ēr   linu  letu  leco  ) ]);
sg_form_ok('lei', noun('lei'), [ qw( lei loē   ēr   linu  ledi  lelu  ) ]);
sg_form_ok('tāu', noun('tāu'), [ qw( tāu tāuex tāua tāunu tāutu tāuco ) ]);
sg_form_ok('tāi', noun('tāi'), [ qw( tāi tāyē  tāya tāinu tāidi tāilu ) ]);


# Relative and interrogative pronouns

