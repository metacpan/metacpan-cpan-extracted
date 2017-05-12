##########################################################
# Have 2 AI players play a set of games of Hanabi
# using some very basic strategy.  Keep track of
# average score.
##########################################################

use strict;
use warnings;

use Games::Hanabi;
use Data::Dumper;
use Time::HiRes;

my @colors = qw(R G B Y W);
my @numbers = qw(1 2 3 4 5);

my $start_time = [Time::HiRes::gettimeofday()];

my $debug = 0;
my $trials = 100;
my $total_score = 0;
my $best = 0;
my $worst = 25;
my @scores;
for my $i (1..$trials) {
	my $score = play_game();
	if( $score < $worst ){ $worst = $score; }
	if( $score > $best ){ $best = $score; }
	$total_score += $score;
	$scores[$score]++;
}
print "Average score over $trials trials: " . ($total_score/$trials) . "\n";
print "Best: $best\nWorst: $worst\n";
#print Dumper \@scores;

my $diff = Time::HiRes::tv_interval($start_time);

print "\n\n$diff\n";

sub play_game {
	no strict 'refs';
	#my $game = Games::Hanabi->new( players => 2 );
	my $game = Games::Hanabi->new( players => 2, debug => $debug );

	# Play a game!
	TURN:
	while( my $moves = $game->get_valid_moves() ) {
		my $state = $game->get_game_state();
		
		$game->print_game_state() if $debug; 
		print "========================================\n"  if $debug;
		my $wait = <> if $debug;
		
		# Play our lower known safe card
		my ($card, $confidence) = play_lowest($game, $state);
		if( $confidence ) {
			$game->take_action({ action => 'play', index => $card  });
			next TURN;
		}
		
		# Discard junk if we have it
		($card, $confidence) = discard_junk($game, $state);
		if( $confidence ) {
			$game->take_action({ action => 'discard', index => $card  });
			next TURN;
		}
		
		# Give a hint to our opponents if they can play a card
		if( $game->{hints} > 0 ) {
			($card, $confidence) = give_play_hint($game, $state);
			if( $confidence ) {
				$game->take_action({ action => 'hint', hint => $card, player => 1 - $game->{turn}  });
				next TURN;
			}
		}
		
		# Discard at random among our unknown cards
		($card, $confidence) = discard_mystery_card($game, $state);
		if( $confidence ) {
			$game->take_action({ action => 'discard', index => $card  });
			next TURN;
		}
		
	}
	return $game->{score};
	$game->print_game_state() if $debug;
}

sub discard_mystery_card {
	my($game, $state) = @_;
	my $highest_num = 999;
	my $highest_card;
	for my $i ( 0 .. @{ $state->{hands}[ $state->{turn} ]} - 1 ) {
		my $card = $state->{hands}[ $state->{turn} ][$i];
		my $score = $card->{known_information}{score};
		if( $score < $highest_num) {
			$highest_num = $score;
			$highest_card = $i;
		}
	}
	#print "discarding $highest_card with score of $highest_num\n";
	return ($highest_card, 10);
}

sub give_play_hint {
	my($game, $state) = @_;
	my $card_to_play = -1;
	my $lowest_number = 6;
	my @hand = @{$state->{hands}[ 1 - $state->{turn} ]};
	for my $i ( 0 .. (scalar @hand - 1) ) {
		my $card = $hand[$i];
		#print "checking " . Dumper $card;
		if( $game->is_valid_play($card) ) {
			#print "It's valid!\n";
			if( $card->{number} < $lowest_number ) {
				#print "lowest...\n";
				$lowest_number = $card->{number};
				$card_to_play = $i;
			}
		}
	}
	#print "No cards to play\n";
	return if $lowest_number == 6;
	
	# Are we giving a color or number hints?
	#print "card is $card_to_play (color is $hand[$card_to_play]->{color})\n";
	#print Dumper $hand[$card_to_play];
	if( $hand[$card_to_play]{known_information}{number}{ $hand[$card_to_play]->{number} } ) {
		# Number is know, give a color hint
		return ( $hand[$card_to_play]->{color}, 10 );
	}
	else {
		return ( $hand[$card_to_play]->{number}, 10 );
	}
}

sub discard_junk {
	my($game, $state) = @_;
	# Otherwise discard junk
	for my $i ( 0 .. @{ $state->{hands}[ $state->{turn} ]} - 1 ) {
		my $card = $state->{hands}[ $state->{turn} ][$i];
		if( $game->is_card_known($card) && $game->is_junk($card, 1) ) {
			return ($i, 10);
		}
	}
	return;
}

# Play a card if we can .. the lowest number allowed
sub play_lowest {
	my($game, $state) = @_;
	my $card_to_play = -1;
	my $lowest_number = 6;
	#print Dumper $state->{hands}[ $state->{turn} ];
	for my $i ( 0 .. @{ $state->{hands}[ $state->{turn} ]} - 1 ) {
		my $card = $state->{hands}[ $state->{turn} ][$i];	
		
		if( $game->is_valid_known_play($card) ) {
			if( $card->{number} < $lowest_number ) {
				$lowest_number = $card->{number};
				$card_to_play = $i;
			}
		}
	}
	if( $lowest_number < 6 ) {
		return ($card_to_play, 10);
	}
	return;
}