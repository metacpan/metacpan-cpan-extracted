# vim:set filetype=perl sw=4 et:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 09_noun.t'

#########################

use Test::More tests => 367;
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

form_ok('eli', noun('eli'), [ qw( eli eli elia elio eliri elirî elirich ) ]);
form_ok('lônd', noun('lônd'), [ qw( lônd lônd lônda lôndo lôndi lôndî lôndich ) ]);
form_ok('âshta', noun('âshta'), [ qw( âshta âsht âshta âshto âshtâ âshtî âshtach ) ]);

form_ok('kal', noun('kal'), [ qw( kal kalu kalu kalo kalo kaloi kaloch ) ]);
form_ok('shkor', noun('shkor'), [ qw( shkor shkoru shkoru shkoro shkoru shkorî shkorich ) ]);
form_ok('nôshti', noun('nôshti'), [ qw( nôshti nôshti nôshti nôshtio nôkchu nôkchî nôkchich ) ]);
form_ok('manu', noun('manu'), [ qw( manu man manu mano mani manî manich ) ]);
form_ok('shpâ', noun('shpâ'), [ qw( shpâ shpâ shpâ shpach shpao shpaoi shpaoch ) ]);

form_ok('chir', noun('chir'), [ qw( chir chira chirê chirach chirâ chirêi chirech ) ]);
form_ok('nor', noun('nor'), [ qw( nor nore norê norech norê norêi norech ) ]);
form_ok('medhi', noun('medhi'), [ qw( medhi medhi medhiê medhich medhiê medhia medhiech ) ]);
form_ok('elorê', noun('elorê'), [ qw( elorê elore elorê elorech eloriê eloria eloriech ) ]);
form_ok('kabrâ', noun('kabrâ'), [ qw( kabrâ kabra kabrê kabrach kabrachâ kabracha kabrachech ) ]);

#is(noun('elorî')->[0], 'elorî',   's.nom. of elorî');
#is(noun('elorî')->[4], 'elorini', 'pl.nom. of elorî');

# Now with explicit gender
form_ok('eli', noun('eli', 'masc'), [ qw( eli eli elia elio eliri elirî elirich ) ]);
form_ok('lônd', noun('lônd', 'masc'), [ qw( lônd lônd lônda lôndo lôndi lôndî lôndich ) ]);
form_ok('âshta', noun('âshta', 'masc'), [ qw( âshta âsht âshta âshto âshtâ âshtî âshtach ) ]);

form_ok('kal', noun('kal', 'neut'), [ qw( kal kalu kalu kalo kalo kaloi kaloch ) ]);
form_ok('shkor', noun('shkor', 'neut'), [ qw( shkor shkoru shkoru shkoro shkoru shkorî shkorich ) ]);
form_ok('nôshti', noun('nôshti', 'neut'), [ qw( nôshti nôshti nôshti nôshtio nôkchu nôkchî nôkchich ) ]);
form_ok('manu', noun('manu', 'neut'), [ qw( manu man manu mano mani manî manich ) ]);
form_ok('shpâ', noun('shpâ', 'neut'), [ qw( shpâ shpâ shpâ shpach shpao shpaoi shpaoch ) ]);

form_ok('chir', noun('chir', 'fem'), [ qw( chir chira chirê chirach chirâ chirêi chirech ) ]);
form_ok('nor', noun('nor', 'fem'), [ qw( nor nore norê norech norê norêi norech ) ]);
form_ok('medhi', noun('medhi', 'fem'), [ qw( medhi medhi medhiê medhich medhiê medhia medhiech ) ]);
form_ok('elorê', noun('elorê', 'fem'), [ qw( elorê elore elorê elorech eloriê eloria eloriech ) ]);
form_ok('kabrâ', noun('kabrâ', 'fem'), [ qw( kabrâ kabra kabrê kabrach kabrachâ kabracha kabrachech ) ]);

#is(noun('elorî', 'masc')->[0], 'elorî',   's.nom. of elorî');
#is(noun('elorî', 'masc')->[4], 'elorini', 'pl.nom. of elorî');

# Now with explicit plural
form_ok('eli', noun('eli', undef, 'eliri'), [ qw( eli eli elia elio eliri elirî elirich ) ]);
form_ok('lônd', noun('lônd', undef, 'lôndi'), [ qw( lônd lônd lônda lôndo lôndi lôndî lôndich ) ]);
form_ok('âshta', noun('âshta', undef, 'âshtâ'), [ qw( âshta âsht âshta âshto âshtâ âshtî âshtach ) ]);

form_ok('kal', noun('kal', undef, 'kalo'), [ qw( kal kalu kalu kalo kalo kaloi kaloch ) ]);
form_ok('shkor', noun('shkor', undef, 'shkoru'), [ qw( shkor shkoru shkoru shkoro shkoru shkorî shkorich ) ]);
form_ok('nôshti', noun('nôshti', undef, 'nôkchu'), [ qw( nôshti nôshti nôshti nôshtio nôkchu nôkchî nôkchich ) ]);
form_ok('manu', noun('manu', undef, 'mani'), [ qw( manu man manu mano mani manî manich ) ]);
form_ok('shpâ', noun('shpâ', undef, 'shpao'), [ qw( shpâ shpâ shpâ shpach shpao shpaoi shpaoch ) ]);

form_ok('chir', noun('chir', undef, 'chirâ'), [ qw( chir chira chirê chirach chirâ chirêi chirech ) ]);
form_ok('nor', noun('nor', undef, 'norê'), [ qw( nor nore norê norech norê norêi norech ) ]);
form_ok('medhi', noun('medhi', undef, 'medhiê'), [ qw( medhi medhi medhiê medhich medhiê medhia medhiech ) ]);
form_ok('elorê', noun('elorê', undef, 'eloriê'), [ qw( elorê elore elorê elorech eloriê eloria eloriech ) ]);
form_ok('kabrâ', noun('kabrâ', undef, 'kabrachâ'), [ qw( kabrâ kabra kabrê kabrach kabrachâ kabracha kabrachech ) ]);

#is(noun('elorî', undef, 'elorini')->[0], 'elorî',   's.nom. of elorî');
#is(noun('elorî', undef, 'elorini')->[4], 'elorini', 'pl.nom. of elorî');

# Now with explicit gender and plural
form_ok('eli', noun('eli', 'masc', 'eliri'), [ qw( eli eli elia elio eliri elirî elirich ) ]);
form_ok('lônd', noun('lônd', 'masc', 'lôndi'), [ qw( lônd lônd lônda lôndo lôndi lôndî lôndich ) ]);
form_ok('âshta', noun('âshta', 'masc', 'âshtâ'), [ qw( âshta âsht âshta âshto âshtâ âshtî âshtach ) ]);

form_ok('kal', noun('kal', 'neut', 'kalo'), [ qw( kal kalu kalu kalo kalo kaloi kaloch ) ]);
form_ok('shkor', noun('shkor', 'neut', 'shkoru'), [ qw( shkor shkoru shkoru shkoro shkoru shkorî shkorich ) ]);
form_ok('nôshti', noun('nôshti', 'neut', 'nôkchu'), [ qw( nôshti nôshti nôshti nôshtio nôkchu nôkchî nôkchich ) ]);
form_ok('manu', noun('manu', 'neut', 'mani'), [ qw( manu man manu mano mani manî manich ) ]);
form_ok('shpâ', noun('shpâ', 'neut', 'shpao'), [ qw( shpâ shpâ shpâ shpach shpao shpaoi shpaoch ) ]);

form_ok('chir', noun('chir', 'fem', 'chirâ'), [ qw( chir chira chirê chirach chirâ chirêi chirech ) ]);
form_ok('nor', noun('nor', 'fem', 'norê'), [ qw( nor nore norê norech norê norêi norech ) ]);
form_ok('medhi', noun('medhi', 'fem', 'medhiê'), [ qw( medhi medhi medhiê medhich medhiê medhia medhiech ) ]);
form_ok('elorê', noun('elorê', 'fem', 'eloriê'), [ qw( elorê elore elorê elorech eloriê eloria eloriech ) ]);
form_ok('kabrâ', noun('kabrâ', 'fem', 'kabrachâ'), [ qw( kabrâ kabra kabrê kabrach kabrachâ kabracha kabrachech ) ]);

is(noun('elorî', 'masc', 'elorini')->[0], 'elorî',   's.nom. of elorî');
is(noun('elorî', 'masc', 'elorini')->[4], 'elorini', 'pl.nom. of elorî');
