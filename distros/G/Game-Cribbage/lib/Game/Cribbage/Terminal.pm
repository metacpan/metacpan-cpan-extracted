package Game::Cribbage::Terminal;

use strict;
use warnings;

our $VERSION = "0.17";

use Object::Proto::Sugar -types;
use Game::Cribbage::Board;
use Getopt::Long ();

our %SEQUENCE = (
	'A' => 'up', 'B' => 'down', 'C' => 'right', 'D' => 'left',
	'H' => 'home', 'F' => 'end',
	'1~' => 'home', '4~' => 'end', '5~' => 'page_up', '6~' => 'page_down',
	'7~' => 'home', '8~' => 'end',
);

our %CONTROL = (
	"\r" => 'enter', "\n" => 'enter', "\t" => 'tab',
	"\x7f" => 'backspace', "\x08" => 'backspace',
	"\x03" => 'interrupt', "\x04" => 'eof',
);

has board => (
	is => 'rw',
	isa => Object
);

has in => (
	is => 'rw',
	default => sub { \*STDIN }
);

has out => (
	is => 'rw',
	default => sub { \*STDOUT }
);

has raw => (
	is => 'rw',
	isa => Any,
	default => 0
);

has keysource => (
	is => 'rw',
	isa => Any
);

has pending => (
	is => 'rw',
	isa => ArrayRef,
	default => sub { [] }
);

has _picking => (
	is => 'rw',
	isa => Any,
	init_arg => 'picking'
);

has _colour => (
	is => 'rw',
	isa => Any,
	init_arg => 'colour'
);

has [qw/dealer crib_set/] => (
	is => 'rw',
	isa => Bool,
	default => 0
);

has starter_card => (
	is => 'rw'
);

sub start {
	my ($self, %params) = @_;

	$self->clear_screen;

	$self->print_header("Welcome to terminal Cribbage");

	$self->print_footer("Insert name: ");

	my $name = $self->read_line;

	return 'quit' unless defined $name;

	chomp($name);

	my $board = Game::Cribbage::Board->new();

	$board->add_player(name => 'Bot');
	$board->add_player(name => $name);

	$board->start_game();

	$self->board($board);

	my $status = $self->init_game();

	$self->leave_raw;

	return $status;
}

sub init_game {
	my ($self) = @_;

	$self->clear_screen;

	$self->reset_cursor();

	my $split = $self->split_cards();

	return 0 if defined $split && !ref $split && $split eq 'quit';

	return $self->init_draw();
}

sub init_draw {
	my ($self, $switch) = @_;

	$self->crib_set(0);
	$self->starter_card(undef);
	$self->dealer(!$self->dealer) if $switch;

	my $winner;
	if ($self->board->score->player1->{current} > 120) {
		$winner = 'player1';
	} elsif ($self->board->score->player2->{current} > 120) {
		$winner = 'player2';
	}
	return $self->winner($winner) if $winner;

	$self->draw_cards();

	my $discard = $self->discard_cards();

	return 0 if defined $discard && !ref $discard && $discard eq 'quit';

	my $split = $self->starter();

	return 0 if defined $split && !ref $split && $split eq 'quit';

	while (!$winner) {
		$self->clear_screen();

		$self->print_header(q|It is your turn to play a card, type go if you're unable to play.|);

		my $played = eval { $self->play_hand(); };

		return 0 if defined $played && !ref $played && $played eq 'quit';

		unless ($@) {
			if ($self->board->score->player1->{current} > 120) {
				$winner = 'player1';
				next;
			} elsif ($self->board->score->player2->{current} > 120) {
				$winner = 'player2';
				next;
			}


			my $hands = $self->board->get_hands;
			unless (grep { !$_->used } @{$hands->player2->cards}, @{$hands->player1->cards}) {
				eval {
					$self->end_hands();
				};
				return $self->init_draw(1);
			}

			if ($self->board->no_player_can_play) {
				eval { $self->board->next_play(); };
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

	$self->crib_set(0);

	$self->clear_screen();

	my $last = $self->board->last_round_hands();
	my $player1_score = $last->player1->score->total_score;
	my $player2_score = $last->player2->score->total_score;
	my $crib_player = $self->dealer ? $self->board->players->[-1]->name : 'Bot';
	my $player = $self->dealer ? 'player2' : 'player1';
	my $crib_score = $last->$player->crib_score->total_score;

	$self->print_header(sprintf "Bot scored: %s - %s scored: %s - %s crib scored: %s",
		$player1_score,
		$self->board->players->[-1]->name,
		$player2_score,
		$crib_player,
		$crib_score
	);

	$self->draw_scores();

	$self->render_player_cards($hands->player1->cards, 3, 20, 1);

	$crib_player = $hands->crib_player;
	$self->render_player_cards($hands->$crib_player->crib, 15, 20, 1);

	$self->render_player_cards($hands->player2->cards, 26, 20, 1);

	$self->print_footer(q|Press enter to continue|);

	$self->read_line;
}

sub play_hand {
	my ($self) = @_;

	my $hands = $self->board->get_hands;
	if ($self->board->next_to_play->player eq 'player1') {
		my $card = $self->board->best_run_play('player1');
		if ($card->can('go') && $card->go) {
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

	$self->render_opponent_cards(scalar grep { !$_->used } @{$hands->player1->cards});

	$self->render_run_play();

	my $number;
	if ($self->picking && $self->enter_raw) {
		$number = $self->pick_card('player2');
		return 'quit' if $number eq 'quit';
		$number = 'go' if $number eq 'go';
		$number = 'b'  if $number eq 'bot';
	}
	else {
		$self->render_player_cards($hands->player2->cards, 26, 20);

		$self->print_footer(q|Pick a card: |);

		$number = $self->read_line;

		return 'quit' unless defined $number;

		chomp($number);
	}

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
		if ($card->can('go') && $card->go) {
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

sub playable_cards {
	my ($self, $player) = @_;
	my $hands = $self->board->get_hands;
	my $hand = $player eq 'player1' ? $hands->player1 : $hands->player2;
	my $play = $self->board->current_play;

	my @can;
	my $i = 0;
	for my $card (@{ $hand->cards }) {
		$i++;
		next if $card->used;
		my $test = $play->test_card($player, $card);
		next if ref $test;
		push @can, $i;
	}
	return \@can;
}

sub card_line {
	my ($self, $player, $index) = @_;
	my $hands = $self->board->get_hands;
	my $hand = $player eq 'player1' ? $hands->player1 : $hands->player2;
	my $card = $hand->cards->[ $index - 1 ];
	my $play = $self->board->current_play;

	my $score = $play->test_card_score($player, $card);
	return sprintf('%s cannot be played, it would take the count past 31',
		$card->stringify) if ref $score eq 'Game::Cribbage::Error';

	my $count = $self->board->current_play_score + $card->value;

	# `run` AND `pair` ARE BOTH INDEXES INTO Play::Score's table, and only one
	# of them happens to read as a count. The table is
	# `run => [3, 4, 5, 6, 7]` and `pair => [2, 6, 12]`, so pair 1 is a pair
	# and run 1 is a run of THREE: the run length is the index plus two, and
	# printing the index gives "a run of 1" for three cards in sequence.
	my @why;
	push @why, 'fifteen'    if $score->fifteen;
	push @why, 'thirty-one' if $score->pegged;
	push @why, sprintf('a run of %d', $score->run + 2) if $score->run;
	push @why, ('a pair', 'three of a kind', 'four of a kind')[ $score->pair - 1 ]
		if $score->pair;

	my $total = $score->total_score;
	return sprintf '%s takes the count to %d%s%s',
		$card->stringify, $count,
		(@why ? ' for ' . join(' and ', @why) : ''),
		($total ? sprintf(', pegging %d', $total) : ', pegging nothing');
}

sub pick_card {
	my ($self, $player) = @_;

	my $can = $self->playable_cards($player);
	return 'go' unless @$can;

	my $at = 0;
	while (1) {
		my $hands = $self->board->get_hands;
		$self->clear_screen();
		$self->print_header($self->card_line($player, $can->[$at]));
		$self->draw_scores();
		$self->render_opponent_cards(scalar grep { !$_->used } @{$hands->player1->cards});
		$self->render_run_play();
		$self->render_player_cards($hands->player2->cards, 26, 20, 0,
			{ $can->[$at] => 'double' });
		$self->print_footer(
			q|arrows to choose, enter or space to play, g for go, b for the bot's pick, q to quit|);

		my $key = $self->read_key;
		return 'quit' unless defined $key;
		return 'quit' if $key eq 'q' || $key eq 'interrupt' || $key eq 'eof';
		return 'go'   if $key eq 'g';
		return 'bot'  if $key eq 'b';
		return $can->[$at] if $key eq 'enter' || $key eq ' ';
		$at = $self->step($can, $at, $key) if $key =~ /\A(?:up|down|left|right|home|end|tab)\z/;
	}
}

sub pick_discards {
	my ($self) = @_;

	my $hands = $self->board->get_hands;
	my $cards = $hands->player2->cards;
	my @all = (1 .. scalar @$cards);

	my ($at, %held) = (0);
	while (1) {
		my %marks = map { $_ => 'heavy' } keys %held;
		$marks{ $all[$at] } = 'double';

		$self->clear_screen();
		$self->print_header(sprintf '%s - %d of 2 chosen for the crib',
			$cards->[ $all[$at] - 1 ]->stringify, scalar keys %held);
		$self->render_opponent_cards(6);
		$self->render_player_cards($cards, 26, 5, 1, \%marks);
		$self->print_footer(
			q|arrows to choose, enter or space to take a card, b for the bot's pick, q to quit|);

		my $key = $self->read_key;
		return 'quit' unless defined $key;
		return 'quit' if $key eq 'q' || $key eq 'interrupt' || $key eq 'eof';
		return 'bot'  if $key eq 'b';

		if ($key eq 'enter' || $key eq ' ') {
			my $here = $all[$at];
			if ($held{$here}) { delete $held{$here} }
			elsif (scalar keys %held < 2) { $held{$here} = 1 }
			return [ sort { $a <=> $b } keys %held ] if scalar keys %held == 2;
			next;
		}
		$at = $self->step(\@all, $at, $key) if $key =~ /\A(?:up|down|left|right|home|end|tab)\z/;
	}
}

sub random_index {
	my ($self, $count) = @_;
	return int(rand($count));
}

sub step {
	my ($self, $items, $at, $key) = @_;
	return 0 if $key eq 'home';
	return $#$items if $key eq 'end';
	return ($at + 1) % @$items if $key eq 'right' || $key eq 'down' || $key eq 'tab';
	return ($at - 1) % @$items if $key eq 'left'  || $key eq 'up';
	return $at;
}

sub split_cards {
	my ($self) = @_;

	$self->print_header(q|Split cards lowest goes first|);

	$self->show_face_down_split(52);

	$self->print_footer(q|Pick a number: |);

	my $number = $self->read_line;

	return 'quit' unless defined $number;

	chomp($number);

	if ($number !~ m/^\d+$/ || $number < 1 || $number > 52) {
		$self->clear_screen();
		return $self->split_cards();
	}

	my $low = $self->board->deck->get($number - 1);

	# BOTH INDEXES ARE 0-BASED HERE. 0.16 drew the bot's card with
	# `get($rand - 1)` against a 0-based `rand(52)`, so rand 0 reached
	# `get(-1)`, the LAST card of the deck, and the "is it the same card"
	# guard compared a 1-based number with a 0-based index and so let the
	# pair collide whenever $number was $rand + 1.
	my $mine = $number - 1;
	my $rand = $self->random_index(52);

	while ($rand == $mine) {
		$rand = $self->random_index(52);
	}

	my $bot = $self->board->deck->get($rand);

	$self->clear_screen();

	my $dealer = $low->value < $bot->value ? 1 : 0;

	$self->print_header(q|Low cards picked, | . ($dealer ? "you are the dealer" : "they are the dealer"));

	$self->render_card($bot, 2, 45);

	$self->render_card($low, 27, 45);

	$self->board->set_crib_player($dealer ? 'player2' : 'player1');

	$self->print_footer(q|Press enter to continue|);

	$self->dealer($dealer);

	$self->read_line;
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

	my $cards_index;
	if ($self->picking && $self->enter_raw) {
		my $picked = $self->pick_discards();
		return 'quit' if !ref $picked && $picked eq 'quit';
		$cards_index = ref $picked ? join(' ', @$picked) : 'b';
	}
	else {
		$self->render_opponent_cards(6);

		$self->render_player_cards($hands->player2->cards, 26, 5);

		$self->print_footer(q|Discard cards: |);

		$cards_index = $self->read_line;

		return 'quit' unless defined $cards_index;

		chomp($cards_index);
	}

	my @cards;
	if ($cards_index =~ m/b/i) {
		my @worst = $self->board->identify_worst_cards('player2');
		@cards = @{$worst[0]};
	} else {
		@cards = map {
			$self->board->get_card('player2', $_ - 1);
		} grep { $_ =~ m/^\d+$/ && $_ >= 1 && $_ <= 6 } split " ", $cards_index;
	}

	unless (scalar @cards == 2) {
		$self->discard_cards();
		return;
	}

	$self->board->crib_player_cards('player2', \@cards);

	my @bot = $self->board->identify_worst_cards('player1');

	$self->board->crib_player_cards('player1', $bot[0]);

	$self->crib_set(1);
}

sub starter {
	my ($self) = @_;

	$self->clear_screen();

	my $count = scalar @{$self->board->deck->deck};
	if ($self->dealer) {
		# WHAT IS LEFT, NOT A HARDCODED 39. The deal takes six cards a side
		# and 0.16 wrote the remainder as a literal, so the bot's cut could
		# only ever reach the first 39 of the 40 that are there.
		my $card = $self->board->deck->get($self->random_index($count));
		$self->starter_card($card);
		$self->board->add_starter_card('player1', $card);
		return;
	}

	$self->print_header(q|Split deck for starter card.|);

	$self->show_face_down_split(40, 13);

	$self->print_footer(q|Split deck: |);

	my $number = $self->read_line;

	return 'quit' unless defined $number;

	chomp($number);

	# THE DECK HERE IS WHAT IS LEFT, NOT 52. Six cards a side and four to the
	# crib are already dealt, so the split is over `$count` cards and 0.16
	# checked against 52: a number past the end reached `get` for a card that
	# is not there, and the starter came back undef.
	if ($number !~ m/^\d+$/ || $number < 1 || $number > $count) {
		$self->clear_screen();
		return $self->starter();
	}

	my $card = $self->board->deck->get($number - 1);
	$self->starter_card($card);
	my $scored = $self->board->add_starter_card('player2', $card);
	return;
}

our %FRAME = (
	light  => [ '┌', '─', '┐', '│', '└', '┘' ],
	double => [ '╔', '═', '╗', '║', '╚', '╝' ],
	heavy  => [ '┏', '━', '┓', '┃', '┗', '┛' ],
);

sub render_card {
	my ($self, $card, $row, $col, $frame) = @_;

	$self->set_cursor_vertical($row);
	$self->set_cursor_horizontal($col);
	my $color = $card->suit =~ m/H|D/ ? 91 : 90;

	my %suits = (
		H => '♥',
		D => '♦',
		C => '♣',
		S => '♠'
	);

	my ($tl, $bar, $tr, $side, $bl, $br) = @{ $FRAME{ $frame || 'light' } || $FRAME{light} };
	my $top = $tl . ($bar x 9) . $tr;
	my $bot = $bl . ($bar x 9) . $br;

	my @card = (
		$top,
		sprintf("%s%s. . . .%s", $side, $card->symbol =~ m/10/ ? $card->symbol : $card->symbol . " ", $side),
		sprintf("%s. . . . .%s", $side, $side),
		sprintf("%s. . . . .%s", $side, $side),
		sprintf("%s. . %s . .%s", $side, $suits{$card->suit}, $side),
		sprintf("%s. . . . .%s", $side, $side),
		sprintf("%s. . . . .%s", $side, $side),
		sprintf("%s. . . .%s%s", $side, $card->symbol =~ m/10/ ? $card->symbol : " " . $card->symbol, $side),
		$bot
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
	my ($self, $cards, $top, $left, $all, $marks) = @_;
	my $i = 1;
	for (@{$cards}) {
		if (!$all && $_->used) {
			$i++;
			next;
		}
		$left += 11;
		$self->set_cursor_vertical($top);
		$self->set_cursor_horizontal($left + 5);
		$self->say($i);
		$self->render_card($_, $top + 1, $left, $marks ? $marks->{$i} : undef);
		$i++;
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
			$string = "└──" x $width;
		$self->say($string);
		$self->say("└─────────┘", 1, 1);
	}
}

sub draw_background {
	for (0 .. 35) {
		$_[0]->emit("\e[102;1m") if $_[0]->colour;
		$_[0]->emit(pack("A100", " "));
		$_[0]->emit("\n");
		$_[0]->emit("\e[0m") if $_[0]->colour;
	}
	$_[0]->draw_dealer();
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
	my ($self, $who) = @_;
	$self->emit("\e[0m\e[2J\e[0;1H");
	for (0 .. 35) {
		$self->emit("\e[102;1m") if $self->colour;
		$self->emit(pack("A100", " "));
		$self->emit("\n");
		$self->emit("\e[0m") if $self->colour;
	}
	$self->set_cursor_vertical(17);
	my $player = $self->board->players->[1];
	$self->say($who eq 'player2'
		? sprintf(q|Congratulations %s, you won the game!|, $player->name)
		: sprintf(q|Unlucky %s, you lost this time!|, $player->name)
	);
	$self->read_line;
	return $who eq 'player2' ? 0 : 1;
}


sub keys_available {
	my ($self) = @_;
	return 1 if $self->keysource;
	return 0 unless eval { -t $self->in };
	return eval { require Term::ReadKey; 1 } ? 1 : 0;
}

sub picking {
	my ($self, @set) = @_;
	$self->_picking($set[0] ? 1 : 0) if @set;
	return $self->_picking ? 1 : 0 if defined $self->_picking;
	return $self->keys_available;
}

sub colour {
	my ($self, @set) = @_;
	$self->_colour($set[0] ? 1 : 0) if @set;
	return $self->_colour ? 1 : 0 if defined $self->_colour;
	return 0 if defined $ENV{NO_COLOR} && length $ENV{NO_COLOR};
	return eval { -t $self->out } ? 1 : 0;
}

sub enter_raw {
	my ($self) = @_;
	return $self if $self->raw;
	if ($self->keysource) { $self->raw(1); return $self }
	return undef unless $self->keys_available;
	return undef unless eval { Term::ReadKey::ReadMode(3, $self->in); 1 };
	$self->raw(1);
	return $self;
}

sub leave_raw {
	my ($self) = @_;
	return $self unless $self->raw;
	eval { Term::ReadKey::ReadMode(0, $self->in) } unless $self->keysource;
	$self->raw(0);
	return $self;
}

sub read_char {
	my ($self, $wait) = @_;
	my $pending = $self->pending;
	return shift @$pending if @$pending;
	return $self->keysource->($wait) if $self->keysource;
	my $char = Term::ReadKey::ReadKey($wait ? 0 : -1, $self->in);
	return $char if defined $char || $wait;
	select undef, undef, undef, 0.05;
	return Term::ReadKey::ReadKey(-1, $self->in);
}

sub read_key {
	my ($self) = @_;
	my $char = $self->read_char(1);
	return undef unless defined $char;
	return $CONTROL{$char} if $CONTROL{$char};
	return $self->read_sequence if $char eq "\e";
	return $char;
}

sub read_sequence {
	my ($self) = @_;
	my $opener = $self->read_char(0);
	return 'escape' unless defined $opener;
	unless ($opener eq '[' || $opener eq 'O') {
		unshift @{ $self->pending }, $opener;
		return 'escape';
	}
	my $tail = '';
	while (length $tail < 8) {
		my $char = $self->read_char(0);
		last unless defined $char;
		$tail .= $char;
		last if $char =~ /[A-Za-z~]/;
	}
	return $SEQUENCE{$tail} || 'escape';
}

sub emit {
	my ($self, @text) = @_;
	my $fh = $self->out;
	print {$fh} @text;
	1;
}

sub read_line {
	my ($self) = @_;
	my $fh = $self->in;
	my $line = <$fh>;
	return $line;
}

sub clear_screen {
	$_[0]->emit("\e[0m\e[2J\e[0;1H");
	$_[0]->draw_background();
}

sub reset_cursor {
	$_[0]->emit("\e[;2H");
}

sub set_cursor_vertical {
	$_[0]->emit("\e[$_[1];2H");
}

sub set_cursor_horizontal {
	$_[0]->emit("\e[$_[1]G");
}

sub say {
	my ($self, $msg, $nl, $indent, $color, $back) = @_;
	$color ||= 90;
	$back ||= 102;
	$self->emit("\e[$color;1;1m\e[$back;1m") if $self->colour;
	$self->emit($msg);
	$self->emit("\n") if $nl;
	$self->set_cursor_horizontal(2) if $indent;
	$self->emit("\e[0m") if $self->colour;
	1;
}

sub print_header {
	my ($self, $message) = @_;
	$self->set_cursor_vertical(0);
	$self->set_cursor_horizontal(0);
	$self->emit("\e[40;1m") if $self->colour;
	$self->emit(pack("A100", " "));
	$self->set_cursor_horizontal(2);
	$self->say($message, 0, 0, 31, 40);
}

sub print_footer {
	my ($self, $message) = @_;
	$self->set_cursor_vertical(36);
	$self->set_cursor_horizontal(0);
	$self->emit("\e[40;1m") if $self->colour;
	$self->emit(pack("A100", " "));
	$self->set_cursor_horizontal(2);
	$self->say($message, 0, 0, 31, 40);
	$self->set_cursor_horizontal(length($message) + 2);
}

sub _usage {
	return <<'USAGE';
cribbage - cribbage on a terminal

usage: cribbage [options]

  --pick         choose cards with the arrow keys; --no-pick to type numbers
  --help         this

exit status:
  0   you won, or you quit
  1   you lost
  2   a bad option

With a terminal and Term::ReadKey the arrow keys walk the cards you can play
and the box round one says what it would peg. Without either, or with
--no-pick, a card is chosen by typing its number. Colour is off when NO_COLOR
is set or the output is not a terminal.
USAGE
}

sub run {
	my ($class, @argv) = @_;
	my %opt;

	my $ok = eval {
		local $SIG{__WARN__} = sub { print STDERR "cribbage: $_[0]" };
		Getopt::Long::GetOptionsFromArray(\@argv, \%opt, 'pick!', 'help');
	};
	if (!$ok)       { print STDERR _usage(); return 2 }
	if ($opt{help}) { print _usage(); return 0 }
	if (@argv)      { print STDERR "cribbage: not an option: $argv[0]\n", _usage(); return 2 }

	my $terminal = $class->new(picking => $opt{pick});

	local @SIG{qw(INT TERM HUP)};
	for my $sig (qw(INT TERM HUP)) {
		$SIG{$sig} = sub { $terminal->leave_raw; $SIG{$sig} = 'DEFAULT'; kill $sig, $$ };
	}

	my $status = eval { $terminal->start };
	my $died = $@;
	$terminal->leave_raw;
	$terminal->emit("\e[0m\n");
	die $died if $died;

	return $status && $status =~ /^\d+$/ ? $status : 0;
}

1;

__END__

=encoding utf8

=head1 NAME

Game::Cribbage::Terminal - the cribbage board on a terminal

=head1 VERSION

Version 0.17

=head1 SYNOPSIS

	my $t = Game::Cribbage::Terminal->new;
	my $status = $t->start;          # RETURNS the exit status; never exits

	Game::Cribbage::Terminal->new(picking => 0)->start;   # type numbers

=head1 DESCRIPTION

Everything that knows about a screen, and nothing that knows about the rules:
those are L<Game::Cribbage::Board>'s. C<in> and C<out> are read-write
properties defaulting to C<STDIN> and C<STDOUT>, so a test can hand it a pair of
handles and read back exactly what it drew.

B<C<start> returns and never calls C<exit>.> Its return value is the exit status
F<bin/cribbage> should use: C<0> if you won or quit, C<1> if you lost.

=head1 PROPERTIES

The following properties are defined in L<Game::Cribbage::Terminal>

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

The following functions are defined in L<Game::Cribbage::Terminal>


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
        $game->board($board);

	$game->clear_screen;

	$game->reset_cursor();

	$game->split_cards();

	$game->init_draw();


=head2 run

	exit Game::Cribbage::Terminal->run(@ARGV);

The whole command line program as a class method: parses the options
F<bin/cribbage> documents, builds the terminal, plays, and B<returns the exit
status rather than calling C<exit>>: C<0> if you won or quit, C<1> if you lost,
C<2> for a bad option, with the usage on C<STDERR>. C<--help> prints the usage on
C<STDOUT> and returns C<0>. Signal handlers are local to the call and the terminal
is left in cooked mode on every way out, so a launcher such as L<Game::Terminal>
can call it in its own process and carry on afterwards. Colour is off under
C<NO_COLOR> and off a terminal.


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

=head1 THE PICKER

With a terminal and L<Term::ReadKey>, the two choices that decide a cribbage
game are made with the arrow keys instead of by typing a number: the two cards
that go to the crib, and the card you play into the count.

B<The cursor only ever stops on a card you can play.> The set it walks comes
from L</playable_cards>, which asks L<Game::Cribbage::Play/test_card> about each
card in turn, so a card that would take the count past 31 is never a stop and
never has to be refused after the fact.

=head2 The marks are frames, not colours

Three things need marking at once while discarding, so there are three box
frames: light for an ordinary card, B<double> for the one under the cursor, and
B<heavy> for a card already chosen for the crib. A mark that is a colour is gone
the moment the board is piped into a file, and the suits are already using
colour to tell red from black.

=head2 The caption is the engine's

L</card_line> reads L<Game::Cribbage::Play/test_card_score> and reports what it
says: the count the card takes you to, whether that is a fifteen or
thirty-one, the pair or run it makes and what it pegs. Nothing about the score
is worked out here, because a preview that does its own arithmetic is a second
implementation of the rules that can disagree with the first.

=head1 KEYS AND INPUT

=head2 in

=head2 out

Read-write handles, defaulting to C<STDIN> and C<STDOUT>. Everything the
terminal draws goes through C<out> and every line it reads comes from C<in>, so
a test can drive a whole game with a pair of in-memory handles.

=head2 picking

Whether the arrow keys are offered. Set it false to type numbers instead; left
unset it follows L</keys_available>.

=head2 colour

Whether the escapes that colour the screen are written. Set it either way;
left unset it is off when C<NO_COLOR> is set to anything, off when L</out> is
not a terminal, and on otherwise. The cursor movement that lays the screen out
is not colour and is written regardless.

=head2 keys_available

Whether a key can be read at all: a C<keysource>, or C<in> being a terminal with
L<Term::ReadKey> installed. B<Term::ReadKey is a recommendation and not a
prerequisite>, so this is false on a perfectly good installation and the typed
prompt is what that installation gets.

=head2 enter_raw

=head2 leave_raw

The cbreak mode round the picker. B<Cbreak and not raw>, so an interrupt is
still an interrupt. C<leave_raw> is safe to call more than once and from a
signal handler; L</run> calls it from C<INT>, C<TERM>, C<HUP> and after a die,
because a program that leaves a terminal in cbreak leaves the shell unusable.

=head2 keysource

=head2 pending

=head2 raw

The seam a test drives the picker through, the pushback queue for an escape
sequence that turned out not to be one, and the cbreak state. C<keysource> is a
coderef returning B<one character per call>, which is what makes the escape
sequence for an arrow key testable: the reader has to ask three times for one
key.

=head2 read_char

=head2 read_key

=head2 read_sequence

One character, one named key, and the tail of an escape sequence. C<read_key>
returns C<'up'>, C<'enter'>, C<'escape'> and so on, or the character itself.

=head2 read_line

=head2 emit

One line in and whatever is handed to it out, both through L</in> and L</out>.
B<Nothing in this module may use C<print> or C<E<lt>STDINE<gt>> directly>: that
is what made the terminal untestable before.

=head1 CHOOSING

=head2 playable_cards

	my $can = $t->playable_cards('player2');    # [ 1, 3, 4 ]

The 1-based positions in that player's hand of the cards that can legally be
played into the current count, asked of the engine one card at a time. Empty
means a go.

=head2 card_line

	$t->card_line('player2', 3);
	# '7♦️ takes the count to 15 for fifteen, pegging 2'

The caption under the cursor, read from the engine.

=head2 pick_card

Runs the picker for one card and returns its 1-based position, or C<'go'>,
C<'bot'> or C<'quit'>.

=head2 pick_discards

Runs the picker for the crib and returns an arrayref of the two 1-based
positions chosen, or C<'bot'> or C<'quit'>. Enter on a card that is already
chosen puts it back.

=head2 random_index

	my $i = $t->random_index($count);    # 0 .. $count - 1

Every draw this module makes goes through here: the bot's card at the low-card
split and the bot's cut for the starter. It exists so a test can pin the draw,
and B<a test must pin it here and not with C<local *CORE::GLOBAL::rand>>, which
has to be in place before the calling code is compiled and so does nothing at
all when a test file sets it after its own C<use> line.

=head2 step

	my $i = $t->step(\@items, $at, 'right');

The index the cursor lands on. Left and up go back, right, down and tab go on,
and both wrap; home and end are the ends. The hand is drawn as one row, so left
and up are the same key and so are right and down.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
