package Game::Cribbage;

our $VERSION = "0.05";

use Rope;
use Rope::Autoload;
use Game::Cribbage::Board;

property inverse => (
	initable => 1,
	value => 1
);

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

	$self->draw_cards();

	$self->discard_cards();

	$self->starter();

	my $winner;
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
				$self->board->end_hands();
				return $self->init_draw(1);
			}

			if (scalar keys %{$self->board->rounds->current_round->current_hands->cannot_play} == 2) {
				eval { $self->board->next_play(); };
			}
		}
	}
	$self->winner($winner);
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

	if (exists $self->board->rounds->current_round->current_hands->cannot_play->{player2}) {
		return;
	}

	$_[0]->draw_scores();

	$self->render_opponent_cards(scalar grep { !$_->{used} } @{$hands->player1->cards});

	$self->render_run_play();

	$self->render_player_cards($hands->player2->cards, 20);

	$self->print_footer(q|Pick a card: |);

	my $number = <STDIN>;

	chomp($number);

	if ($number eq 'go') {
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

	$self->set_crib_player($dealer ? 'player2' : 'player1');

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

	$self->render_player_cards($hands->player2->cards, 5);

	$self->print_footer(q|Discard cards: |);

	my $cards_index  = <STDIN>;

	chomp($cards_index);

	my @cards = map { 
		$self->board->get_card('player2', $_ - 1);
	} split " ", $cards_index;


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
		$self->add_starter_card('player1', $card);
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
	my $scored = $self->add_starter_card('player2', $card);
	return;
}


=pod
		┌─────────┐
		│.2. . . .│
		│. . . . .│
		│. . . . .│
		│. . ♥ . .│
		│. . . . .│
		│. . . . .│
		│. . . .2.│
		└─────────┘	
=cut

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
	my ($self, $cards, $left) = @_;
	my $i = 1;
	for (@{$cards}) {
		if ($_->{used}) {
			$i++;
			next;
		}
		$left += 11;
		$self->set_cursor_vertical(26);
		$self->set_cursor_horizontal($left + 5);
		$self->say($i++);
		$self->render_card($_, 27, $left);
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

Version 0.05

=cut

=head1 SYNOPSIS

	lnation:High lnation$ cribbage

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
