use v5.38;
use lib ( 'lib', '../lib' );
use Logic::Probabilistic::Syntax;

# Rolling two dice
prob_logic TwoDice {

    # Categorical choices: Fair six-sided dice
    pchoice die1 => [
        1 / 6 => 1,
        1 / 6 => 2,
        1 / 6 => 3,
        1 / 6 => 4,
        1 / 6 => 5,
        1 / 6 => 6,
    ];

    pchoice die2 => [
        1 / 6 => 1,
        1 / 6 => 2,
        1 / 6 => 3,
        1 / 6 => 4,
        1 / 6 => 5,
        1 / 6 => 6,
    ];

    # Relational rule calculating sum of two dice
    rule sum_dice($s) {
        fresh my ( $d1, $d2 );
        die1($d1);
        die2($d2);
        is_goal( $s, [ $d1, $d2 ], sub ( $a, $b ) { $a + $b } );
    }

    # Condition: Sum is an odd number
    rule odd_sum {
        fresh my $s;
        sum_dice($s);
        guard( [$s], sub ($v) { ( $v % 2 ) != 0 } );
    }
}

fresh my $total;

# if rolling two fair dice, what are the probabilities of getting every possible total?
query_dist TwoDice::sum_dice($total)->my $dist;
say $dist;
print "\n";

# We roll two dice. Someone tells us one of the dice shows 6. What are the probabilities of what number the other dice shows?
query_dist TwoDice::sum_dice($total),
	evidence => [ TwoDice::die1(6) ]->my $dist_die1_six;
say $dist_die1_six;
print "\n";

# We roll two dice. Someone tells us the total is an odd number. What are the probabilities of each sum?
query_dist TwoDice::sum_dice($total), 
	evidence => [TwoDice::odd_sum]->my $dist_odd;
say $dist_odd;
print "\n";


