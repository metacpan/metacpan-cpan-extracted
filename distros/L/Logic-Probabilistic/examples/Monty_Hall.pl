use v5.38;
use lib ( 'lib', '../lib' );
use Logic::Probabilistic::Syntax;

# The Monty Hall 3-Door Problem
# A car is hidden behind one of three doors with equal probability (1/3).
# The contestant initially selects Door 1.
# The host (Monty), who knows where the car is, opens a different door
# revealing a goat. The contestant can either stay with Door 1 or switch.
prob_logic MontyHall {

    # 1. Car placement behind door 1, 2, or 3
    pchoice prize => [
        ( 1 / 3 ) => 1,
        ( 1 / 3 ) => 2,
        ( 1 / 3 ) => 3,
    ];

    # 2. Contestant initially picks Door 1
    fact picked(1);

    # Available doors
    fact door(1);
    fact door(2);
    fact door(3);

	# 3. Monty's choice:
	# If the prize is behind Door 1 (contestant picked right), Monty flips a 50/50 coin between Door 2 and Door 3.
    pchoice monty_picks_if_prize_1 => [
        0.5 => 2,
        0.5 => 3,
    ];

    # If the prize is behind 2, Monty must open 3.
    rule monty_opens(3) {
        prize(2);
    }

    # If the prize is behind 3, Monty must open 2.
    rule monty_opens(2) {
        prize(3);
    }

	# If the prize is behind 1, Monty opens whichever door was picked by the 50/50 choice.
    rule monty_opens($d) {
        prize(1);
        monty_picks_if_prize_1($d);
    }

    # 4. Strategy: Stay vs Switch
    rule win_stay {
        fresh my $p;
        picked($p);
        prize($p);
    }

    # The switched door is the door that was neither picked nor opened by Monty
    rule switch_door($s) {
        door($s);
        not { picked($s); };
        not { monty_opens($s); };
    }

    rule win_switch {
        fresh my $s;
        switch_door($s);
        prize($s);
    }
}

say "=== The Monty Hall 3-Door Problem ===";
say "Setup: 3 doors. Contestant initially chooses Door 1.";
say "Monty opens another door revealing a goat.\n";

# 1. Probability of winning by staying with initial choice
query_prob MontyHall::win_stay->my $p_stay;
say "1. P(win by staying):                  "
  . sprintf( "%.4f", $p_stay->probability );

# 2. Probability of winning by switching doors
query_prob MontyHall::win_switch->my $p_switch;
say "2. P(win by switching):                "
  . sprintf( "%.4f", $p_switch->probability );

# 3. Conditional reasoning: Suppose Monty opens Door 3
query_prob MontyHall::prize(2),
  given => [ MontyHall::monty_opens(3) ]->my $p_cond_2;
query_prob MontyHall::prize(1),
  given => [ MontyHall::monty_opens(3) ]->my $p_cond_1;
say "\n3. Given Monty opens Door 3:";
say "   P(prize is behind Door 2 | Monty opened 3): "
  . sprintf( "%.4f", $p_cond_2->probability );
say "   P(prize is behind Door 1 | Monty opened 3): "
  . sprintf( "%.4f", $p_cond_1->probability );

# 4. Monte Carlo verification (10,000 trials)
query_prob MontyHall::win_switch,
  method  => 'rejection',
  samples => 10_000,
  seed    => 42->my $p_mc;
say "\n4. Monte Carlo Simulation (10,000 trials):";
say "   " . $p_mc->to_string;
