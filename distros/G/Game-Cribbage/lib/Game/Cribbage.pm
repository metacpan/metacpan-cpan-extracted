package Game::Cribbage;

our $VERSION = "0.12";

use Rope;
use Rope::Autoload;
use Game::Cribbage::Board;

prototyped 'board' => undef, dealer => undef, crib_set => 0, starter_card => undef; 

sub start {
	my ($self, %params) = @_;

	$self->clear_screen;

	$self->print_header("Welcome to terminal Cribbage");

	$self->print_footer("Insert name: ");

	my $name = <STDIN>;

	chomp($name);

	my $board = Game::Cribbage::Board->new();

	$board->add_player(name => 'Bot');
	$board->add_player(name => $name);

	$board->start_game();

	$self->board = $board;

	$self->init_game();
}

sub init_game {
	my ($self) = @_;

	$self->clear_screen;

	$self->reset_cursor();

	$self->split_cards();

	$self->init_draw();
}

sub init_draw {
	my ($self, $switch) = @_;

	$self->crib_set = 0;
	$self->starter_card = undef;
	$self->dealer = !$self->dealer if $switch;

	my $winner;
	if ($self->board->score->player1->{current} > 120) {
		$winner = 'player1';
	} elsif ($self->board->score->player2->{current} > 120) {
		$winner = 'player2';
	}		
	return $self->winner($winner) if $winner;

	$self->draw_cards();

	$self->discard_cards();

	$self->starter();

	while (!$winner) {
		$self->clear_screen();	

		$self->print_header(q|It is your turn to play a card, type go if you're unable to play.|);

		my $ok = eval { $self->play_hand(); };

		unless ($@) {
			if ($self->board->score->player1->{current} > 120) {
				$winner = 'player1';
				next;
			} elsif ($self->board->score->player2->{current} > 120) {
				$winner = 'player2';
				next;
			}		


			my $hands = $self->board->get_hands;
			unless (grep { !$_->{used} } @{$hands->player2->cards}, @{$hands->player1->cards}) {
				eval {
					$self->end_hands();
				};
				if ($@) {
					while (1) {
						print $@;
					}
				}
				return $self->init_draw(1);
			}

			if ($self->board->no_player_can_play) {
				eval { $self->board->next_play(); };
				if ($@) {
					while (1) {
						print $@;
					}
				}
			}
		}
	}
	$self->winner($winner);
}

sub end_hands {
	my ($self) = @_;

	$self->board->end_play();
		
	my $hands = $self->board->get_hands;

	$self->board->end_hands();

	$self->crib_set = 0;

	$self->clear_screen();

	my $last = $self->board->last_round_hands();
	my $player1_score = $last->player1->score->total_score;
	my $player2_score = $last->player2->score->total_score;
	my $crib_player = $self->dealer ? $self->board->players->[-1]->name : 'Bot';
	my $crib_score = $last->{$self->dealer ? 'player2' : 'player1'}->crib_score->total_score;

	$self->print_header(sprintf "Bot scored: %s - %s scored: %s - %s crib scored: %s",
		$player1_score,
		$self->board->players->[-1]->name,
		$player2_score,
		$crib_player,
		$crib_score
	);

	$self->draw_scores();

	$self->render_player_cards($hands->player1->cards, 3, 20, 1);

	$self->render_player_cards($hands->{$hands->crib_player}->crib, 15, 20, 1);

	$self->render_player_cards($hands->player2->cards, 26, 20, 1);

	$self->print_footer(q|Press enter to continue|);

	<STDIN>
}

sub play_hand {
	my ($self) = @_;

	my $hands = $self->board->get_hands;
	
	if ($self->board->next_to_play->player eq 'player1') { 
		my $card = $self->board->best_run_play('player1');
		if ($card->go) {
			$self->board->cannot_play('player1');
			$self->draw_go(6, 2);
		} else {
			$self->board->play_card('player1', $card);
			if ($self->board->current_play_score == 31) {
				$self->board->next_play();
				return;
			}

			if ($self->board->score->player1->{current} > 120) {
				return;
			}
		}
	}

	if ($self->board->player_cannot_play('player2')) {
		if (!$self->board->player_cannot_play('player1')) {
			$self->board->set_next_to_play('player1');
		}
		return;
	}

	$_[0]->draw_scores();

	$self->render_opponent_cards(scalar grep { !$_->{used} } @{$hands->player1->cards});

	$self->render_run_play();

	$self->render_player_cards($hands->player2->cards, 26, 20);

	$self->print_footer(q|Pick a card: |);

	my $number = <STDIN>;

	chomp($number);

	if ($number =~ m/go/i) {
		my @can = $self->board->cannot_play('player2');
		if (scalar @can && ref $can[0]) {
			return;
		}
		$self->draw_go(30);
		return;
	}

	if ($number eq 'b') {
		my $card = $self->board->best_run_play('player2');
		if ($card->go) {
			$self->board->cannot_play('player2');
			$self->draw_go(6, 2);
		} else {
			$self->board->play_card('player2', $card);
			if ($self->board->current_play_score == 31) {
				$self->board->next_play();
			}
		}
		return;
	}
	
	if ($number !~ m/^\d+$/ || $number > scalar @{$hands->player2->cards}) {
		return;
	}

	my $card = $self->board->get_card('player2', $number - 1);
	$self->board->play_card('player2', $card);

	if ($self->board->current_play_score == 31) {
		$self->board->next_play();
	}

	return 1;
}

sub split_cards {
	my ($self) = @_;

	$self->print_header(q|Split cards lowest goes first|);

	$self->show_face_down_split(52);
	
	$self->print_footer(q|Pick a number: |);

	my $number = <STDIN>;
	
	if ($number !~ m/^\d+$/ || $number > 52) {
		$self->clear_screen();
		$self->split_cards();
		return;
	}

	my $low = $self->board->deck->get($number - 1);

	my $rand = int(rand(52));
	
	while ($number == $rand) {
		$rand = int(rand(52));
	}

	my $bot = $self->board->deck->get($rand - 1);

	$self->clear_screen();

	my $dealer = $low->value < $bot->value ? 1 : 0;

	$self->print_header(q|Low cards picked, | . ($dealer ? "you are the dealer" : "they are the dealer"));

	$self->render_card($bot, 2, 45);

	$self->render_card($low, 27, 45);

	$self->board->set_crib_player($dealer ? 'player2' : 'player1');

	$self->print_footer(q|Press enter to continue|);

	$self->dealer = $dealer;

	<STDIN>
}

sub draw_cards {
	my ($self) = @_;

	$self->board->draw_hands();
}

sub discard_cards {
	my ($self) = @_;
	
	$self->clear_screen();

	$self->print_header(q|Discard two cards to the crib, seperate the indexes with a space.|);

	my $hands = $self->board->get_hands;

	$self->render_opponent_cards(6);

	$self->render_player_cards($hands->player2->cards, 26, 5);

	$self->print_footer(q|Discard cards: |);

	my $cards_index  = <STDIN>;

	chomp($cards_index);

	my @cards = map {
		$self->board->get_card('player2', $_ - 1);
	} grep { $_ =~ m/^\d+$/ && $_ <= 6 } split " ", $cards_index;

	unless (scalar @cards == 2) {
		$self->discard_cards();
		return;
	}

	$self->board->crib_player_cards('player2', \@cards);

	my @bot = $self->board->identify_worst_cards('player1');

	$self->board->crib_player_cards('player1', $bot[0]);

	$self->crib_set = 1;
}

sub starter {
	my ($self) = @_;

	$self->clear_screen();

	my $count = scalar @{$self->board->deck->{deck}};
	if ($self->dealer) {
		my $card = $self->board->deck->get(int(rand(39)));	
		$self->starter_card = $card;
		$self->board->add_starter_card('player1', $card);
		return;
	}

	$self->print_header(q|Split deck for starter card.|);
	
	$self->show_face_down_split(40, 13); 

	$self->print_footer(q|Split deck: |);

	my $number = <STDIN>;
	
	chomp($number);
	
	if ($number !~ m/^\d+$/ || $number > 52) {
		$self->clear_screen();
		$self->starter();
		return;
	}

	my $card = $self->board->deck->get($number);
	$self->starter_card = $card;
	my $scored = $self->board->add_starter_card('player2', $card);
	return;
}

sub render_card {
	my ($self, $card, $row, $col) = @_;

	$self->set_cursor_vertical($row);
	$self->set_cursor_horizontal($col);
	my $color = $card->suit =~ m/H|D/ ? 91 : 90;
	
	my %suits = (
		H => '♥',
		D => '♦',
		C => '♣',
		S => '♠'
	);

	my @card = (	
		"┌─────────┐",
		sprintf("│%s. . . .│", $card->symbol =~ m/10/ ? $card->symbol : $card->symbol . " "),
		"│. . . . .│",
		"│. . . . .│",
		sprintf("│. . %s . .│", $suits{$card->suit}),
		"│. . . . .│",
		"│. . . . .│",
		sprintf("│. . . .%s│", $card->symbol =~ m/10/ ? $card->symbol : " " . $card->symbol),
		"└─────────┘"
	);

	for (@card) {
		$self->say($_, 1, 0, $color);
		$self->set_cursor_horizontal($col);
	}
}


sub render_opponent_cards {
	my ($self, $num) = @_;

	return unless $num;

	$self->set_cursor_vertical(2);
	$self->set_cursor_horizontal((100 - ($num * 4)) / 2);

	my $string = "┌──" x ($num - 1);
	$self->say($string);
	$self->say("┌─────────┐", 1, 1);
	$self->set_cursor_horizontal((100 - ($num * 4)) / 2);
	for (0..6) {
		$string = "│. " x ($num - 1);
		$self->say($string);
		$self->say("│. . . . .│", 1, 1);
		$self->set_cursor_horizontal((100 - ($num * 4)) / 2);
	}
	$string = "└──" x ($num - 1);	
	$self->say($string);
	$self->say("└─────────┘", 1, 1);
}

sub render_player_cards {
	my ($self, $cards, $top, $left, $all) = @_;
	my $i = 1;
	for (@{$cards}) {
		if (!$all && $_->{used}) {
			$i++;
			next;
		}
		$left += 11;
		$self->set_cursor_vertical($top);
		$self->set_cursor_horizontal($left + 5);
		$self->say($i++);
		$self->render_card($_, $top + 1, $left);
	}
}

sub render_run_play {
	my ($self) = @_;

	my $cards = $self->board->current_play->cards;

	return unless (scalar @{$cards});

	my $left = 25;
	for (@{$cards}) {
		$self->render_card($_->card, 15, $left);
		$left += 10;
	}
}


sub show_face_down_split {
	my ($self, $num, $vertical) = @_;

	$self->set_cursor_vertical($vertical || 10);

	my $width = ($num / 2) - 1;

	for my $it (0 .. 1) {
		my $string = "┌──" x $width;
		$self->say($string);
		$self->say("┌─────────┐", 1, 1);
		$string = "";
		for (1 .. $width) {
			my $v = $it ? 26 + $_ : $_;
			$string .= sprintf("│%s", (!$it && $_ < 10 ? "$v " : $v));
		}
		$self->say($string);
		$self->say(sprintf("│%s. . . .│", $it ? ($width + 1) * 2 : $width + 1), 1, 1);
		for (0..4) {
			$string = "│. " x $width;
			$self->say($string);
			$self->say("│. . . . .│", 1, 1);
		}
		$string = "│. " x $width;
		$self->say($string);
		$self->say(sprintf("│. . . .%s│", $it ? ($width + 1) * 2 : $width + 1), 1, 1);
		my $string = "└──" x $width;	
		$self->say($string);
		$self->say("└─────────┘", 1, 1);
	}
}

sub draw_background {
	for (0 .. 35) {
		print "\e[102;1m";
		print pack("A100", " ");
		print "\n";
		print "\e[0";
	}
	$_[0]->draw_dealer();
	#$_[0]->draw_scores();
	$_[0]->draw_crib();
	$_[0]->draw_starter();
	$_[0]->reset_cursor();
}

sub draw_starter {
	my ($self) = @_;

	return unless $self->starter_card;

	$self->render_card($self->starter_card, 15, 2);
}


sub draw_crib {
	my ($self) = shift;
	my $dealer = $self->dealer;
	return unless defined $dealer;
	return unless $self->crib_set;
	my @card = (	
		"┌─────────┐",
		"│. . . . .│",
		"│. . . . .│",
		"│. . . . .│",
		"│. . . . .│", 
		"│. . . . .│",
		"│. . . . .│",
		"│. . . . .│",
		"└─────────┘"
	);

	if ($dealer) {
		$self->set_cursor_vertical(27);
	} else {
		$self->set_cursor_vertical(3);
	}

	for (@card) {
		$self->set_cursor_horizontal(10);
		$self->say($_, 1, 0);
	}
}

sub draw_go {
	my ($self, $top, $left) = @_;	
	my $message = ' GO ';
	$self->set_cursor_vertical($top);
	$self->say($message, 0, 0, 31, 40);
}


sub draw_dealer {
	my ($self) = @_;	
	
	my $dealer = $self->dealer;

	return unless defined $dealer;
	my $message = ' Dealer ';
	if ($dealer) {
		$self->set_cursor_vertical(34);
		$self->say($message, 0, 0, 31, 40);
	} else {
		$self->set_cursor_vertical(3);
		$self->say($message, 0, 0, 31, 40);
	}
}

sub draw_scores {
	my ($self) = @_;
	my $message;
	return unless $self->board;
	if ($self->board && $self->board->current_play_score) {
		$message = pack("A2", $self->board->current_play_score);
		$self->set_cursor_vertical(14);
		$self->set_cursor_horizontal(49);
		$self->say($message, 0, 0, 31, 40);
	}
	$message = ' Score: ' . $self->board->score->player2->{current} . ' ';
	$self->set_cursor_vertical(34);
	$self->set_cursor_horizontal(100 - (length($message) + 1));
	$self->say($message, 0, 0, 31, 40);
	$message = ' Score: ' . $self->board->score->player1->{current} . ' ';
	$self->set_cursor_vertical(3);
	$self->set_cursor_horizontal(100 - (length($message) + 1));
	$self->say($message, 0, 0, 31, 40);
}

sub winner {
	print "\e[0m\e[2J\e[0;1H";
	for (0 .. 35) {
		print "\e[102;1m";
		print pack("A100", " ");
		print "\n";
		print "\e[0";
	}
	$_[0]->set_cursor_vertical(17);
	my $player = $_[0]->board->players->[1];
	$_[0]->say($_[1] eq 'player2' 
		? sprintf(q|Congratualations %s, you won the game!|, $player->name)
		: sprintf(q|Unlucky %s, you lost this time!|, $player->name)
	);
	<STDIN>
}


sub clear_screen {
	print "\e[0m\e[2J\e[0;1H";
	$_[0]->draw_background();
}

sub reset_cursor {
	print "\e[;2H";
}

sub set_cursor_vertical {
	print "\e[$_[1];2H";
}

sub set_cursor_horizontal {
	print "\e[$_[1]G";
}

sub say {
	my ($self, $msg, $nl, $indent, $color, $back) = @_;
	$color ||= 90;
	$back ||= 102;
	print "\e[$color;1;1m\e[$back;1m";
	print $msg;
	print "\n" if $nl;
	$self->set_cursor_horizontal(2) if $indent;
	print "\e[0";
	1;
}

sub print_header {
	my ($self, $message) = @_;
	$self->set_cursor_verical(0);
	$self->set_cursor_horizontal(0);
 	print "\e[40;1m";
	print pack("A100", " ");
	$self->set_cursor_horizontal(2);
	$self->say($message, 0, 0, 31, 40);
}

sub print_footer {
	my ($self, $message) = @_;
	$self->set_cursor_vertical(36);
	$self->set_cursor_horizontal(0);
 	print "\e[40;1m";
	print pack("A100", " ");
	$self->set_cursor_horizontal(2);
	$self->say($message, 0, 0, 31, 40);
	$self->set_cursor_horizontal(length($message) + 2);
}


1;

__END__

=head1 NAME

Game::Cribbage - Cribbage game engine

=head1 VERSION

Version 0.12

=cut

=head1 SYNOPSIS

	lnation$ cribbage

	...

	use Game::Cribbage;

	Game::Cribbage->new()->start();

	...
	
=for html <img style="width:500px" src="https://raw.githubusercontent.com/ThisUsedToBeAnEmail/Game-Cribbage/main/test.png" title="img-tag, local-dist" alt="Inlineimage" />

	...

	use Game::Cribbage::Board;

	my $engine = Game::Cribbage::Board->new();

	$engine->add_player(name => 'Robert');
	$engine->add_player(name => 'Joseph');

	$engine->start_game();

	# low card logic to then set the dealer/crib player
	$engine->set_crib_player('player1');
	
	# deal hands
	$engine->draw_hands();

	$engine->crib_player_cards('player1', $cards);
	$engine->crib_player_cards('player2', $cards);

	# split to get starter
	$engine->add_starter_card('player2', $card);

	$engine->play_card('player1', $card);
	$engine->play_card('player2', $card);
	
	...

	$engine->next_play();

	...

	$engine->end_hands();
	$engine->score;

=head1 DESCRIPTION

Cribbage is a card game, typically for two players, where the goal is to be the first to reach 121 points by forming counting combinations of cards and using a special pegging board to track scores. 

The L<Game::Cribbage> class is an implementation of cribbage using the terminal. The distribution itself is an game engine and should contain all the logic you need to build a version of Cribbage using any alternative interface.

=head1 PROPERTIES

The following properties are defined in L<Game::Cribbage>

=head2 board

Property to store the current L<Game::Cribbage::Board>

	$game->board;

=head2 dealer

Property to store a boolean of whether the current player is the dealer for the current round. If true they are.

	$game->dealer;

=head2 crib_set

Property to store a boolean of whether the current plays crib is set.

	$game->crib_set;

=head2 starter_card

Property to store the starter card for the current play.

	$game->starter_card;.


=head1 FUNCTIONS

The following functions are defined in L<Game::Cribbage>


	my $game = Game::Cribbage->new;

	$game->clear_screen;

        $game->print_header("Welcome to terminal Cribbage");

        $game->print_footer("Insert name: ");

        my $name = <STDIN>;

        chomp($name);

        my $board = Game::Cribbage::Board->new();

        $board->add_player(name => 'Bot');
        $board->add_player(name => $name);

        $board->start_game();
/split
        $game->board = $board;

	$game->clear_screen;

	$game->reset_cursor();
	
	$game->split_cards();

	$game->init_draw();


=head2 start

Start a new terminal cribbage game. This function setups the L<Game::Cribbage::Board> setting the players and starting the game. It will then call init_game.

	$game->start();


=head2 init_game

Initialise a new terminal game, clearing the welcome start screen, calling split_cards and then init_draw.

	$game->init_game();


=head2 init_draw

This is where the main terminal game loop happens. For each new round/draw this function is called recursively. Cards are drawn, discarded and the starter card is set. Hands are played until no cards are left, scores are calculated and we repeat..

	$game->init_draw();

=head2 end_hands

When all cards have been used in the current draw/round then this end_hands function should be called. It handles the ending of the round and will render to the terminal an overview of the round/draw including all cards and the relevant scores.

	$game->end_hands();

=head2 play_hand

Contains the logic needed to handle the play of the players hand, aka placing a card or calling go because you cannot play a card.

	$game->play_hand();. 


=head2 split_cards

Contains the logic needed to decide which player goes first as the dealer.

	$game->split_cards();

=head2 draw_cards

Contains the logic needed to draw player cards so they can then decide which two to discard.

	$game->draw_cards();

=head2 discard_cards

Contains the logic neeeded to discard two cards from the players and bots hands into the crib.

	$game->discard_cards();

=head2 starter

Contains the logic needed to select the starter card for the current draw.

	$game->starter();

=head2 render_card

Contians the logic needed to render a card to the terminal.

	$game->render_card($card, $row, $col);

=head2 render_opponent_cards

Contains the logic needed to render the opponents cards to the terminal. AKA face down at the top of the screen.

	$game->render_opponent_cards($num);

=head2 render_player_cards

Contains the logic needed to render the players cards to the terminal. AKA face up at the bottom of the screen.

	$game->render_player_cards($cards, $row, $col, $all);

=head2 render_run_play

Contains the logic needed to render the current plays run cards. AKA the cards that have been played for the current play in the middle of the screen.

	$game->render_run_play;


=head2 show_face_down_split

Utility function to render face down cards to the terminal.

	$game->show_face_down_split($num, $vertical);

=head2 draw_background

Utility function to draw the basic cribbage game, this function calls draw_dealer, draw_crib, draw_starter and reset_cursor. It will render the green background, dealer, crib and starter card to the terminal.

	$game->draw_background();

=head2 draw_starter

Utility function to draw the starter card to the terminal. If no starter card is set then nothing will be drawn.

	$game->draw_starter();

=head2 draw_crib

Utility function to draw the crib to the terminal, depending on who is the dealer.

	$game->draw_crib();

=head2 draw_go

Utitlity function to draw GO to the terminal.

	$game->draw_go();

=head2 draw_dealer

Utility function to draw the text "Dealer" to the terminal, this will be against the player who is currently the dealer.

	$game->draw_dealer();.

=head2 draw_scores

Utility function to draw the current scores to the terminal.

	$game->draw_scores();

=head2 winner

Utility function to draw the winners screen to the terminal at the end of the game.

	$game->winner();

=head2 clear_screen

Utility function to clear the terminal.

	$game->clear_screen();

=head2 reset_cursor

Utility function to reset the terminal cursor position.

	$game->reset_cursor();

=head2 set_cursor_vertical

Utiltiy function to set the vertical position of the terminal cursor.

	$game->set_cursor_vertical($y);

=head2 set_cursor_horizontal

Utility function to set the horizontal position of the terminal cursor.

	$game->set_cursor_horizontal($x);

=head2 say

Utility function to print text to the terminal.

	$game->say("Hello World", $new_line, $indent, $color, $background);

=head2 print_header

Utility function to print the header to the terminal

	$game->print_header("Print some header text");

=head2 print_footer

Utility function to print the footer to the terminal

	$game->print_footer("Print some footer text");

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-cribbage at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Cribbage>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::Cribbage

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game-Cribbage>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Game-Cribbage>

=item * Search CPAN

L<https://metacpan.org/release/Game-Cribbage>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
