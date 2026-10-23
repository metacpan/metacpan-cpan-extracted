use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use Test::More;

use Logic::Probabilistic::Syntax;

# 1. Simple Alarm Network
prob_logic AlarmNet {
    pfacts {
        0.7 => burglary;
        0.2 => earthquake;
    }

    prule 0.9 => alarm {
        burglary;
        earthquake;
      }

      prule 0.8 => alarm {
        burglary;
        not { earthquake; }
      }

      prule 0.1 => alarm {
        not { burglary; } earthquake;
      }
  }

  subtest 'Alarm network conditioned on alarm' => sub {
    my $b_res;
    query_prob AlarmNet::burglary, evidence => { alarm => 1 }->$b_res;
    ok( abs( $b_res->probability - 0.989655 ) < 1e-5,
        'P(burglary | alarm) == 0.989655' );

    my $e_res;
    query_prob AlarmNet::earthquake, evidence => { alarm => 1 }->$e_res;
    ok(
        abs( $e_res->probability - 0.227586 ) < 1e-5,
        'P(earthquake | alarm) == 0.227586'
    );
  };

# 2. AlarmCalls Network with first-order prule and probabilistic conditions
prob_logic AlarmCallsNet {
    facts {
        person('John');
        person('Mary');
    }

    pfacts {
        0.7 => burglary;
        0.2 => earthquake;
    }

    prule 0.9 => alarm {
        burglary;
        earthquake;
      }

      prule 0.8 => alarm {
        burglary;
        not { earthquake; }
      }

      prule 0.1 => alarm {
        not { burglary; } earthquake;
      }

      prule 0.8 => calls($x) {
        alarm;
        person($x);
    }

    prule 0.1 => calls($x) {
        not { alarm; } person($x);
    }
  }

  subtest 'AlarmCalls auto-grounding' => sub {
    my @pfacts = $AlarmCallsNet::PROGRAM->all_pfacts;
    is( scalar(@pfacts), 9, '9 pfacts grounded in AlarmCallsNet' );
  };

subtest 'AlarmCalls conditioned on calls(John) and calls(Mary)' => sub {
    my $expected_b = 0.981939;
    my $expected_e = 0.226851;

    # Format 1: Nested pair list [ [ G1 => 1, G2 => 1 ] ]
    my $b1;
    query_prob AlarmCallsNet::burglary,
      evidence => [
        [
            AlarmCallsNet::calls('John') => 1,
            AlarmCallsNet::calls('Mary') => 1
        ]
      ]->$b1;
    ok(
        abs( $b1->probability - $expected_b ) < 1e-5,
        'P(burglary | calls) with nested pair list'
    );

    # Format 2: Flat pair list [ G1 => 1, G2 => 1 ]
    my $b2;
    query_prob AlarmCallsNet::burglary,
      evidence => [
        AlarmCallsNet::calls('John') => 1,
        AlarmCallsNet::calls('Mary') => 1
      ]->$b2;
    ok(
        abs( $b2->probability - $expected_b ) < 1e-5,
        'P(burglary | calls) with flat pair list'
    );

    # Format 3: Array of separate pair arrays [ [ G1 => 1 ], [ G2 => 1 ] ]
    my $b3;
    query_prob AlarmCallsNet::burglary,
      evidence => [
        [ AlarmCallsNet::calls('John') => 1 ],
        [ AlarmCallsNet::calls('Mary') => 1 ]
      ]->$b3;
    ok(
        abs( $b3->probability - $expected_b ) < 1e-5,
        'P(burglary | calls) with list of pair arrays'
    );

    # Format 4: List of goals [ G1, G2 ]
    my $b4;
    query_prob AlarmCallsNet::burglary,
      evidence =>
      [ AlarmCallsNet::calls('John'), AlarmCallsNet::calls('Mary') ]->$b4;
    ok(
        abs( $b4->probability - $expected_b ) < 1e-5,
        'P(burglary | calls) with list of positive goals'
    );

    # Earthquake query
    my $eq;
    query_prob AlarmCallsNet::earthquake,
      evidence =>
      [ AlarmCallsNet::calls('John'), AlarmCallsNet::calls('Mary') ]->$eq;
    ok(
        abs( $eq->probability - $expected_e ) < 1e-5,
        'P(earthquake | calls) == 0.226851'
    );
};

done_testing();
