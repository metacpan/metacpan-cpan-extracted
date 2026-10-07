package Game::Checkers::Terminal;

use strict;
use warnings;

use Object::Proto::Sugar -types;
use Game::Checkers;
use Game::Checkers::Bot;
use Game::Checkers::Notation;
use Game::Checkers::Squares;

our $VERSION = '0.02';

our %COMMAND;

BEGIN {
	%COMMAND = (
		help => 'this list',
		'?' => 'this list',
		moves => 'the legal moves, numbered: play one by its number',
		pick => 'choose a move with the arrow keys instead of typing it',
		type => 'go back to typing moves out',
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

# the squares nobody plays on are the light ones, so an unplayed square needs no
# mark of its own once the board is painted
my %GROUND = (
	light => '48;5;180',
	dark => '48;5;94',
	from => '48;5;136',
	to => '48;5;28',
	captured => '48;5;124',
	cursor => '48;5;24',
);

my %INK = (
	black => '1;38;5;16',
	white => '1;38;5;231',
);

# resign and draw are not on a key on purpose: a game should not end because a
# finger slipped on the row below the arrow keys
my %KEY = (
	u => 'undo',
	f => 'flip',
	a => 'ascii',
	q => 'quit',
);

# Term::ReadKey hands over one character at a time and leaves an escape
# sequence as the characters it is made of, so the arrow keys are named here
my %SEQUENCE = (
	'A' => 'up',
	'B' => 'down',
	'C' => 'right',
	'D' => 'left',
	'H' => 'home',
	'F' => 'end',
	'1~' => 'home',
	'4~' => 'end',
	'5~' => 'page_up',
	'6~' => 'page_down',
	'7~' => 'home',
	'8~' => 'end',
);

my %CONTROL = (
	"\r" => 'enter',
	"\n" => 'enter',
	"\t" => 'tab',
	"\x7f" => 'backspace',
	"\x08" => 'backspace',
	"\x03" => 'interrupt',
	"\x04" => 'eof',
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

has highlight => (
	is => 'rw',
	isa => HashRef,
	default => {}
);

has picking => (
	is => 'rw',
	isa => Bool
);

has raw => (
	is => 'rw',
	isa => Bool,
	default => 0
);

has keysource => (
	is => 'rw',
	isa => CodeRef
);

has pending => (
	is => 'rw',
	isa => ArrayRef,
	default => []
);

sub BUILD {
	my ($self) = @_;
	$self->game(Game::Checkers->new) unless $self->game;
	$self->in(\*STDIN) unless $self->in;
	$self->out(\*STDOUT) unless $self->out;
	$self->interactive(-t $self->in ? 1 : 0) unless defined $self->interactive;
	$self->colour($self->interactive && !$ENV{NO_COLOR} ? 1 : 0)
		unless defined $self->colour;
	$self->picking($self->interactive ? 1 : 0) unless defined $self->picking;
	$self->picking(0) unless $self->keys_available;
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
	$self->picking(0) if $self->picking && !$self->enter_raw;

	# a raw terminal that is never put back is a broken shell, so the interrupt
	# is caught only to restore it, and then raised again as if it had not been
	my $interrupt = $SIG{INT};
	local $SIG{INT} = sub {
		$self->leave_raw;
		$SIG{INT} = defined $interrupt ? $interrupt : 'DEFAULT';
		kill 'INT', $$;
	};

	$self->say('Checkers. Type help for the commands.');
	my $played = eval { $self->turns; 1 };
	my $error = $@;
	$self->leave_raw;
	die $error unless $played;
	return $self->game->result;
}

sub turns {
	my ($self) = @_;
	while (1) {
		my $picking = $self->picking && $self->raw;
		# only a move or a switch redraws: a list of moves or a refusal would
		# otherwise be wiped, or pushed off the top, by the board that follows
		# it. A picked move draws its own screen, every keystroke of it
		$self->render if $self->redraw && !$picking;
		if (my $result = $self->game->result) {
			$self->highlight({});
			$self->render if $picking;
			$self->say($result->stringify);
			last;
		}
		if ($self->bot_plays($self->game->turn)) {
			$self->bot_move;
			next;
		}
		my $line = $picking ? $self->pick : $self->read_line;
		unless (defined $line) {
			$self->say('Bye.');
			last;
		}
		last if $self->command($line);
	}
	return $self;
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

sub keys_available {
	my ($self) = @_;
	return 1 if $self->keysource;
	return 0 unless defined $self->in && -t $self->in;
	return eval { require Term::ReadKey; 1 } ? 1 : 0;
}

sub enter_raw {
	my ($self) = @_;
	return $self if $self->raw;
	if ($self->keysource) {
		$self->raw(1);
		return $self;
	}
	return undef unless $self->keys_available;
	# cbreak rather than raw, so an interrupt is still an interrupt and not a
	# key this has to know about
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
	return shift @{$pending} if @{$pending};
	return $self->keysource->($wait) if $self->keysource;
	my $char = Term::ReadKey::ReadKey($wait ? 0 : -1, $self->in);
	return $char if defined $char || $wait;
	# nothing there yet, and the rest of an escape sequence is worth one short
	# wait before the escape is taken for the key of that name
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
	# a pressed escape key that happens to be followed by a real keystroke must
	# not eat it, so what is not the opening of a sequence goes back
	unless ($opener eq '[' || $opener eq 'O') {
		unshift @{$self->pending}, $opener;
		return 'escape';
	}
	my $tail = '';
	while (length $tail < 8) {
		my $char = $self->read_char(0);
		last unless defined $char;
		$tail .= $char;
		last if $char =~ m/[A-Za-z~]/;
	}
	return $SEQUENCE{$tail} || 'escape';
}

sub pick {
	my ($self) = @_;
	return undef unless $self->raw;
	my $legal = $self->game->legal_moves;
	return undef unless @{$legal};

	my $at = 0;
	my $notice = [];
	while (1) {
		$self->show_choice($legal, $at, $notice);
		$notice = [];
		my $key = $self->read_key;
		return undef if !defined $key || $key eq 'eof' || $key eq 'interrupt';

		if ($key eq 'up' || $key eq 'left' || $key eq 'k') {
			$at = ($at - 1) % @{$legal};
			next;
		}
		if ($key eq 'down' || $key eq 'right' || $key eq 'tab' || $key eq 'j') {
			$at = ($at + 1) % @{$legal};
			next;
		}
		if ($key eq 'home' || $key eq 'page_up') {
			$at = 0;
			next;
		}
		if ($key eq 'end' || $key eq 'page_down') {
			$at = $#{$legal};
			next;
		}
		if ($key eq 'enter' || $key eq ' ') {
			$self->highlight({});
			$self->game->move($legal->[$at]);
			$self->redraw(1);
			return '';
		}
		if ($key =~ m/^[1-9]$/ && $key <= @{$legal}) {
			$at = $key - 1;
			next;
		}
		if ($key eq 'h') {
			my $hint = $self->hint;
			$notice = [$hint->{line}];
			$at = $self->index_of($legal, $hint->{move}) if $hint->{move};
			next;
		}
		if ($key eq '?') {
			$notice = $self->help_lines;
			next;
		}
		if ($key eq ':') {
			$self->highlight({});
			return $self->read_line(': ');
		}
		if ($KEY{$key}) {
			$self->highlight({});
			return $KEY{$key};
		}
		$notice = ['That key does nothing here. Press ? for the ones that do.'];
	}
}

sub index_of {
	my ($self, $legal, $move) = @_;
	my $notation = $move->coord_notation;
	for my $index (0 .. $#{$legal}) {
		return $index if $legal->[$index]->coord_notation eq $notation;
	}
	return 0;
}

sub show_choice {
	my ($self, $legal, $at, $notice) = @_;
	$self->highlight($self->move_marks($legal->[$at]));
	$self->clear;
	$self->say($_) for @{$self->board_lines}, '', @{$self->status_lines}, '',
		@{$self->choice_lines($legal, $at)};
	$self->say('') if $notice && @{$notice};
	$self->say($_) for @{$notice || []};
	$self->say('');
	$self->say($self->legend);
	$self->redraw(0);
	return $self;
}

sub move_marks {
	my ($self, $move) = @_;
	my %mark;
	$mark{$_} = 'cursor' for @{$move->path};
	$mark{$_} = 'captured' for @{$move->captures};
	$mark{$move->from} = 'from';
	$mark{$move->to} = 'to';
	return \%mark;
}

sub choice_lines {
	my ($self, $legal, $at) = @_;
	# the list is windowed so that a position with a lot of jumps in it cannot
	# push the board off the top of the screen
	my $window = 8;
	my $first = 0;
	if (@{$legal} > $window) {
		$first = $at - int($window / 2);
		$first = 0 if $first < 0;
		$first = @{$legal} - $window if $first > @{$legal} - $window;
	}
	my $last = $first + $window - 1;
	$last = $#{$legal} if $last > $#{$legal};

	my @lines;
	push @lines, sprintf '    %d further up', $first if $first;
	for my $index ($first .. $last) {
		my $move = $legal->[$index];
		my $line = sprintf '%2d. %-11s %s',
			$index + 1, $move->coord_notation, $self->describe($move);
		$line =~ s/\s+$//;
		push @lines, $index == $at
			? ' ' . $self->paint("> $line", '1;7')
			: "   $line";
	}
	push @lines, sprintf '    %d further down', $#{$legal} - $last
		if $last < $#{$legal};
	return \@lines;
}

sub describe {
	my ($self, $move) = @_;
	my @note;
	push @note, 'takes ' . join ', ',
		map { Game::Checkers::Squares::coord_name($_) } @{$move->captures}
		if @{$move->captures};
	push @note, 'crowns' if $move->promoted;
	return join ', ', @note;
}

sub legend {
	return 'up and down to choose, enter to play, h hint, u undo, f flip, '
		. 'q quit, : to type a command, ? for the rest';
}

sub read_line {
	my ($self, $prompt) = @_;
	my $out = $self->out;
	print {$out} defined $prompt ? $prompt : $self->game->turn . '> ';
	return $self->keyed_line if $self->raw;
	my $line = readline $self->in;
	return undef unless defined $line;
	chomp $line;
	return $line;
}

sub keyed_line {
	my ($self) = @_;
	my $out = $self->out;
	my $line = '';
	while (1) {
		my $key = $self->read_key;
		return undef if !defined $key || $key eq 'eof' || $key eq 'interrupt';
		last if $key eq 'enter';
		if ($key eq 'backspace') {
			next unless length $line;
			chop $line;
			# back over the character, blank it, and back over it again, which
			# is all a raw terminal will do for a rubbed out letter
			print {$out} "\b \b";
			next;
		}
		next if length $key > 1 || $key lt ' ';
		$line .= $key;
		print {$out} $key;
	}
	print {$out} "\n";
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
	# opens at index 3. A painted board drops the rule and the bars, because the
	# squares then meet, and widens the cell to five so a piece has a middle to
	# sit in. Either way the first file stays at index five and the pitch stays
	# the cell width, so the letters sit over the pieces
	my @lines = $self->colour
		? ('     ' . join('    ', @files[@cols]))
		: ('     ' . join('   ', @files[@cols]));
	push @lines, $rule unless $self->colour;
	for my $row (@rows) {
		my $line = $self->colour
			? sprintf('%2d ', 8 - $row)
			: sprintf('%2d |', 8 - $row);
		for my $col (@cols) {
			$line .= $self->cell($board, $row, $col);
			$line .= '|' unless $self->colour;
		}
		if (my $note = shift @aside) {
			$line .= '  ' . $note;
		}
		push @lines, $line;
		push @lines, $rule unless $self->colour;
	}
	return \@lines;
}

sub cell {
	my ($self, $board, $row, $col) = @_;
	my $square = Game::Checkers::Squares::square($row, $col);
	my $value = $square ? $board->at($square) : 0;
	my $piece = $value ? $PIECE{$value}{$self->ascii ? 'ascii' : 'wide'} : undef;

	# an empty playing square is dotted, because half the squares are not in the
	# game at all and nothing else unpainted says which half
	unless ($self->colour) {
		return '   ' unless $square;
		return ' ' . (defined $piece ? $piece : '.') . ' ';
	}

	my $mark = $square ? $self->highlight->{$square} : undef;
	$mark = $square ? 'dark' : 'light' unless $mark && $GROUND{$mark};
	my @code = ($GROUND{$mark});
	push @code, $INK{$value > 0 ? 'black' : 'white'} if defined $piece;
	return "\e[" . join(';', @code) . 'm  '
		. (defined $piece ? $piece : ' ') . "  \e[0m";
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
	return $self->set_picking($word) if $word eq 'pick' || $word eq 'type';
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

sub hint {
	my ($self) = @_;
	my $bot = $self->bot || Game::Checkers::Bot->new;
	my $move = $bot->choose($self->game);
	return { line => 'There is nothing to play.' } unless $move;
	my $score = $bot->last_search->{score};
	return {
		move => $move,
		line => sprintf('Try %s%s.', $move->coord_notation,
			defined $score ? sprintf(' (it scores that %+.2f)', $score / 100) : '')
	};
}

sub show_hint {
	my ($self) = @_;
	$self->say($self->hint->{line});
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

sub set_picking {
	my ($self, $word) = @_;
	if ($word eq 'type') {
		# raw mode goes with it, so the terminal does its own line editing again
		$self->leave_raw;
		$self->picking(0);
		$self->say('Type your moves. The command pick brings the keys back.');
		return 0;
	}
	return $self->say('This terminal cannot be read a key at a time.') && 0
		unless $self->enter_raw;
	$self->picking(1);
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

sub help_lines {
	my ($self) = @_;
	return [
		'A move is its squares: a3-b4 to slide, c3xe5xg7 to jump.',
		map { sprintf '  %-12s %s', $_, $COMMAND{$_} }
		sort { length $a <=> length $b || $a cmp $b } keys %COMMAND
	];
}

sub show_help {
	my ($self) = @_;
	$self->say($_) for @{$self->help_lines};
	return 0;
}

1;

__END__

=head1 NAME

Game::Checkers::Terminal - the game at a prompt

=head1 VERSION

Version 0.02

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

In colour the board is checkered instead, and then the grid and the dots both go:
the squares are painted light and dark, they meet, and the dark ones are the
played half. The cell widens from three columns to five so that a piece has a
middle to sit in, and the pitch of the files widens with it, so a piece is always
in the column of its own letter. Nothing but the colour changes, which is what
keeps the plain board exactly the board above.

The highlight is painted the same way. L</move_marks> names the squares a move
starts on, lands on, passes through and takes, and L</cell> paints each of those
its own colour, so the move under the cursor is shown on the board rather than
only written in the list.

=head2 Moves and the commands

A move is written as the squares it is on, read off the letters and numbers round
the edge: C<a3-b4> to slide and C<c3xe5xg7> to jump, with the whole path for a
multiple jump. Numeric notation is still accepted, because
L<Game::Checkers::Notation> reads both, but nothing here prints it: a saved game
is PDN, which is numeric, and the board is not.

A bare number plays that move from the C<moves> list. Everything else is a
command: C<help>, C<moves>, C<pick>, C<type>, C<hint>, C<board>, C<fen>, C<undo>,
C<save FILE>, C<load FILE>, C<level N>, C<flip>, C<ascii>, C<draw>, C<resign> and
C<quit>. An unknown word is answered and the prompt comes back: the loop never
dies on what somebody types, which is what L<Game::Checkers::Error> is for.

=head2 Picking a move instead of typing one

On a terminal there is nothing to type. The legal moves are listed under the
board, one is always under the cursor, and the up and down keys walk the list
while the board shows where that move goes. Enter plays it. C<h> asks the bot and
moves the cursor to what it suggests, C<u> takes a move back, C<f> flips the
board, C<q> stops, a digit jumps to that numbered move, and C<?> lists the
commands. C<:> gives a line to type, for the commands that need a word or a file
name, and the typed C<type> command stops the keys and C<pick> starts them again.

Resigning and offering a draw are deliberately not on a key. They are not
undoable and the keys for them would sit under the same fingers as the arrows.

This needs L<Term::ReadKey> to put the terminal into cbreak mode. Without it,
L</keys_available> is false, L</picking> is turned off in the constructor, and
moves are typed exactly as they always were. It is not in C<PREREQ_PM> for that
reason: the game plays without it.

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

=head2 highlight

Read and write hash reference, square number to the name of a colour:
C<from>, C<to>, C<captured> and C<cursor>. L</cell> paints a square its colour
instead of the light or dark it would have had. Only a painted board reads it, so
a plain one is drawn the same whatever is in here.

	$terminal->highlight({ 11 => 'from', 15 => 'to' });

=head2 picking

Read and write boolean: whether a move is chosen with the keys rather than typed.
Defaults to L</interactive>, and is turned off in the constructor if
L</keys_available> is false, so asking for it on something that cannot do it is
not an error.

	$terminal->picking;

=head2 raw

Read and write boolean: whether the terminal is in cbreak mode. L</enter_raw>
sets it and L</leave_raw> clears it. Everything that reads a key tests this
rather than L</picking>, because the typed line reader is the one to use until
the mode is actually changed.

	$terminal->raw;

=head2 keysource

Read and write code reference, called with the wait flag L</read_char> was given
and returning one character or undef. Set it to take keys from somewhere that is
not a terminal, which is how the suite plays a whole game by key with no terminal
to play it on. Left unset, L<Term::ReadKey> reads L</in>.

	$terminal->keysource(sub { shift @character });

=head2 pending

Read and write array reference of characters read but not used yet, which is how
an escape that turns out not to begin a sequence gives back the keystroke behind
it. Not for a caller to set.

	$terminal->pending;

=head1 FUNCTIONS

=head2 start

Runs the game to its end and returns the result. It is the one that owns the
terminal mode: it enters cbreak if L</picking> is on, puts the terminal back
whatever happens, L</turns> dying included, and catches an interrupt for just
long enough to restore it before raising it again. A shell is never left in raw
mode.

	my $result = $terminal->start;

=head2 turns

The loop itself, one turn an iteration: draw if the board changed, stop on a
result, let the bot move if it is the bot's turn, and otherwise take a move from
the keys or the prompt. L</start> is what callers want; this is separate so that
restoring the terminal can wrap it.

	$terminal->turns;

=head2 keys_available

Whether a move can be picked with the keys here: true when L</keysource> is set,
or when L</in> is a terminal and L<Term::ReadKey> can be loaded.

	$terminal->keys_available or print "type your moves\n";

=head2 enter_raw

Puts the terminal into cbreak mode, so a key arrives as it is pressed and is not
echoed. Returns the object, or undef if it cannot be done, which is the answer
L</start> turns L</picking> off on. Safe to call twice. Signals are left alone,
so an interrupt is still an interrupt.

=head2 leave_raw

Puts the terminal back and returns the object. Safe to call twice, and safe when
L</enter_raw> was never called.

=head2 read_char

	my $char = $terminal->read_char(1);

One character: whatever L</pending> is holding, else L</keysource> if it is set,
else L<Term::ReadKey>. With a false argument it does not block, and returns undef
if nothing is there after a moment, which is how the end of an escape sequence is
found.

=head2 read_key

One keystroke, as the character itself or, for a key that is not one character, a
name: C<up>, C<down>, C<left>, C<right>, C<home>, C<end>, C<page_up>,
C<page_down>, C<enter>, C<tab>, C<backspace>, C<escape>, C<interrupt> and C<eof>.
A name is always longer than one character, so

	my $named = length $key > 1;

is the test. Returns undef at the end of the input.

=head2 read_sequence

Reads the rest of an escape sequence, the escape having been read already, and
returns its name, or C<escape> for what is not a sequence this knows. A character
that turns out not to belong to one is put back on L</pending> rather than lost.

=head2 pick

Draws the board, the move list and the cursor, and reads keys until something
comes of it. Returns the empty string when a move was chosen, which it plays
itself; the word of a command for L</command> to run; a typed line when C<:> was
pressed; or undef at the end of the input.

	my $line = $terminal->pick;

=head2 index_of

Where a move sits in a list of moves, by its notation, or 0 if it is not in it.
Used to put the cursor on the move a hint names.

	$terminal->index_of($legal, $move);

=head2 show_choice

Draws one frame of L</pick>: the board with the chosen move marked on it, the
status block, the list, anything in the notice, and the keys.

	$terminal->show_choice($legal, 0, ['Try f6-e5.']);

=head2 move_marks

The hash L</highlight> takes for one move: where it leaves, where it lands, the
squares it passes through on a multiple jump, and the pieces it takes.

	$terminal->highlight($terminal->move_marks($move));

=head2 choice_lines

The move list as lines, the chosen one marked and in reverse video, windowed to
eight at a time so that a position full of jumps cannot push the board off the
top of the screen. The lines above and below are counted rather than drawn.

	$terminal->choice_lines($legal, 2);

=head2 describe

What a move does, beyond where it goes: what it takes and whether it crowns, or
the empty string for a plain step.

	$terminal->describe($move);

=head2 legend

The one line of keys printed under the list.

=head2 keyed_line

A typed line read a key at a time, echoed as it is typed, with backspace rubbing
a character out. Used instead of C<readline> while the terminal is in cbreak
mode, because the terminal is not assembling lines then. Returns undef on an
interrupt or the end of the input.

=head2 hint

What the bot would play, as a hash reference: C<line> to print and C<move>, the
move itself, so a caller can put the cursor on it. C<move> is absent when there
is nothing to play.

	my $hint = $terminal->hint;

=head2 set_picking

Runs the C<pick> and C<type> commands: turns the keys on, or off and the terminal
back with them.

	$terminal->set_picking('type');

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

One square of the board, drawn: three characters on a plain board, and on a
painted one five, coloured by whether the square is played on and by whatever
L</highlight> says about it.

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

=head2 help_lines

The help as lines rather than printed, so that L</pick> can show it without
printing under a screen it is about to draw again.

	$terminal->help_lines;

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
