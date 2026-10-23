use v5.38;
use lib ( 'lib', '../lib' );
use Logic::Probabilistic::Syntax;

=pod

Example from: https://dtai.cs.kuleuven.be/problog/tutorial/basic/01_coins.html

% Probabilistic facts:
0.5::heads1.
0.6::heads2.

% Rules:
twoHeads :- heads1, heads2.
someHeads :- heads1.
someHeads :- heads2.

% Queries:
query(heads1).
query(heads2).
query(twoHeads).
query(someHeads).

% Evidence:
evidence(twoHeads, false).

=cut

prob_logic CoinToss {

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
}

# query(heads1).
query_prob CoinToss::heads1->my $coin1;
say "P(heads1): ", $coin1->probability;

# query(heads2).
query_prob CoinToss::heads2->my $coin2;
say "P(heads2): ", $coin2->probability;

# query(twoHeads).
query_prob CoinToss::twoHeads->my $twoCoins;
say "P(twoHeads): ", $twoCoins->probability;

# query(someHeads).
query_prob CoinToss::someHeads->my $someCoins;
say "P(someHeads): ", $someCoins->probability;

# evidence(twoHeads, false).

query_prob CoinToss::heads1, 
	evidence => { twoHeads => 0 }->my $heads1_given_not_two;
say "P(heads1) (given !twoHeads): ", $heads1_given_not_two->probability;

query_prob CoinToss::heads2, 
	evidence => { twoHeads => 0 }->my $heads2_given_not_two;
say "P(heads2) (given !twoHeads): ", $heads2_given_not_two->probability;

query_prob CoinToss::twoHeads, 
	evidence => { twoHeads => 0 }->my $twoHeads_given_not_two;
say "P(twoHeads) (given !twoHeads): ", $twoHeads_given_not_two->probability;

query_prob CoinToss::someHeads, 
	evidence => { twoHeads => 0 }->my $someHeads_given_not_two;
say "P(someHeads) (given !twoHeads): ", $someHeads_given_not_two->probability;

