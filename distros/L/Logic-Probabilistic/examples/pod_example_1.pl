use v5.38;
use lib ( 'lib', '../lib' );
use Logic::Probabilistic::Syntax;

prob_logic AlarmNet {
    pfacts {
        0.7 => burglary;
        0.2 => earthquake;
    }

    prule 0.9 => alarm { burglary; earthquake; }
    prule 0.8 => alarm { burglary; not { earthquake; } }
    prule 0.1 => alarm { not { burglary; } earthquake; }
}

# Condition on observing alarm
query_prob AlarmNet::burglary, evidence => { alarm => 1 } -> my $b_given_alarm;
say "P(burglary | alarm):   " . $b_given_alarm->probability;   # ~0.9897

query_prob AlarmNet::earthquake, evidence => { alarm => 1 } -> my $e_given_alarm;
say "P(earthquake | alarm): " . $e_given_alarm->probability; # ~0.2276


