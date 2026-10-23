use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use Test::More;

use Logic::Probabilistic::Syntax;

# 1. First-Order Coin Toss Tutorial Model
prob_logic FirstOrderCoins {
    facts {
        coin('c1');
        coin('c2');
        coin('c3');
        coin('c4');
    }

    # 0.6::heads(C) :- coin(C).
    prule 0.6 => heads($c) {
        coin($c);
    };

    rule someHeads {
        fresh my $c;
        heads($c);
    }
}

subtest 'First-Order coin toss with prule' => sub {
    my $sh;
    query_prob FirstOrderCoins::someHeads->$sh;

    # Theoretical: 1 - (1 - 0.6)^4 = 1 - 0.4^4 = 1 - 0.0256 = 0.9744
    ok( abs( $sh->probability - 0.9744 ) < 1e-6, 'P(someHeads) == 0.9744' );

    my $h1;
    query_prob FirstOrderCoins::heads('c1')->$h1;
    ok( abs( $h1->probability - 0.6 ) < 1e-6, 'P(heads(c1)) == 0.6' );
};

# 2. Multi-arity prule with non-unification constraint
prob_logic InfluencesModel {
    facts {
        person('Alice');
        person('Bob');
        person('Clara');
    }

    # 0.2::influences(X, Y) :- person(X), person(Y), X \= Y.
    prule 0.2 => influences( $x, $y ) {
        person($x);
        person($y);
        $x \= $y;
    };
}

subtest 'Multi-argument prule' => sub {
    is( scalar( $InfluencesModel::PROGRAM->all_pfacts ),
        6, '6 directed pairs generated for 3 people' );

    my $inf;
    query_prob InfluencesModel::influences( 'Alice', 'Bob' )->$inf;
    ok(
        abs( $inf->probability - 0.2 ) < 1e-6,
        'P(influences(Alice, Bob)) == 0.2'
    );
};

# 3. Propositional / 0-arity prule
prob_logic PropositionalPrule {
    fact flag;

    prule 0.75 => alarm {
        flag;
    };
}

subtest 'Propositional prule' => sub {
    my $res;
    query_prob PropositionalPrule::alarm->$res;
    ok( abs( $res->probability - 0.75 ) < 1e-6, 'P(alarm) == 0.75' );
};

# 4. Late fact declaration / dynamic grounding
prob_logic LateFactsModel {
    prule 0.5 => outcome($x) {
        item($x);
    };

    facts {
        item('a');
        item('b');
    }
}

subtest 'Late fact declaration / auto-grounding on query' => sub {
    my $res;
    query_prob LateFactsModel::outcome('a')->$res;
    ok( abs( $res->probability - 0.5 ) < 1e-6, 'P(outcome(a)) == 0.5' );
    is( scalar( $LateFactsModel::PROGRAM->all_pfacts ),
        2, '2 pfacts grounded on query' );
};

done_testing();
