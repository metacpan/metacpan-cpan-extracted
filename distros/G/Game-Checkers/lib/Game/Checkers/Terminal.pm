package Game::Checkers::Terminal;

use strict;
use warnings;

use Object::Proto::Sugar -types;
use Game::Checkers;
use Game::Checkers::Bot;
use Game::Checkers::Notation;
use Game::Checkers::Squares;

our $VERSION = '0.01';

our %COMMAND;

BEGIN {
	%COMMAND = (
		help => 'this list',
		'?' => 'this list',
		moves => 'the legal moves, numbered: play one by its number',
		hint => 'what the bot would play here',
		board => 'draw the board again',
		fen => 'the position as FEN',
		undo => 'take back your last move, and the reply to it',
		'save FILE' => 'write the game out as PDN',
		'load FILE' => 'read a PDN game back in',
		'level N' => 'set the strength of the bot, 1 to 5',
		flip => 'draw the board from the other side',
		ascii => 'letters instead of draughts symbols',
		draw => 'offer a draw',
		resign => 'give the game up',
		quit => 'stop playing',
	);
}

my %PIECE = (
	1 => { ascii => 'b', wide => "\x{26C2}" },
	2 => { ascii => 'B', wide => "\x{26C3}" },
	-1 => { ascii => 'w', wide => "\x{26C0}" },
	-2 => { ascii => 'W', wide => "\x{26C1}" },
);

has game => (
	is => 'rw',
	isa => Object
);

has bot => (
	is => 'rw'
);

has human => (
	is => 'rw',
	isa => Str,
	default => 'black'
);

has [qw/in out/] => (
	is => 'rw'
);

has [qw/interactive colour/] => (
	is => 'rw'
);

has [qw/ascii flip/] => (
	is => 'rw',
	isa => Bool,
	default => 0
);

has redraw => (
	is => 'rw',
	isa => Bool,
	default => 1
);

sub BUILD {
	my ($self) = @_;
	$self->game(Game::Checkers->new) unless $self->game;
	$self->in(\*STDIN) unless $self->in;
	$self->out(\*STDOUT) unless $self->out;
	$self->interactive(-t $self->in ? 1 : 0) unless defined $self->interactive;
	$self->colour($self->interactive && !$ENV{NO_COLOR} ? 1 : 0)
		unless defined $self->colour;
	binmode $self->out, ':encoding(UTF-8)' unless $self->ascii;

	# a prompt is printed without a newline and has to be on the screen before
	# the read, and the encoding layer holds on to output otherwise
	my $previous = select $self->out;
	$| = 1;
	select $previous;
	return $self;
}

sub start {
	my ($self) = @_;
	$self->say('Checkers. Type help for the commands.');
	while (1) {
		# only a move or a switch redraws: a list of moves or a refusal would
		# otherwise be wiped, or pushed off the top, by the board that follows it
		$self->render if $self->redraw;
		if (my $result = $self->game->result) {
			$self->say($result->stringify);
			last;
		}
		if ($self->bot_plays($self->game->turn)) {
			$self->bot_move;
			next;
		}
		my $line = $self->read_line;
		unless (defined $line) {
			$self->say('Bye.');
			last;
		}
		last if $self->command($line);
	}
	return $self->game->result;
}

sub bot_plays {
	my ($self, $side) = @_;
	return 0 if $self->human eq 'both' || !$self->bot;
	return 1 if $self->human eq 'none';
	return $side eq $self->human ? 0 : 1;
}

sub bot_move {
	my ($self) = @_;
	my $move = $self->bot->choose($self->game) or return undef;
	$self->game->move($move);
	$self->say(sprintf '%s plays %s.', ucfirst $move->side, $move->coord_notation);
	$self->redraw(1);
	return $move;
}

sub read_line {
	my ($self, $prompt) = @_;
	my $out = $self->out;
	print {$out} defined $prompt ? $prompt : $self->game->turn . '> ';
	my $line = readline $self->in;
	return undef unless defined $line;
	chomp $line;
	return $line;
}

sub say {
	my ($self, $line) = @_;
	my $out = $self->out;
	print {$out} (defined $line ? $line : ''), "\n";
	return $self;
}

sub clear {
	my ($self) = @_;
	return $self unless $self->interactive;
	my $out = $self->out;
	print {$out} "\e[2J\e[H";
	return $self;
}

sub render {
	my ($self) = @_;
	$self->clear;
	$self->say($_) for @{$self->board_lines}, '', @{$self->status_lines};
	$self->redraw(0);
	return $self;
}

sub board_lines {
	my ($self) = @_;
	my $board = $self->game->board;
	my $rule = '   +' . ('---+' x 8);
	my @files = ('a' .. 'h');
	my @rows = 0 .. 7;
	my @cols = 0 .. 7;
	if ($self->flip) {
		@rows = reverse @rows;
		@cols = reverse @cols;
	}

	my @aside = @{$self->aside};
	# five spaces puts a over the middle of the first cell, which the rule line
	# opens at index 3
	my @lines = ('     ' . join('   ', @files[@cols]), $rule);
	for my $row (@rows) {
		my $line = sprintf '%2d |', 8 - $row;
		for my $col (@cols) {
			$line .= $self->cell($board, $row, $col) . '|';
		}
		if (my $note = shift @aside) {
			$line .= '  ' . $note;
		}
		push @lines, $line, $rule;
	}
	return \@lines;
}

sub cell {
	my ($self, $board, $row, $col) = @_;
	my $square = Game::Checkers::Squares::square($row, $col);
	return '   ' unless $square;
	if (my $value = $board->at($square)) {
		my $piece = $PIECE{$value}{$self->ascii ? 'ascii' : 'wide'};
		return ' ' . $self->paint($piece, $value > 0 ? '1;36' : '1;37') . ' ';
	}
	# an empty playing square is dotted, because half the squares are not in the
	# game at all and nothing else on the board says which half
	return ' ' . $self->paint('.', '2') . ' ';
}

sub paint {
	my ($self, $text, $code) = @_;
	return $text unless $self->colour;
	return "\e[${code}m" . $text . "\e[0m";
}

sub aside {
	my ($self) = @_;
	my $board = $self->game->board;
	my @aside;
	for my $side (qw/black white/) {
		my $count = $board->count($side);
		push @aside, sprintf '%-5s %2d  (%d kings)',
			ucfirst $side, $count->{total}, $count->{kings};
	}
	return \@aside;
}

sub status_lines {
	my ($self) = @_;
	my $game = $self->game;
	my @lines;

	if (my $last = $game->history->[-1]) {
		push @lines, sprintf 'Last: %s by %s%s',
			$last->coord_notation, $last->side,
			(@{$last->captures}
				? ', taking ' . join(', ',
					map { Game::Checkers::Squares::coord_name($_) }
					@{$last->captures})
				: '');
	}

	if (my $result = $game->result) {
		push @lines, $result->stringify;
		return \@lines;
	}

	my $moves = scalar @{$game->legal_moves};
	push @lines, $game->must_capture
		? sprintf('%s must capture, %d %s available',
			ucfirst $game->turn, $moves, $moves == 1 ? 'jump' : 'jumps')
		: sprintf('%s to move, %d %s',
			ucfirst $game->turn, $moves, $moves == 1 ? 'move' : 'moves');

	push @lines, sprintf '%s has offered a draw.', ucfirst $game->draw_offered_by
		if $game->draw_offered_by;

	return \@lines;
}

sub command {
	my ($self, $line) = @_;
	$line =~ s/^\s+|\s+$//g;
	return 0 unless length $line;

	my ($word, $argument) = split ' ', $line, 2;
	$word = lc $word;

	return $self->show_help if $word eq 'help' || $word eq '?';
	return $self->redraw(1) && 0 if $word eq 'board';
	return $self->show_moves if $word eq 'moves';
	return $self->show_hint if $word eq 'hint';
	return $self->say('FEN: ' . $self->game->to_fen) && 0 if $word eq 'fen';
	return $self->take_back if $word eq 'undo';
	return $self->save($argument) if $word eq 'save';
	return $self->load($argument) if $word eq 'load';
	return $self->set_level($argument) if $word eq 'level';
	return $self->toggle($word) if $word eq 'flip' || $word eq 'ascii';
	return $self->offer_draw if $word eq 'draw';
	return $self->resign if $word eq 'resign';
	return $self->quit if $word eq 'quit';

	return $self->play_number($word) if $word =~ m/^[0-9]+$/;
	return $self->play($line);
}

sub play {
	my ($self, $notation) = @_;
	my $move = $self->game->move($notation);
	return $self->redraw(1) && 0 unless ref $move eq 'Game::Checkers::Error';

	$self->say(ucfirst $move->message . '.');
	$self->say('Type moves for the list, or help for the commands.')
		if $move->not_a_move;
	$self->say('You could play: '
		. join ', ', map { $_->coord_notation } @{$move->legal})
		if @{$move->legal} && !$move->not_a_move;
	return 0;
}

sub play_number {
	my ($self, $number) = @_;
	my $legal = $self->game->legal_moves;
	return $self->say("There is no move $number. Type moves for the list.") && 0
		unless $number >= 1 && $number <= @{$legal};
	$self->game->move($legal->[$number - 1]);
	$self->redraw(1);
	return 0;
}

sub show_moves {
	my ($self) = @_;
	my $legal = $self->game->legal_moves;
	my $number = 0;
	$self->say(sprintf '%2d. %s', ++$number, $_->coord_notation) for @{$legal};
	$self->say('Play one by its number, or type it out.');
	return 0;
}

sub show_hint {
	my ($self) = @_;
	my $bot = $self->bot || Game::Checkers::Bot->new;
	my $move = $bot->choose($self->game);
	return $self->say('There is nothing to play.') && 0 unless $move;
	my $score = $bot->last_search->{score};
	$self->say(sprintf 'Try %s%s.', $move->coord_notation,
		defined $score ? sprintf(' (it scores that %+.2f)', $score / 100) : '');
	return 0;
}

sub take_back {
	my ($self) = @_;
	my $game = $self->game;
	return $self->say('There is nothing to take back.') && 0 unless $game->ply;

	$game->undo;
	# and the reply that provoked it, so the board comes back as you left it
	$game->undo if $game->ply && $self->bot_plays($game->turn);
	$self->say('Taken back.');
	$self->redraw(1);
	return 0;
}

sub save {
	my ($self, $file) = @_;
	return $self->say('Save needs a file name.') && 0 unless $file;
	open my $handle, '>', $file
		or return $self->say("Cannot write $file: $!") && 0;
	print {$handle} $self->game->to_pdn(Event => 'Terminal checkers');
	close $handle;
	$self->say("Saved to $file.");
	return 0;
}

sub load {
	my ($self, $file) = @_;
	return $self->say('Load needs a file name.') && 0 unless $file;
	open my $handle, '<', $file
		or return $self->say("Cannot read $file: $!") && 0;
	my $pdn = do { local $/; <$handle> };
	close $handle;
	my $game = eval { Game::Checkers->from_pdn($pdn) };
	return $self->say("That is not a game I can read: $@") && 0 unless $game;
	$self->game($game);
	$self->say("Loaded $file, " . $game->ply . ' moves in.');
	$self->redraw(1);
	return 0;
}

sub set_level {
	my ($self, $level) = @_;
	return $self->say('Level takes a number from 1 to 5.') && 0
		unless defined $level && $level =~ m/^[1-5]$/;
	$self->bot(Game::Checkers::Bot->new) unless $self->bot;
	$self->bot->level($level);
	$self->say("The bot is at level $level.");
	return 0;
}

sub toggle {
	my ($self, $what) = @_;
	$self->$what($self->$what ? 0 : 1);
	$self->redraw(1);
	return 0;
}

sub offer_draw {
	my ($self) = @_;
	my $game = $self->game;
	my $side = $self->human eq 'both' ? $game->turn : $self->human;
	$game->offer_draw($side);
	$self->redraw(1);
	return 0 unless $self->bot;

	# the bot answers from what it thought of the position last time it moved,
	# which costs nothing and is the same number it played on
	my $score = $self->bot->last_search ? $self->bot->last_search->{score} : undef;
	if (defined $score && $score <= 30) {
		$game->accept_draw($side eq 'black' ? 'white' : 'black');
		$self->say('The bot takes the draw.');
	} else {
		$game->decline_draw($side eq 'black' ? 'white' : 'black');
		$self->say('The bot plays on.');
	}
	return 0;
}

sub resign {
	my ($self) = @_;
	my $game = $self->game;
	$game->resign($self->human eq 'both' ? $game->turn : $self->human);
	$self->redraw(1);
	return 0;
}

sub quit {
	my ($self) = @_;
	return 1 unless $self->game->status eq 'active' && $self->game->ply;
	my $answer = $self->read_line('Really quit, with the game unfinished? (y/n) ');
	return 1 if !defined $answer || $answer =~ m/^\s*y/i;
	return 0;
}

sub show_help {
	my ($self) = @_;
	$self->say('A move is its squares: a3-b4 to slide, c3xe5xg7 to jump.');
	$self->say(sprintf '  %-12s %s', $_, $COMMAND{$_})
		for sort { length $a <=> length $b || $a cmp $b } keys %COMMAND;
	return 0;
}

1;

__END__

=head1 NAME

Game::Checkers::Terminal - the game at a prompt

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Game::Checkers;
	use Game::Checkers::Bot;
	use Game::Checkers::Terminal;

	Game::Checkers::Terminal->new(
		game  => Game::Checkers->new,
		bot   => Game::Checkers::Bot->new(level => 3),
		human => 'black',
	)->start;

=head1 DESCRIPTION

Everything in this distribution that reads a handle or writes to one is here.
L<Game::Checkers> and the modules under it do no input and no output at all, and
nothing in the engine loads this module: the C<checkers> script does.

The handles are properties. C<in> and C<out> default to STDIN and STDOUT, and a
test hands it two in memory filehandles and plays a whole game in process, which
is the reason for the split.

C<start> returns the L<Game::Checkers::Result> and never calls C<exit>, so the
script owns the exit status.

=head2 The board

	     a   b   c   d   e   f   g   h
	   +---+---+---+---+---+---+---+---+
	 8 |   | b |   | b |   | b |   | b |  Black 12  (0 kings)
	   +---+---+---+---+---+---+---+---+
	 7 | b |   | b |   | b |   | b |   |  White 12  (0 kings)
	   +---+---+---+---+---+---+---+---+
	 6 |   | b |   | b |   | b |   | b |
	   +---+---+---+---+---+---+---+---+
	 5 | . |   | . |   | . |   | . |   |
	   ...

Pieces are the Unicode draughts symbols, or C<b>, C<B>, C<w> and C<W> with
L</ascii>. An empty playing square is a dot: half the board is never played on and
the dots are what say which half. Colour is on only when the input is a terminal
and C<NO_COLOR> is unset.

=head2 Moves and the commands

A move is written as the squares it is on, read off the letters and numbers round
the edge: C<a3-b4> to slide and C<c3xe5xg7> to jump, with the whole path for a
multiple jump. Numeric notation is still accepted, because
L<Game::Checkers::Notation> reads both, but nothing here prints it: a saved game
is PDN, which is numeric, and the board is not.

A bare number plays that move from the C<moves> list. Everything else is a
command: C<help>, C<moves>, C<hint>, C<board>, C<fen>, C<undo>, C<save FILE>,
C<load FILE>, C<level N>, C<flip>, C<ascii>, C<draw>, C<resign> and C<quit>. An
unknown word is answered and the prompt comes back: the loop never dies on what
somebody types, which is what L<Game::Checkers::Error> is for.

The board is drawn again when something changes it, and not otherwise. A list of
moves, a hint or a refusal stays on the screen with the prompt under it, rather
than being cleared away, or pushed off the top, by a board that is exactly the one
already drawn.

End of file on C<in> is a clean quit, so C<< echo | checkers >> ends instead of
spinning.

=head1 PROPERTIES

=head2 game

Read and write L<Game::Checkers>, a new game by default.

	$terminal->game;

=head2 bot

Read and write L<Game::Checkers::Bot>, or undef for two people at one keyboard.

	$terminal->bot;

=head2 human

Read and write string: C<black> or C<white> for a game against the bot, C<both>
for hotseat, C<none> to watch two bots play.

	$terminal->human;

=head2 in, out

Read and write filehandles, STDIN and STDOUT by default. C<out> is given a UTF-8
layer unless L</ascii> is set.

	$terminal->out;

=head2 interactive

Read and write boolean, true when C<in> is a terminal. It decides whether the
screen is cleared between moves, so a captured transcript stays readable.

	$terminal->interactive;

=head2 colour

Read and write boolean. Defaults to on when the session is interactive and
C<NO_COLOR> is unset.

	$terminal->colour;

=head2 ascii

Read and write boolean: letters instead of the Unicode symbols.

	$terminal->ascii;

=head2 redraw

Read and write boolean: whether the board wants drawing again. L</render> clears
it and a move, an undo, a load or one of the switches sets it, so the loop only
draws a board that has changed.

	$terminal->redraw;

=head2 flip

Read and write boolean: draw the board from White's side. The square names do not
change, because they name the board and not the view of it.

	$terminal->flip;

=head1 FUNCTIONS

=head2 start

Runs the game to its end and returns the result.

	my $result = $terminal->start;

=head2 render

Draws the board and the status block.

	$terminal->render;

=head2 board_lines

The board as an arrayref of lines, without their newlines.

	$terminal->board_lines;

=head2 status_lines

The lines under the board: the last move, whose turn it is and how many moves
they have, any draw offer, and the result once there is one.

	$terminal->status_lines;

=head2 aside

The two lines printed beside the top of the board, one a side, with the piece
counts.

	$terminal->aside;

=head2 cell

The three characters for one square of the board.

	$terminal->cell($board, 0, 1);

=head2 paint

Wraps text in an ANSI colour, or returns it untouched when colour is off.

	$terminal->paint('b', '1;36');

=head2 command

Handles one line of input, whether it is a move or a command. Returns true when
the game should stop.

	$terminal->command('f6-e5');

=head2 play

Plays a move written out, and prints why not when it is refused.

	$terminal->play('f6-e5');

=head2 play_number

Plays a move by its place in the numbered list.

	$terminal->play_number(3);

=head2 bot_plays

True when the given side belongs to the bot.

	$terminal->bot_plays('white');

=head2 bot_move

Lets the bot play one move and announces it.

	$terminal->bot_move;

=head2 read_line

Prints a prompt and reads one line from C<in>, returning undef at end of file.

	my $line = $terminal->read_line;

=head2 say

Prints one line to C<out>.

	$terminal->say('your move');

=head2 clear

Clears the screen, but only in an interactive session.

	$terminal->clear;

=head2 show_moves, show_hint, show_help

The C<moves>, C<hint> and C<help> commands.

	$terminal->show_moves;

=head2 take_back

The C<undo> command: your last move and the reply to it.

	$terminal->take_back;

=head2 save, load

The C<save> and C<load> commands, which write and read PDN.

	$terminal->save('game.pdn');

=head2 set_level

The C<level> command.

	$terminal->set_level(4);

=head2 toggle

Flips one of the rendering switches by name.

	$terminal->toggle('flip');

=head2 offer_draw

The C<draw> command. The bot answers from the score it recorded on its last move,
taking the draw when it is not better than a third of a man ahead.

	$terminal->offer_draw;

=head2 resign

The C<resign> command.

	$terminal->resign;

=head2 quit

The C<quit> command, which asks first when a game is under way.

	$terminal->quit;

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-checkers at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Checkers>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::Checkers

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game-Checkers>

=item * Search CPAN

L<https://metacpan.org/release/Game-Checkers>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
