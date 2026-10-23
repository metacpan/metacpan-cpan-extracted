use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use Test::More;

use Logic::Probabilistic::Syntax;

prob_logic CoinModel {
    pfacts {
        0.5 => heads1;
        0.6 => heads2;
    }

    rule twoHeads {
        heads1;
        heads2;
    }

    rule someHeads {
        heads1;
    }
    rule someHeads {
        heads2;
    }

    rule not_twoHeads {
        not { twoHeads; };
    }
}

subtest 'Prior probabilities without evidence' => sub {
    my ( $h1, $h2, $th, $sh );
    query_prob CoinModel::heads1->$h1;
    query_prob CoinModel::heads2->$h2;
    query_prob CoinModel::twoHeads->$th;
    query_prob CoinModel::someHeads->$sh;

    ok( abs( $h1->probability - 0.5 ) < 1e-6, 'P(heads1) == 0.5' );
    ok( abs( $h2->probability - 0.6 ) < 1e-6, 'P(heads2) == 0.6' );
    ok( abs( $th->probability - 0.3 ) < 1e-6, 'P(twoHeads) == 0.3' );
    ok( abs( $sh->probability - 0.8 ) < 1e-6, 'P(someHeads) == 0.8' );
};

subtest 'Negative evidence via rule-level negation: not_twoHeads' => sub {
    my ( $h1, $h2, $sh, $th );
    query_prob CoinModel::heads1,    given => [CoinModel::not_twoHeads]->$h1;
    query_prob CoinModel::heads2,    given => [CoinModel::not_twoHeads]->$h2;
    query_prob CoinModel::someHeads, given => [CoinModel::not_twoHeads]->$sh;
    query_prob CoinModel::twoHeads,  given => [CoinModel::not_twoHeads]->$th;

    # Theoretical: P(~twoHeads) = 1 - 0.3 = 0.7
    # P(heads1 | ~twoHeads) = 0.5 * 0.4 / 0.7 = 2/7 ~= 0.285714
    # P(heads2 | ~twoHeads) = 0.5 * 0.6 / 0.7 = 3/7 ~= 0.428571
    # P(someHeads | ~twoHeads) = 0.5 / 0.7 = 5/7 ~= 0.714286
    # P(twoHeads | ~twoHeads) = 0.0
    ok(
        abs( $h1->probability - ( 2 / 7 ) ) < 1e-6,
        'P(heads1 | not_twoHeads) == 2/7'
    );
    ok(
        abs( $h2->probability - ( 3 / 7 ) ) < 1e-6,
        'P(heads2 | not_twoHeads) == 3/7'
    );
    ok(
        abs( $sh->probability - ( 5 / 7 ) ) < 1e-6,
        'P(someHeads | not_twoHeads) == 5/7'
    );
    ok(
        abs( $th->probability - 0.0 ) < 1e-6,
        'P(twoHeads | not_twoHeads) == 0'
    );
};

subtest 'Negative evidence via not_goal(...) exported helper' => sub {
    my ( $h1, $h2, $sh, $th );
    query_prob CoinModel::heads1,
      given => [ not_goal(CoinModel::twoHeads) ]->$h1;
    query_prob CoinModel::heads2,
      given => [ not_goal(CoinModel::twoHeads) ]->$h2;
    query_prob CoinModel::someHeads,
      given => [ not_goal(CoinModel::twoHeads) ]->$sh;
    query_prob CoinModel::twoHeads,
      given => [ not_goal(CoinModel::twoHeads) ]->$th;

    ok(
        abs( $h1->probability - ( 2 / 7 ) ) < 1e-6,
        'P(heads1 | not_goal(twoHeads)) == 2/7'
    );
    ok(
        abs( $h2->probability - ( 3 / 7 ) ) < 1e-6,
        'P(heads2 | not_goal(twoHeads)) == 3/7'
    );
    ok(
        abs( $sh->probability - ( 5 / 7 ) ) < 1e-6,
        'P(someHeads | not_goal(twoHeads)) == 5/7'
    );
    ok(
        abs( $th->probability - 0.0 ) < 1e-6,
        'P(twoHeads | not_goal(twoHeads)) == 0'
    );
};

subtest 'Negative evidence via hashref' => sub {
    my ( $h1, $h2, $sh );
    query_prob CoinModel::heads1, given => { twoHeads              => 0 }->$h1;
    query_prob CoinModel::heads2, given => { 'CoinModel::twoHeads' => 0 }->$h2;
    query_prob CoinModel::someHeads, evidence => { twoHeads => 'false' }->$sh;

    ok(
        abs( $h1->probability - ( 2 / 7 ) ) < 1e-6,
        'P(heads1 | {twoHeads=>0}) == 2/7'
    );
    ok(
        abs( $h2->probability - ( 3 / 7 ) ) < 1e-6,
        'P(heads2 | {CoinModel::twoHeads=>0}) == 3/7'
    );
    ok(
        abs( $sh->probability - ( 5 / 7 ) ) < 1e-6,
        'P(someHeads | {twoHeads=>"false"}) == 5/7'
    );
};

subtest 'Negative evidence via pair in arrayref' => sub {
    my ( $h1, $h2 );
    query_prob CoinModel::heads1,
      evidence => [ [ CoinModel::twoHeads => 0 ] ]->$h1;
    query_prob CoinModel::heads2,
      evidence => [ [ CoinModel::twoHeads, 0 ] ]->$h2;

    ok(
        abs( $h1->probability - ( 2 / 7 ) ) < 1e-6,
        'P(heads1 | [twoHeads=>0]) == 2/7'
    );
    ok(
        abs( $h2->probability - ( 3 / 7 ) ) < 1e-6,
        'P(heads2 | [twoHeads, 0]) == 3/7'
    );
};

subtest 'Negative evidence in rejection sampling' => sub {
    my $h1;
    query_prob CoinModel::heads1,
      method  => 'rejection',
      samples => 3000,
      given   => [ not_goal(CoinModel::twoHeads) ]->$h1;

    ok( abs( $h1->probability - ( 2 / 7 ) ) < 0.05,
        'Rejection estimate near 2/7' );
};

done_testing();
