use v5.38;
use lib ( 'lib', '../lib' );
use Logic::Probabilistic::Syntax;

=pod

Example from: https://dtai.cs.kuleuven.be/problog/tutorial/basic/01_coins.html
"First-Order & Probabilistic clauses"

% Background information:
coin(c1).
coin(c2).
coin(c3).
coin(c4).

% Probabilistic clause:
0.6::heads(C) :- coin(C).

% Rules:
someHeads :- heads(_).

% Queries:
query(someHeads).

=cut

prob_logic FirstOrderCoins {

    facts {
        coin('c1');
        coin('c2');
        coin('c3');
        coin('c4');
    }

    # Probabilistic clause: 0.6::heads(C) :- coin(C).
    prule 0.6 => heads($c) {
        coin($c);
    };

    rule someHeads {
        fresh my $c;
        heads($c);
    }
}

query_prob FirstOrderCoins::someHeads->my $result;
say "P(someHeads): ", $result->probability;

# Query distribution of heads across individual coins
query_dist FirstOrderCoins::heads(fresh my $coin)->my $dist;
say "\nDistribution of individual coin tosses:";
say $dist;

