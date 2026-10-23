use v5.38;
use experimental 'signatures';
use Test::More;

use Logic::Probabilistic::Syntax;

prob_logic CoinModel {
    pfact 0.70 => heads;
    pfact 0.50 => bonus;

    rule win {
        heads;
    }

    rule jackpot {
        heads;
        bonus;
    }
}

subtest 'Basic prob_logic syntax and query_prob' => sub {
    my $res_win;
    query_prob CoinModel::win->$res_win;
    is( $res_win->method, 'exact', 'default method is exact' );
    ok( abs( $res_win->probability - 0.70 ) < 1e-6, 'P(win) == 0.70' );

    my $res_jp;
    query_prob CoinModel::jackpot->$res_jp;
    ok( abs( $res_jp->probability - 0.35 ) < 1e-6, 'P(jackpot) == 0.35' );
};

subtest 'Accessing program instance via $PROGRAM' => sub {
    ok( defined $CoinModel::PROGRAM, '$CoinModel::PROGRAM is defined' );
    isa_ok( $CoinModel::PROGRAM, 'Logic::Probabilistic::Program' );
    isa_ok( $CoinModel::PROGRAM->relational_program,
        'Logic::Relational::Program' );

    # Direct query via object method
    my $res = $CoinModel::PROGRAM->query('heads');
    ok(
        abs( $res->probability - 0.70 ) < 1e-6,
        'query via $CoinModel::PROGRAM'
    );

    # Dynamic mutation via $PROGRAM
    $CoinModel::PROGRAM->update_pfact( 0.90, 'heads' );
    my $res_mutated = $CoinModel::PROGRAM->query('heads');
    ok(
        abs( $res_mutated->probability - 0.90 ) < 1e-6,
        'dynamic update via $CoinModel::PROGRAM'
    );

    # Revert
    $CoinModel::PROGRAM->update_pfact( 0.70, 'heads' );
};

prob_logic WeatherModel {
    pchoice weather => [
        0.60 => 'sunny',
        0.30 => 'cloudy',
        0.10 => 'rainy',
    ];

    rule nice_day {
        weather('sunny');
    }

    rule take_umbrella {
        weather('rainy');
    }
}

subtest 'Categorical choice syntax' => sub {
    my $res_sunny;
    query_prob WeatherModel::nice_day->$res_sunny;
    ok( abs( $res_sunny->probability - 0.60 ) < 1e-6, 'P(nice_day) == 0.60' );

    my $res_rain;
    query_prob WeatherModel::take_umbrella->$res_rain;
    ok( abs( $res_rain->probability - 0.10 ) < 1e-6,
        'P(take_umbrella) == 0.10' );
};

prob_logic AlarmModel {
    pfact 0.01 => burglary;
    pfact 0.02 => earthquake;

    pfact 0.95 => cause_burglary;
    pfact 0.20 => cause_earthquake;

    rule alarm {
        burglary;
        cause_burglary;
    } rule alarm {
        earthquake;
        cause_earthquake;
    }
}

subtest 'Conditioning syntax with query_prob' => sub {

    # Exact conditional query
    my $res_exact;
    query_prob AlarmModel::burglary, given => [AlarmModel::alarm]->$res_exact;
    cmp_ok( $res_exact->probability, '>', 0.01,
        'P(burglary | alarm) > prior 0.01' );

    # Monte Carlo rejection conditional query
    my $res_mc;
    query_prob AlarmModel::burglary,
      given   => [AlarmModel::alarm],
      method  => 'rejection',
      samples => 5000,
      seed    => 123->$res_mc;

    is( $res_mc->method, 'rejection', 'method is rejection' );
    cmp_ok( $res_mc->probability, '>', 0.01,
        'MC P(burglary | alarm) > prior 0.01' );

    # MCMC conditional query
    my $res_mcmc;
    query_prob AlarmModel::burglary,
      given   => [AlarmModel::alarm],
      method  => 'mcmc',
      samples => 3000,
      seed    => 456->$res_mcmc;

    is( $res_mcmc->method, 'mcmc', 'method is mcmc' );
    cmp_ok( $res_mcmc->probability, '>', 0.01,
        'MCMC P(burglary | alarm) > prior 0.01' );
};

prob_logic GuardGeneratorModel {
    pfact 0.80 => noisy_detector;

 # Guard checking if number is even, combined with between generator from StdLib
    rule even_detected($x) {
        between( 1, 4, $x );
        guard( [$x], sub ($v) { return ( $v % 2 ) == 0; } );
        noisy_detector;
    }
}

subtest 'Guards and Generators in prob_logic' => sub {
    my $res_even;
    query_prob GuardGeneratorModel::even_detected(2)->$res_even;
    ok( abs( $res_even->probability - 0.80 ) < 1e-6,
        'P(even_detected(2)) == 0.80' );

    my $res_odd;
    query_prob GuardGeneratorModel::even_detected(3)->$res_odd;
    is( $res_odd->probability, 0.0, 'P(even_detected(3)) == 0.0' );

    my $res_out;
    query_prob GuardGeneratorModel::even_detected(9)->$res_out;
    is( $res_out->probability, 0.0, 'P(even_detected(9)) == 0.0' );
};

prob_logic DiceSyntaxModel {
    pchoice roll => [ [ 0.25, 1 ], [ 0.25, 2 ], [ 0.50, 3 ], ];

    rule outcome($val) {
        roll($val);
    }
}

subtest 'query_dist keyword syntax' => sub {
    fresh my $out_val;
    my $dist;
    query_dist DiceSyntaxModel::outcome($out_val)->$dist;
    isa_ok( $dist, 'Logic::Probabilistic::Distribution' );
    is( $dist->probability(1), 0.25, 'P(1) = 0.25' );
    is( $dist->probability(2), 0.25, 'P(2) = 0.25' );
    is( $dist->probability(3), 0.50, 'P(3) = 0.50' );
    ok( abs( $dist->mean - 2.25 ) < 1e-6, 'mean = 2.25' );
    is( scalar( $dist->mode ), 3, 'mode = 3' );
};

prob_logic GroupedPFactsModel {
    pfacts {
        # Propositional events
        0.01 => burglary;
        0.02 => earthquake;

        # Parameterized relations
        0.90 => link( 'a', 'b' );
        0.85 => link( 'b', 'c' );

        # Fraction probabilities
        1 / 6 => die_face(1);
    }

    rule path( $x, $y ) {
        link( $x, $y );
    }
    rule path( $x, $z ) {
        fresh my $y;
        link( $x, $y );
        path( $y, $z );
    }
}

subtest 'Grouped pfacts block syntax' => sub {
    is( scalar( $GroupedPFactsModel::PROGRAM->all_pfacts ),
        5, '5 pfacts registered from block' );

    my $res_b;
    query_prob GroupedPFactsModel::burglary->$res_b;
    ok( abs( $res_b->probability - 0.01 ) < 1e-6, 'P(burglary) == 0.01' );

    my $res_eq;
    query_prob GroupedPFactsModel::earthquake->$res_eq;
    ok( abs( $res_eq->probability - 0.02 ) < 1e-6, 'P(earthquake) == 0.02' );

    my $res_die;
    query_prob GroupedPFactsModel::die_face(1)->$res_die;
    ok( abs( $res_die->probability - ( 1 / 6 ) ) < 1e-6,
        'P(die_face(1)) == 1/6' );

    my $res_path;
    query_prob GroupedPFactsModel::path( 'a', 'c' )->$res_path;
    ok( abs( $res_path->probability - ( 0.90 * 0.85 ) ) < 1e-6,
        'P(path(a, c)) == 0.765' );
};

prob_logic GroupedFactsModel {
    facts {
        # Propositional fact
        alarm_enabled;

        # Parameterized relations
        person('Alice');
        person('Bob');
        friend( 'Alice', 'Bob' );
        friend( 'Bob',   'Clara' );
    }

    pfact 0.80 => ping('Alice');

    rule reachable( $x, $y ) {
        friend( $x, $y );
    }
    rule reachable( $x, $z ) {
        fresh my $y;
        friend( $x, $y );
        reachable( $y, $z );
    }
}

subtest 'Grouped facts block syntax' => sub {
    my $preds = $GroupedFactsModel::PROGRAM->relational_program->{predicates};
    ok(
        exists $preds->{'alarm_enabled/0'},
        'alarm_enabled/0 predicate defined'
    );
    ok( exists $preds->{'person/1'}, 'person/1 predicate defined' );
    ok( exists $preds->{'friend/2'}, 'friend/2 predicate defined' );

    my $res;
    query_prob GroupedFactsModel::reachable( 'Alice', 'Clara' )->$res;
    is( $res->probability, 1.0,
        'P(reachable(Alice, Clara)) == 1.0 (deterministic facts)' );
};

prob_logic CyclicSmokingModel {
    table 'friends/2';

    facts {
        friend( 'Alice', 'Bob' );
        friend( 'Bob',   'Clara' );
        friend( 'Clara', 'Alice' );
    }

    pfacts {
        0.3 => stress('Alice');
        0.3 => stress('Bob');
        0.2 => influences( 'Alice', 'Bob' );
        0.2 => influences( 'Bob',   'Alice' );
    }

    rule friends( $x, $y ) {
        either {
            friend( $x, $y );
          }
          or {
            friend( $y, $x );
          }
    }

    rule smokes($x) {
        stress($x);
    }

    rule smokes($x) {
        fresh my $y;
        friends( $x, $y );
        influences( $y, $x );
        smokes($y);
    }
}

subtest 'Cyclic recursive probabilistic model and tabling' => sub {
    ok(
        $CyclicSmokingModel::PROGRAM->is_tabled('friends/2'),
        'table directive registered on probabilistic program'
    );

    my $res;
    query_prob CyclicSmokingModel::smokes('Alice')->$res;

# P(Alice smokes) = P(stress(Alice) OR (stress(Bob) AND influences(Bob, Alice)))
# = 0.3 + (1 - 0.3) * (0.3 * 0.2) = 0.3 + 0.7 * 0.06 = 0.342
    ok(
        abs( $res->probability - 0.342 ) < 1e-6,
        'Cyclic smokes(Alice) terminates and computes exact probability 0.342'
    );
};

done_testing();

