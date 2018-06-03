use strict;
use warnings;

use Test::More 'no_plan';

use FLAT;
use FLAT::FA;
use FLAT::DFA;
use FLAT::NFA;
use FLAT::PFA;
use FLAT::Regex::WithExtraOps;

my ($PFA1, $PFA2, $DFA1, $DFA2);

# Evilness
## these used to fail; fixed in NFA->as_dfa() when initializing subset construction by finding start state via e-closure
ok($PFA1 = FLAT::Regex::WithExtraOps->new('a*')->as_pfa());
isa_ok($PFA1, 'FLAT::PFA');
ok($DFA1 = $PFA1->as_nfa()->as_min_dfa());
require Data::Dumper;
note Data::Dumper::Dumper($DFA1);
isa_ok($DFA1, 'FLAT::DFA');
isa_ok($DFA1, 'FLAT::FA');
can_ok($DFA1, q{equals});
ok($PFA1 = FLAT::Regex::WithExtraOps->new('a*+b')->as_pfa());
ok($DFA1 = $PFA1->as_nfa()->as_min_dfa());
isa_ok($DFA1, 'FLAT::DFA');
isa_ok($DFA1, 'FLAT::FA');
can_ok($DFA1, q{equals});
ok($PFA1 = FLAT::Regex::WithExtraOps->new('a*+b*')->as_pfa());
ok($DFA1 = $PFA1->as_nfa()->as_min_dfa());
isa_ok($DFA1, 'FLAT::DFA');
isa_ok($DFA1, 'FLAT::FA');
can_ok($DFA1, q{equals});
ok($PFA1 = FLAT::Regex::WithExtraOps->new('a*&b')->as_pfa());
ok($DFA1 = $PFA1->as_nfa()->as_min_dfa());
isa_ok($DFA1, 'FLAT::DFA');
isa_ok($DFA1, 'FLAT::FA');
can_ok($DFA1, q{equals});
ok($PFA1 = FLAT::Regex::WithExtraOps->new('a*&b*')->as_pfa());
ok($DFA1 = $PFA1->as_nfa()->as_min_dfa());
isa_ok($DFA1, 'FLAT::DFA');
isa_ok($DFA1, 'FLAT::FA');
can_ok($DFA1, q{equals});
ok($PFA1 = FLAT::Regex::WithExtraOps->new('a*&b*&c*')->as_pfa());
ok($DFA1 = $PFA1->as_nfa()->as_min_dfa());
isa_ok($DFA1, 'FLAT::DFA');
isa_ok($DFA1, 'FLAT::FA');
can_ok($DFA1, q{equals});

# w&w
ok($PFA1 = FLAT::Regex::WithExtraOps->new('abc&def')->as_pfa());
ok($PFA2 = FLAT::Regex::WithExtraOps->new('a(b(c&def)+d(ef&bc))+d(ef&abc)')->as_pfa());
ok($DFA1 = $PFA1->as_nfa()->as_min_dfa());
isa_ok($DFA1, 'FLAT::DFA');
isa_ok($DFA1, 'FLAT::FA');
can_ok($DFA1, q{equals});
ok($DFA2 = $PFA2->as_nfa()->as_min_dfa());
is(($DFA1->equals($DFA2)), 1);

# w&v* 
ok($PFA1 = FLAT::Regex::WithExtraOps->new('abc&(def)*')->as_pfa());
ok($PFA2 = FLAT::Regex::WithExtraOps->new('(def)*(a(bc&(def)*)+d((efd)*ef&(abc))+d((efd)*&(abc))ef)')->as_pfa());
ok($DFA1 = $PFA1->as_nfa()->as_min_dfa());
ok($DFA2 = $PFA2->as_nfa()->as_min_dfa());
isa_ok($DFA1, 'FLAT::DFA');
isa_ok($DFA1, 'FLAT::FA');
can_ok($DFA1, q{equals});
is(($DFA1->equals($DFA2)), 1);

# w*&v*
ok( $PFA1 = FLAT::Regex::WithExtraOps->new('(abc)*&(def)*')->as_pfa() );
ok( $PFA2 = FLAT::Regex::WithExtraOps->new('((abc+def)*( a((bca)*bc&(def)*)+ a((bca)*&(def)*)bc+ d((efd)*ef&(abc)*)+ d((efd)*&(abc)*)ef)*)*')->as_pfa() );
ok( $DFA1 = $PFA1->as_nfa()->as_min_dfa() );
ok( $DFA2 = $PFA2->as_nfa()->as_min_dfa() );
isa_ok($DFA1, 'FLAT::DFA');
isa_ok($DFA1, 'FLAT::FA');
can_ok($DFA1, q{equals});
is( ($DFA1->equals($DFA2)), 1);


SKIP: {
    skip q{Skipping long running tests. To run, set "FLAT_RUN_LONG_TESTS" to some truth value in your environement} unless $ENV{FLAT_RUN_LONG_TESTS};

    # the following take a long time
    # w*x&v*y
    ok( $PFA1 = FLAT::Regex::WithExtraOps->new('(abc)*dx&(efg)*hy')->as_pfa() );
    ok(
        $PFA2 = FLAT::Regex::WithExtraOps->new(
'(abc+efg)*( dx&(efg)*hy+ hy&(abc)*dx+ a(((bca)*bcdx)&((efg)*hy))+ a(((bca)*)&((efg)*hy))bcdx+ e(((fge)*fghy)&((abc)*dx))+ e(((fge)*)&((abc)*dx))fghy)'
        )->as_pfa()
    );
    ok( $DFA1 = $PFA1->as_nfa()->as_min_dfa() );
    ok( $DFA2 = $PFA2->as_nfa()->as_min_dfa() );
    isa_ok( $DFA1, 'FLAT::DFA' );
    isa_ok( $DFA1, 'FLAT::FA' );
    can_ok( $DFA1, q{equals} );
    is( ( $DFA1->equals($DFA2) ), 1 );

    ok( $PFA1 =
          FLAT::Regex::WithExtraOps->new('nop(abc)*hij&qrs(def)*klm')->as_pfa()
    );
    ok(
        $PFA2 = FLAT::Regex::WithExtraOps->new(
            'n(op(abc)*hij&qrs(def)*klm)+q(rs(def)*klm&nop(abc)*hij)')->as_pfa()
    );

    ok( $DFA1 = $PFA1->as_nfa()->as_min_dfa() );
    isa_ok( $DFA1, 'FLAT::DFA' );
    isa_ok( $DFA1, 'FLAT::FA' );
    can_ok( $DFA1, q{equals} );
    ok( $DFA2 = $PFA2->as_nfa()->as_min_dfa() );
    is( ( $DFA1->equals($DFA2) ), 1 );
}
