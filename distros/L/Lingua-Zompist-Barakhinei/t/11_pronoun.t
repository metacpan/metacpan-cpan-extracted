# vim:set filetype=perl sw=4 et:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 11_pronoun.t'

#########################

use Test::More tests => 56;
use Carp;

BEGIN { use_ok 'Lingua::Zompist::Barakhinei', 'noun' }

sub form_ok ($$$) {
    # croak 'usage: form_ok($noun, $is, $should)' unless @_ >= 3;
    my($noun, $is, $should) = @_;

    is($is->[0], $should->[0], "nom.sg. of $noun");
    is($is->[1], $should->[1], "acc.sg. of $noun");
    is($is->[2], $should->[2], "dat.sg. of $noun");
    is($is->[3], $should->[3], "gen.sg. of $noun");
    is($is->[4], $should->[4], "nom.pl. of $noun");
    is($is->[5], $should->[5], "acc./dat.pl. of $noun");
    is($is->[6], $should->[6], "gen.pl. of $noun");
}

sub sg_form_ok {
    # croak 'usage: form_ok($noun, $is, $should)' unless @_ >= 3;
    my($noun, $is, $should) = @_;

    is($is->[0], $should->[0], "nom. of $noun");
    is($is->[1], $should->[1], "acc. of $noun");
    is($is->[2], $should->[2], "dat. of $noun");
    is($is->[3], $should->[3], "gen. of $noun");
}


# Personal pronouns

form_ok('sû',  noun('sû' ), [ qw( sû  sêth sû  (eri)  ta   tâ (tandê) ) ]);
form_ok('lê',  noun('lê' ), [ qw( lê  êk   lê  (leri) mukh mî (mundê) ) ]);
form_ok('ât',  noun('ât' ), [ qw( ât  âtô  âta  âti   kâ   kâ (kandê) ) ]);
form_ok('tot', noun('tot'), [ qw( tot tô   tota toti  kâ   kâ (kandê) ) ]);
form_ok('zê',  noun('zê' ), [ '', qw( zêth zeu zei ), '', qw( zaa zai ) ]);
sg_form_ok('ta',   noun('ta'  ), [ qw( ta   tâ   tao (tandê) ) ]);
sg_form_ok('mukh', noun('mukh'), [ qw( mukh mî   mî  (mundê) ) ]);
sg_form_ok('kâ',   noun('kâ'  ), [ qw( kâ   kâ   kâ  (kandê) ) ]);
sg_form_ok('kêt',  noun('kêt' ), [ qw( kêt  kêtô kêta kêti   ) ]);
sg_form_ok('za',   noun('za'  ), [ '', qw( zaa zau zai ) ]);
