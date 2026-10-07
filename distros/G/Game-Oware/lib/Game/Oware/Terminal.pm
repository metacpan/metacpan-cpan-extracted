package Game::Oware::Terminal;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Oware;
use Game::Oware::Board;
use Game::Oware::Bot;
use Game::Oware::Error;
use Game::Oware::Notation;
use Game::Oware::Rules;
use Game::Oware::Scoring;
use Game::Oware::Variant ();

our $VERSION = '0.02';

# The glyph tables. NOTE: this file is NOT under `use utf8`, so the wide
# glyphs are byte strings and `length` on anything built from them is a byte
# count rather than a column count. Every cell below is therefore padded from
# a COUNT the caller already has, never from length(), and nothing here is
# ever passed to sprintf's %Ns. Get that wrong and the board shears by two
# columns per seed on a UTF-8 terminal and by none on a C-locale one.
my %GLYPH = (
	wide => {
		h    => '─', v  => '│',
		tl   => '╭', tr => '╮', bl => '╰', br => '╯',
		td   => '┬', tu => '┴', lt => '├', rt => '┤', tx => '┼',
		seed => '•', more => '…',
	},
	ascii => {
		h    => '-', v  => '|',
		tl   => '+', tr => '+', bl => '+', br => '+',
		td   => '+', tu => '+', lt => '+', rt => '+', tx => '+',
		seed => '.', more => '>',
	},
);

my $STORE_W  = 4;
my $HOUSE_W  = 6;
my $SEED_CAP = 4;

my %SGR = (
	frame     => '2',
	letter    => '36',
	mine      => '1;36',
	store     => '36',
	storemine => '1;36',
	empty     => '2',
	seed      => '33',
	risk      => '31',
	loaded    => '1;33',
	emptied   => '2',
	gained    => '32',
	landed    => '1;32',
	captured  => '7;31',
	forfeited => '1;33',
	prompt    => '1',
	cursor    => '1;7',
);

my @TIMES = ('', 'once', 'twice', 'for the third time', 'for the fourth time');

# Term::ReadKey hands over one character at a time and leaves an escape
# sequence as the characters it is made of, so the arrow keys are named here.
# Same tables as Game::Checkers::Terminal, on purpose: two of this author's
# terminals reading the same keyboard should not disagree about what Home is.
my %SEQUENCE = (
	'A'  => 'up',
	'B'  => 'down',
	'C'  => 'right',
	'D'  => 'left',
	'H'  => 'home',
	'F'  => 'end',
	'1~' => 'home',
	'4~' => 'end',
	'5~' => 'page_up',
	'6~' => 'page_down',
	'7~' => 'home',
	'8~' => 'end',
);

my %CONTROL = (
	"\r"   => 'enter',
	"\n"   => 'enter',
	"\t"   => 'tab',
	"\x7f" => 'backspace',
	"\x08" => 'backspace',
	"\x03" => 'interrupt',
	"\x04" => 'eof',
);

has in => (
	is      => 'rw',
	isa     => Any,
	default => sub { \*STDIN }
);

has out => (
	is      => 'rw',
	isa     => Any,
	default => sub { \*STDOUT }
);

has level => (
	is      => 'ro',
	isa     => Int,
	default => 3
);

has variant => (
	is      => 'ro',
	isa     => Str,
	default => 'abapa'
);

has seat => (
	is      => 'ro',
	isa     => Str,
	default => 'p1'
);

has seed => (
	is      => 'ro',
	isa     => Str,
	default => ''
);

has quiet => (
	is      => 'ro',
	isa     => Int,
	default => 0
);

has ascii => (
	is      => 'ro',
	isa     => Int,
	default => 0
);

has game => (
	is  => 'rw',
	isa => Object
);

has bot => (
	is  => 'rw',
	isa => Object
);

has raw => (
	is      => 'rw',
	isa     => Int,
	default => 0
);

has keysource => (is => 'rw');

has recent => (
	is      => 'rw',
	isa     => ArrayRef,
	default => []
);

has pending => (
	is      => 'rw',
	isa     => ArrayRef,
	default => []
);

has _wants_ansi => (
	is       => 'ro',
	init_arg => 'ansi',
	private  => 1
);

has _wants_progress => (
	is       => 'ro',
	init_arg => 'progress',
	private  => 1
);

has _wants_interactive => (
	is       => 'ro',
	init_arg => 'interactive',
	private  => 1
);

has _wants_picking => (
	is       => 'rw',
	init_arg => 'picking',
	private  => 1
);

sub BUILD {
	my ($self) = @_;

	Game::Oware::Variant::check_variant($self->variant);

	die 'Game::Oware::Terminal: seat must be p1 or p2, not ' . $self->seat
		unless $self->seat eq 'p1' || $self->seat eq 'p2';

	Game::Oware::Bot->setting_for($self->level);

	$self->game(Game::Oware->new(
		variant => $self->variant,
		seed    => $self->seed,
	)) unless $self->game;

	$self->bot(Game::Oware::Bot->new(
		level => $self->level,
		seed  => $self->seed . ':bot',
	)) unless $self->bot;

	return $self;
}

sub ansi {
	my ($self) = @_;
	return 0 if defined $ENV{NO_COLOR} && length $ENV{NO_COLOR};
	return $self->_wants_ansi ? 1 : 0 if defined $self->_wants_ansi;
	return -t $self->out ? 1 : 0;
}

sub interactive {
	my ($self) = @_;
	return $self->_wants_interactive ? 1 : 0
		if defined $self->_wants_interactive;
	return -t $self->out ? 1 : 0;
}

sub progress {
	my ($self) = @_;
	return 0 if $self->quiet;
	return $self->_wants_progress ? 1 : 0 if defined $self->_wants_progress;
	return $self->interactive;
}

# Read AND write: the `type` key turns picking off for the rest of the game,
# and `pick` turns it back on. Not a plain property because the default has to
# be computed from `in`, which the suite sets after construction.
sub picking {
	my ($self, @set) = @_;
	$self->_wants_picking($set[0] ? 1 : 0) if @set;
	return 0 if $self->quiet;
	return $self->_wants_picking ? 1 : 0 if defined $self->_wants_picking;
	return $self->keys_available;
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

	# cbreak rather than raw, so an interrupt stays an interrupt instead of
	# becoming a key this loop has to know about.
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

	# Nothing there yet, and the rest of an escape sequence is worth one short
	# wait before the escape is taken for the key of that name.
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

	# A pressed escape key that happens to be followed by a real keystroke must
	# not eat it, so what is not the opening of a sequence goes back.
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

sub rows_for {
	my ($self, $seat) = @_;
	return $seat eq 'p1'
		? ([ reverse 6 .. 11 ], [ 0 .. 5 ])
		: ([ reverse 0 .. 5 ],  [ 6 .. 11 ]);
}

sub marks_for {
	my ($self, $move) = @_;
	return {} unless $move;

	my %mark;
	my $house = $move->house;
	$mark{$house} = '-';

	# The sowing walk, so the mark on a house of twelve or more shows the
	# origin staying empty while the hand goes past it.
	my $i    = $house;
	my $hand = $move->sown;
	while ($hand) {
		$i = ($i + 1) % Game::Oware::Board->HOUSES;
		next if $i == $house;
		$mark{$i} = '+';
		$hand--;
	}

	$mark{ $move->last } = '*';
	$mark{$_} = '!' for @{ $move->forfeited };
	$mark{$_} = 'x' for @{ $move->captured };

	return \%mark;
}

sub board_text {
	my ($self, $from, $seat, $marks) = @_;
	$seat  ||= $self->seat;
	$marks ||= {};

	# A game or a bare board, because the picker draws a position no game has
	# been in: the one a candidate move would produce.
	my $board = ref $from eq 'ARRAY' ? $from : $from->board;
	my $captured = Game::Oware::Scoring->captured($board);

	my ($top, $bottom) = $self->rows_for($seat);
	my $them = Game::Oware::Board->other($seat);
	my $g = $self->_glyphs;

	my $v     = $self->_paint($g->{v}, 'frame');
	my $house = $g->{h} x $HOUSE_W;
	my $store = $g->{h} x $STORE_W;

	my @left  = $self->_store_cell($them, $captured->{$them}, 'store');
	my @right = $self->_store_cell($seat, $captured->{$seat}, 'storemine');

	my @out;
	push @out, $self->_letters($top, 'letter');
	push @out, $self->_paint($g->{tl} . $store . $g->{td}
		. join($g->{td}, ($house) x 6) . $g->{td} . $store . $g->{tr}, 'frame');
	push @out, $v . $left[0] . $v . $self->_seeds($board, $top, $marks)
		. $v . $right[0] . $v;
	push @out, $v . $left[1] . $v . $self->_counts($board, $top, $marks)
		. $v . $right[1] . $v;
	push @out, $v . $left[2]
		. $self->_paint($g->{lt} . join($g->{tx}, ($house) x 6) . $g->{rt}, 'frame')
		. $right[2] . $v;
	push @out, $v . $left[3] . $v . $self->_counts($board, $bottom, $marks)
		. $v . $right[3] . $v;
	push @out, $v . $left[4] . $v . $self->_seeds($board, $bottom, $marks)
		. $v . $right[4] . $v;
	push @out, $self->_paint($g->{bl} . $store . $g->{tu}
		. join($g->{tu}, ($house) x 6) . $g->{tu} . $store . $g->{br}, 'frame');
	push @out, $self->_letters($bottom, 'mine');

	return @out;
}

sub preview {
	my ($self, $house) = @_;
	return Game::Oware::Rules->resolve(
		$self->game->board, $house, $self->seat, $self->variant);
}

sub describe {
	my ($self, $house) = @_;

	my (undef, $move) = $self->preview($house);
	my $them = Game::Oware::Board->other($self->seat);

	my @note = ('sows ' . $move->sown);

	push @note, 'right round, skipping '
		. Game::Oware::Notation->letter_of($house)
		if $move->sown >= 12;

	if (@{ $move->forfeited }) {
		push @note, "would take every seed $them has, so takes none";
	}
	elsif (@{ $move->captured }) {
		push @note, 'captures ' . $move->taken . ' from ' . join ', ',
			map { Game::Oware::Notation->letter_of($_) } @{ $move->captured };
		push @note, "and the rest of the board goes to $them" if $move->slammed;
	}

	return join ', ', @note;
}

sub choice_lines {
	my ($self, $legal, $at) = @_;

	my @lines;
	for my $index (0 .. $#$legal) {
		my $line = Game::Oware::Notation->letter_of($legal->[$index])
			. '  ' . $self->describe($legal->[$index]);
		$line =~ s/\s+\z//;
		push @lines, $index == $at
			? '  ' . $self->_paint("> $line", 'cursor')
			: "    $line";
	}

	return @lines;
}

sub legend {
	my ($self) = @_;
	return (
		'arrows to choose, enter to sow, a letter to jump to that house',
		'v for the board as it stands, ? for the rules, t to type, q to quit',
	);
}

sub pick {
	my ($self) = @_;

	my $game  = $self->game;
	my $seat  = $self->seat;
	my @legal = @{ $game->legal($seat) };
	return 0 unless @legal;

	# Asked for and not available: fall back to typing for good rather than
	# failing the same way on every turn of the game.
	unless ($self->enter_raw) {
		$self->picking(0);
		return $self->_typed_turn;
	}

	my $at = 0;
	my $live = 0;
	my @notice;

	while (1) {
		$self->_show_choice(\@legal, $at, \@notice, $live);
		@notice = ();

		my $key = $self->read_key;

		if (!defined $key || $key eq 'eof' || $key eq 'interrupt' || $key eq 'q') {
			$self->leave_raw;
			return 0;
		}

		if ($key eq 'up' || $key eq 'left') {
			$at = ($at - 1) % @legal;
			next;
		}
		if ($key eq 'down' || $key eq 'right' || $key eq 'tab') {
			$at = ($at + 1) % @legal;
			next;
		}
		if ($key eq 'home' || $key eq 'page_up') { $at = 0;       next }
		if ($key eq 'end'  || $key eq 'page_down') { $at = $#legal; next }

		if ($key eq 'enter' || $key eq ' ') {
			$self->leave_raw;
			my $move = $game->play($seat, $legal[$at]);
			$self->_after_ply($move, $seat);
			return 1;
		}

		if ($key =~ /\A[1-9]\z/ && $key <= @legal) {
			$at = $key - 1;
			next;
		}

		# Not `b`, which is a house. See `command`.
		if ($key eq 'v') {
			$live = !$live;
			next;
		}

		# A HOUSE LETTER IS STILL THE INTERFACE. The letters are printed on the
		# board and against every option, so typing one has to land on it, and
		# typing one that is not on the list has to say why it is not.
		my $house = eval { Game::Oware::Notation->index_of($key) };
		if (defined $house) {
			my ($found) = grep { $legal[$_] == $house } 0 .. $#legal;
			if (defined $found) { $at = $found; next }
			@notice = (ucfirst($self->_why_not($house, $seat)) . '.');
			next;
		}

		if ($key eq '?') { @notice = $self->_help_lines; next }

		if ($key eq 't' || $key eq ':') {
			$self->leave_raw;
			$self->picking(0) if $key eq 't';
			return $self->_typed_turn;
		}

		@notice = ('That key does nothing here. Press ? for the ones that do.');
	}
}

sub status_text {
	my ($self, $from) = @_;
	$from ||= $self->game;

	my $board = ref $from eq 'ARRAY' ? $from : $from->board;
	my $play = Game::Oware::Board->seeds_on_side($board, 'p1')
		+ Game::Oware::Board->seeds_on_side($board, 'p2');

	return ' ' x ($STORE_W + 4) . $self->_paint($play . ' in play, '
		. Game::Oware::Variant::target($self->variant) . ' wins', 'frame');
}

sub start {
	my ($self) = @_;

	$self->_intro unless $self->quiet;

	my $game = $self->game;
	$self->_show unless $self->picking;

	while ($game->status eq 'active') {
		my ($turn) = $game->waiting_on;
		last unless defined $turn;

		if ($turn eq $self->seat) {
			last unless $self->_human_turn;
		}
		else {
			last unless $self->_bot_turn($turn);
		}
	}

	$self->_finish;

	return $game->result;
}

sub command {
	my ($self, $line) = @_;

	return 'quit' unless defined $line;
	$line =~ s/\A\s+|\s+\z//g;

	return 'again' unless length $line;
	return 'quit' if $line =~ /\A(?:q|quit|exit)\z/i;
	return 'help' if $line =~ /\A(?:\?|h|help)\z/i;
	return 'board' if $line =~ /\Aboard\z/i;
	return 'pick' if $line =~ /\Apick\z/i;
	return 'type' if $line =~ /\Atype\z/i;

	return $line;
}

sub _glyphs { return $GLYPH{ $_[0]->ascii ? 'ascii' : 'wide' } }

sub _say {
	my ($self, @lines) = @_;
	my $out = $self->out;
	print {$out} "$_\n" for @lines;
	return;
}

# A partial line, so the handle has to be flushed or a prompt sits in the
# buffer while the bot thinks and the player stares at nothing.
sub _print {
	my ($self, $text) = @_;
	my $out = $self->out;
	print {$out} $text;
	my $was = select $out;
	$| = 1;
	select $was;
	return;
}

# An undef key is "leave it alone", which is what an ordinary house count
# wants: paint every cell and the marked ones stop standing out. Only a call
# with no key at all takes the default.
sub _paint {
	my ($self, $text, $key) = @_;
	return $text unless $self->ansi;
	$key = 'prompt' if @_ < 3;
	return $text unless defined $key && defined $SGR{$key};
	return "\e[" . $SGR{$key} . 'm' . $text . "\e[0m";
}

sub _letters {
	my ($self, $houses, $key) = @_;
	my $row = ' ' x ($STORE_W + 4);
	$row .= $self->_paint(Game::Oware::Notation->letter_of($_), $key) . ' ' x 6
		for @$houses;
	$row =~ s/\s+\z//;
	return $row;
}

sub _store_cell {
	my ($self, $who, $count, $key) = @_;
	my $blank = ' ' x $STORE_W;
	return (
		$blank,
		$self->_paint(sprintf(' %-2s ', $who), $key),
		$self->_paint(sprintf(' %2d ', $count), $key),
		$blank,
		$blank,
	);
}

sub _seeds {
	my ($self, $board, $houses, $marks) = @_;
	my $g = $self->_glyphs;
	return join $self->_paint($g->{v}, 'frame'),
		map { $self->_paint($self->_seed_text($board->[$_]),
			$self->_seed_key($board->[$_], $marks->{$_})) } @$houses;
}

sub _counts {
	my ($self, $board, $houses, $marks) = @_;
	my $g = $self->_glyphs;
	return join $self->_paint($g->{v}, 'frame'),
		map { $self->_paint(
			sprintf(' %s %2d ', defined $marks->{$_} ? $marks->{$_} : ' ', $board->[$_]),
			$self->_count_key($board->[$_], $marks->{$_})) } @$houses;
}

sub _seed_text {
	my ($self, $count) = @_;
	return ' ' x $HOUSE_W unless $count;

	# The overflow glyph is NOT a `+`: that is the mark for a house that gained
	# a seed, and the two sat one row apart meaning different things.
	my $g = $self->_glyphs;
	return ' ' . ($g->{seed} x $SEED_CAP) . $g->{more} if $count > $SEED_CAP;

	my $pad = int(($HOUSE_W - $count) / 2);
	return (' ' x $pad) . ($g->{seed} x $count)
		. (' ' x ($HOUSE_W - $pad - $count));
}

sub _seed_key {
	my ($self, $count, $mark) = @_;
	return 'captured'  if defined $mark && $mark eq 'x';
	return 'forfeited' if defined $mark && $mark eq '!';
	return 'empty'     unless $count;
	return 'risk'      if $count <= 2;
	return 'loaded'    if $count >= 12;
	return 'seed';
}

sub _count_key {
	my ($self, $count, $mark) = @_;

	if (defined $mark) {
		return 'captured'  if $mark eq 'x';
		return 'forfeited' if $mark eq '!';
		return 'landed'    if $mark eq '*';
		return 'gained'    if $mark eq '+';
		return 'emptied'   if $mark eq '-';
	}

	return 'empty'  unless $count;
	return 'risk'   if $count <= 2;
	return 'loaded' if $count >= 12;
	return undef;
}

sub _show {
	my ($self, $move) = @_;
	return if $self->quiet;

	my $game = $self->game;
	my $result = $game->result;

	# A sweep rewrote the board after the move, so the move's marks would be
	# pointing at counts that are no longer the ones it produced.
	my $swept = $result
		&& ($result->reason eq 'cycle' || $result->reason eq 'no_feed');

	$self->_say('',
		$self->board_text($game, $self->seat, $swept ? {} : $self->marks_for($move)),
		$self->status_text($game));

	return;
}

sub _legend {
	my ($self) = @_;
	return (
		'  ' . $self->_paint('-', 'emptied') . ' emptied   '
			. $self->_paint('+', 'gained') . ' gained a seed   '
			. $self->_paint('*', 'landed') . ' the last seed landed',
		'  ' . $self->_paint('x', 'captured') . ' captured   '
			. $self->_paint('!', 'forfeited') . ' capture forfeited',
	);
}

sub _intro {
	my ($self) = @_;
	$self->_say(
		'Oware, ' . $self->variant . ' rules. You are ' . $self->seat . '.',
		'Your six houses are the bottom row and your store is on the right.',
		'Sow from one of them by typing its letter.',
		'',
		'The marks say what the last move did:',
		$self->_legend,
		'',
		'Type help for the rules that surprise people, or quit to stop.',
	);
	return;
}

sub _help {
	my ($self) = @_;
	$self->_say($self->_help_lines);
	return;
}

sub _help_lines {
	my ($self) = @_;
	return (
		'Take every seed from one of your houses and drop one in each house',
		'counter-clockwise, skipping the house you took them from.',
		'',
		'If your last seed brings one of your opponent houses to exactly two or',
		'three, you capture it, and the walk continues backwards while that',
		'holds. Twenty-five seeds wins. Twenty-four each is a draw.',
		'',
		'Three rules surprise people:',
		'  - a move that would take EVERY seed your opponent has takes none;',
		'  - if your opponent has no seeds you must play a house that reaches',
		'    them, and if you cannot, you take your own seeds and the game ends;',
		'  - a game that will not end is stopped by a house rule, not a rule of',
		'    Oware. See the note when it happens.',
		'',
		'The marks on the board:',
		$self->_legend,
		'',
		'A house of one or two seeds is drawn in red, because that is what an',
		'opponent captures by bringing it to two or three. A house of twelve or',
		'more is drawn bright, because it laps the board.',
	);
}

sub _prompt_for {
	my ($self, $seat) = @_;

	my $game = $self->game;
	my @legal = @{ $game->legal($seat) };
	my @sowable = Game::Oware::Rules->sowable($game->board, $seat);

	if (@sowable > @legal) {
		my $them = Game::Oware::Board->other($seat);
		$self->_say('', $them . ' has no seeds, so you must play a house that'
			. ' reaches them: '
			. join(' ', map { Game::Oware::Notation->letter_of($_) } @legal));
	}

	return join ' ', map { Game::Oware::Notation->letter_of($_) } @legal;
}

sub _human_turn {
	my ($self) = @_;
	return $self->picking ? $self->pick : $self->_typed_turn;
}

# The picker redraws the whole screen on every keystroke, so it clears first;
# scrolling six options past a nine line board is unreadable. Nothing here is
# an escape the renderer owns, so it is gated on being interactive rather than
# on `ansi`: a player with NO_COLOR set still wants a usable picker.
sub _clear {
	my ($self) = @_;
	return unless $self->interactive;
	$self->_print("\e[2J\e[H");
	return;
}

sub _show_choice {
	my ($self, $legal, $at, $notice, $live) = @_;

	my $game = $self->game;
	my $seat = $self->seat;

	$self->_clear;

	# THE ROUND SO FAR, every frame. The picker clears the screen on every
	# keystroke, so the narration printed when a move was played has already
	# gone by the time there is anything to choose. Both plies, not just the
	# opponent's: a player who cannot see their own capture, or what it was
	# answered with, is choosing in the dark.
	my $recent = $self->recent;
	$self->_say($self->_narrate_lines($_->{move}, $_->{seat}, 1))
		for @$recent;
	$self->_say('') if @$recent;

	# THE BOARD DRAWN HERE IS THE ONE THE MOVE WOULD PRODUCE, not the one on
	# the table with a path drawn over it. The first version did the latter,
	# the way Game::Checkers highlights a jump, and it was wrong for this
	# game: the marks said where the seeds went while every count was still
	# the count from before they moved, so the cursor house read `- 1` for a
	# house it had just emptied. Here a capture shows the store going up.
	#
	# `v` swaps it for the position as it stands, carrying the opponent's own
	# marks, because a preview is not a substitute for the board you are
	# actually playing from.
	my ($board, $marks, $title);
	if ($live) {
		$board = $game->board;
		$marks = @$recent ? $self->marks_for($recent->[-1]{move}) : {};
		$title = '    as it stands:';
	}
	else {
		my $move;
		($board, $move) = $self->preview($legal->[$at]);
		$marks = $self->marks_for($move);
		$title = '    if you sow '
			. Game::Oware::Notation->letter_of($legal->[$at]) . ':';
	}

	$self->_say(
		$title,
		$self->board_text($board, $seat, $marks),
		$self->status_text($board),
		'',
	);

	# The list holds only legal moves, so a player looking for a house the
	# feeding rule took away has nothing to read. Say it where the list is.
	my @sowable = Game::Oware::Rules->sowable($game->board, $seat);
	$self->_say(Game::Oware::Board->other($seat) . ' has no seeds, so only a'
		. ' house that reaches them can be played:', '')
		if @sowable > @$legal;

	$self->_say($self->choice_lines($legal, $at));
	$self->_say('', @$notice) if @$notice;
	$self->_say('', map { $self->_paint($_, 'frame') } $self->legend);

	return;
}

sub _why_not {
	my ($self, $house, $seat) = @_;
	my $flag = Game::Oware::Board->owner_of($house) ne $seat ? 'not_your_house'
		: !$self->game->board->[$house]                      ? 'empty_house'
		:                                                      'must_feed';
	return Game::Oware::Error->throw($flag)->message;
}

sub _typed_turn {
	my ($self) = @_;

	my $game = $self->game;
	my $seat = $self->seat;
	my $in   = $self->in;

	my $legal = $self->_prompt_for($seat);

	while (1) {
		# The newline belongs to the PROMPT, not to whatever answers it. On a
		# terminal the echoed Return supplies one; on a pipe it does not, and
		# the first version of this loop printed every refusal, every help
		# screen and every redrawn board onto the prompt's own line.
		$self->_print("\n" . $self->_paint('your move', 'prompt') . " [$legal] > ");

		my $line = <$in>;
		my $command = $self->command($line);

		return 0 if $command eq 'quit';

		if ($command eq 'help')  { $self->_say(''); $self->_help; next }
		if ($command eq 'again') { next }
		if ($command eq 'board') { $self->_show; next }
		if ($command eq 'type')  { $self->picking(0); next }

		if ($command eq 'pick') {
			$self->picking(1);
			return $self->pick if $self->keys_available;
			$self->picking(0);
			$self->_say('', 'The keys are not available here, so this game is'
				. ' typed. Term::ReadKey and a terminal are what it takes.');
			next;
		}

		my $house = eval { Game::Oware::Notation->index_of($command) };
		if (!defined $house) {
			$self->_say('', 'That is not a house. Type one of: ' . $legal);
			next;
		}

		my $out_of = $game->play($seat, $house);
		if (ref $out_of && $out_of->isa('Game::Oware::Error')) {
			$self->_say('', ucfirst($out_of->message) . '.');
			next;
		}

		$self->_after_ply($out_of, $seat);
		return 1;
	}
}

sub _bot_turn {
	my ($self, $seat) = @_;

	my $game = $self->game;

	$self->_thinking($seat);
	my $house = $self->bot->choose($game, $seat);
	$self->_thought;

	# Unreachable while the engine ends a game the moment a seat has no legal
	# move. A `return` here instead would hand control back to a loop whose
	# condition has not changed, so the program would spin in silence.
	unless (defined $house) {
		$self->_say('', "$seat has no move, so the game cannot go on.")
			unless $self->quiet;
		return 0;
	}

	my $move = $game->play($seat, $house);
	$self->_after_ply($move, $seat);

	return 1;
}

sub _thinking {
	my ($self, $seat) = @_;
	return unless $self->progress;
	$self->_print($self->_paint("$seat is thinking", 'frame'));
	return;
}

sub _thought {
	my ($self) = @_;
	return unless $self->progress;
	$self->_print("\r" . (' ' x 20) . "\r");
	return;
}

# Everything one ply owes the screen, in one place, because the two front ends
# want opposite things from it. The typed game scrolls, so it narrates and
# redraws; the picker owns the screen and reprints both plies in its own header
# on every keystroke, so anything drawn here would be a flash and nothing more.
sub _after_ply {
	my ($self, $move, $seat) = @_;

	# Recorded whether or not it is printed. The picker clears the screen on
	# every keystroke, so this is the only surviving copy of the round, and a
	# player who cannot see their own capture or the reply to it is choosing
	# in the dark.
	my $recent = $self->recent;
	push @$recent, { move => $move, seat => $seat };
	shift @$recent while @$recent > 2;

	return if $self->quiet;
	return if $self->picking && $self->game->status eq 'active';

	$self->_say('', $self->_narrate_lines($move, $seat));
	$self->_show($move);

	return;
}

sub _narrate_lines {
	my ($self, $move, $seat, $past) = @_;

	my $name = Game::Oware::Notation->letter_of($move->house);
	my $them = Game::Oware::Board->other($seat);
	my $sows = $past ? 'sowed' : 'sows';

	my @lines = ($self->_paint("$seat $sows $name.", 'prompt'));

	push @lines, '  The sow went right round, so it skipped '
		. "$name on the way past."
		if $move->sown >= 12;

	if (@{ $move->forfeited }) {
		my $houses = join ', ',
			map { Game::Oware::Notation->letter_of($_) } @{ $move->forfeited };
		push @lines, "  That would have taken every seed $them has, from "
			. "$houses, so it takes none and they stay on the board.";
	}
	elsif (@{ $move->captured }) {
		my $houses = join ', ',
			map { Game::Oware::Notation->letter_of($_) } @{ $move->captured };
		push @lines, '  It captures ' . $move->taken . " seeds, from $houses.";
		push @lines, '  Every seed left on the board goes to ' . $them . '.'
			if $move->slammed;
	}

	return @lines;
}

sub _finish {
	my ($self) = @_;

	my $game = $self->game;
	my $result = $game->result;

	unless ($result) {
		$self->_say('', 'Stopped. Nobody won.') unless $self->quiet;
		return;
	}

	my $reason = $result->reason;

	if ($reason eq 'no_feed' && !$self->quiet) {
		my ($swept) = map { $_->{payload}{p} }
			grep { $_->{kind} eq 'sweep' } @{ $game->events };
		$self->_say('', "$swept had no move that could give the other side seeds,"
			. ' so it took every seed in its own territory and the game ended.');
	}
	elsif ($reason eq 'cycle') {
		# NOT narration, so quiet does not silence it. A game ended by a rule
		# that no book contains has to say so however terse the output is.
		my ($cycle) = grep { $_->{kind} eq 'cycle' } @{ $game->events };
		my $times = $cycle->{payload}{times}
			|| Game::Oware::Variant::repetition_limit($self->variant);
		my $why = $cycle->{payload}{why} eq 'repetition'
			? 'the same position came round ' . _times($times)
			: $cycle->{payload}{plies} . ' moves passed with nothing captured';
		$self->_say('', "This game was going nowhere: $why.",
			'So each side took the seeds on its own half.',
			'THAT IS A HOUSE RULE AND NOT A RULE OF OWARE. The published rule',
			'ends a cycle when both players agree, which is not something this',
			'program can ask you.');
	}

	$self->_say('', $self->_paint($result->stringify . '.', 'prompt'));

	return;
}

sub _times {
	my ($count) = @_;
	return $TIMES[$count] if $count && $count <= $#TIMES;
	return "for the ${count}th time";
}

1;

__END__

=head1 NAME

Game::Oware::Terminal - a playable game on two filehandles

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Game::Oware::Terminal;

    my $terminal = Game::Oware::Terminal->new(level => 3, seat => 'p1');
    my $result = $terminal->start;

=head1 DESCRIPTION

=head2 It is separate from the engine on purpose

L<Game::Cribbage> is about a thousand lines of escape codes in its B<top level
namespace module>, so that only its C<::Board> was ever reusable by anything
else. This is a consumer of the engine exactly as a web adapter would be, and
the suite asserts that loading L<Game::Oware> does not pull this in.

=head2 in and out are properties

Defaulting to C<STDIN> and C<STDOUT>. That is what makes a terminal testable:
the suite drives a whole game in process against in-memory handles, with no
pipe, no fork, and no subprocess writing into the TAP stream.

=head2 start returns, and never exits

A module that calls C<exit> cannot be tested and cannot be embedded. The exit
status belongs to F<bin/oware>, which is the only part that knows it is a
program.

=head2 Every option is validated in the constructor

An unknown variant, an unknown level or a seat that does not exist all die from
C<BUILD>, before a game is built and before anything is printed.
C<Game::Reversi> validated its variant three calls deeper and shipped a
C<--variant draughts> that died with a raw Perl message and an exit status of
255.

=head2 The board is drawn as a board

A store at each end, flanking the two rows of six houses, which is the shape of
the thing on the table. The viewer's own store is the right-hand one, as it is
when you sit down to play.

Each house carries its seed count B<and> a cluster of seeds, because neither
alone is enough. A pile of dots is unreadable past four, so the count is what
you play from; but a bare grid of numbers gives no sense of a board at all, and
the cluster is what makes a row of ones and twos look as thin as it is. Past
C<$SEED_CAP> the cluster stops and takes a C<+>, because the number is right
there and five dots against twenty-five dots would be a lie either way.

=head2 Counts, not glyphs, is why the letters are the interface

The letters are printed above and below the board and the prompt takes one,
matching L<Game::Oware::Notation> exactly. A terminal that invented its own
numbering would give the distribution two notations.

=head2 The board is turned round for whoever is looking

Your own six houses are always the bottom row, because the whole spatial
vocabulary of this game is "your row" and "their row". B<The letters do not
move>: C<A> to C<F> is p1's side and C<a> to C<f> is p2's, in both views and in
every line of narration, so two people looking at one game can never disagree
about where a house is.

=head2 The marks are in the text, and the colour is on top of them

Five things happen to a house in a move, and each gets a character inside its
cell: C<-> for the house that was emptied, C<+> for a house that gained a seed,
C<*> for where the last seed landed, C<x> for a capture and C<!> for a capture
that was forfeited.

B<That is deliberately not done with colour.> Strip every escape from a game and
it still says what the last move did, which is the property C<NO_COLOR>,
C<--no-ansi> and a redirected handle all depend on, and the suite asserts it
byte for byte. Colour here is a second encoding of what the marks already say,
plus a reading of the position that carries no history: a house of one or two
seeds in red because that is exactly what an opponent captures by bringing it to
two or three, and a house of twelve or more drawn bright because it laps the
board.

The C<+> marks come from walking the sow rather than from diffing two boards, so
a hand of twelve or more shows the origin staying empty while the hand goes past
it. That is the one rule in Oware that a player will otherwise be certain is a
bug, and here it is visible in the cell rather than only in a sentence.

=head2 A move is chosen with the arrow keys, and the preview is the result

On a terminal with L<Term::ReadKey> installed, the legal moves are listed under
the board and the up and down keys walk them. Return sows the one under the
cursor, a house letter jumps to that house, C<v> shows the position as it
stands, C<?> prints the rules, C<t> goes back to typing and C<q> stops. Off a
terminal, or without L<Term::ReadKey>, the moves are typed out as before, and
C<--no-pick> asks for that on purpose.

The same key tables as L<Game::Checkers::Terminal>, deliberately: two of this
author's terminals reading the same keyboard should not disagree about what
Home is.

B<The board above the list is the position the move would produce.> That is
where this parts company with the Checkers picker, which highlights the squares
a jump passes through. A checkers square holds a piece or nothing, so a
highlight is the whole story; an Oware house holds a B<number>, and the first
version of this did it the Checkers way with the result that the house under
the cursor read C<- 1> for a house the move had just emptied, and a capture drew
C<x> over seeds that were still sitting there. Previewing the result instead
means a capture shows the store going up and the status line shows the seeds
leaving the board, which is the question a player is actually asking.

The cost of a full-screen picker is that B<the opponent's move scrolls away>,
and that was a real bug in the first draft: the narration printed when the bot
moved was gone by the time there was anything to choose, so the player answered
a move they never read. The last move is recorded whether or not it was printed
and is reprinted on every frame, in the past tense, and C<v> puts its marks back
on the live board.

=head2 The board is drawn every ply, not every round

A human move and a bot reply are two changes, and drawing once after both of
them leaves the player diffing a grid of twelve numbers to work out which half
of it was their own doing. Each ply draws, so a move and its answer are two
pictures.

=head2 --ascii is a real second table

C<$GLYPH{ascii}> is C<+ - |> and a full stop for a seed, against box drawing and
a bullet for the wide form. The first version of this module shipped two
identical tables, so C<--ascii> was a flag that changed nothing; there is now a
difference to see and F<t/20-terminal.t> asserts it.

B<This file is not under C<use utf8>>, so the wide glyphs are byte strings.
Every cell is padded from a count the caller already holds rather than from
C<length>, and nothing built from a glyph reaches C<sprintf>'s C<%Ns>. A board
padded by byte count shears by two columns per seed on a UTF-8 terminal and by
none in the C locale, which is a bug that passes every test run on the machine
that wrote it.

=head2 Four moments have to be said in words as well

Oware's failure mode on a terminal is that the board changes in ways the player
cannot account for, so each of these gets a sentence rather than being left to
be inferred:

=over

=item *

B<a forfeited slam>. A capturing move captures nothing. Unexplained, that is a
bug report.

=item *

B<a sow of twelve or more>, which skipped its own house on the way past, so the
counts do not add up by eye and the player will count them again.

=item *

B<the feeding rule>, when it has pruned the move list. The refusal message
exists, but a player who never tries the illegal move never sees it.

=item *

B<the cycle ending>, named as a house rule with the count that triggered it,
because a game ending on a rule no book contains has to say so. C<quiet> does
B<not> silence that paragraph: it is not narration, and a terse run of this
program must not imply a book says what it just did.

=back

The failed-feed ending is a fifth: a seat that cannot move takes its own seeds,
which reads backwards to anybody who knows chess.

=head2 quiet never silences the result

C<quiet> drops the banner, the narration and the board. It does not drop the
line saying who won, which is the one thing a run of this program always has to
produce, and the first version of this module dropped that too.

=head1 PROPERTIES

=head2 in

The handle to read from. Defaults to C<STDIN>.

=head2 out

The handle to write to. Defaults to C<STDOUT>.

=head2 level

The bot's level, 1 to 5.

=head2 variant

C<abapa> or C<awari>.

=head2 seat

Which seat the human plays, C<p1> or C<p2>.

=head2 seed

Passed to the game and, with a suffix, to the bot.

=head2 quiet

Suppress the banner, the narration and the board. Not the result, and not the
cycle rule's disclaimer.

=head2 ascii

Plain box drawing and a full stop for a seed.

=head2 game

The L<Game::Oware> being played. Built by C<BUILD> unless one is supplied, which
is how the suite starts from a constructed position.

=head2 bot

The L<Game::Oware::Bot> playing the other seat.

=head2 raw

Whether the terminal is currently in cbreak mode. Set by L</enter_raw> and
cleared by L</leave_raw>.

=head2 keysource

A coderef taking a wait flag and returning one character, used in place of
L<Term::ReadKey>:

    $terminal->keysource(sub { shift @character });

That is how F<t/22-pick.t> drives the whole key loop with no terminal, no pipe
and no L<Term::ReadKey> installed. A key loop with no such seam does not get
tested, it gets asserted about in POD.

=head2 pending

Characters read and given back, which is how an escape that turns out not to
open a sequence does not eat the keystroke behind it.

=head2 recent

The last two plies, as C<< { move, seat } >> hashrefs, oldest first. Recorded
whether or not they were narrated: the picker clears the screen on every
keystroke, so this is the only surviving copy of the round.

=head1 METHODS

=head2 ansi

Whether to emit escapes. C<NO_COLOR> wins over everything; an explicit C<ansi>
option beats the tty check; otherwise it follows whether C<out> is a terminal.

=head2 progress

Whether to print the transient "thinking" line while the bot searches. An
explicit C<progress> option beats the tty check; otherwise it follows whether
C<out> is a terminal, and C<quiet> turns it off outright.

It is gated on being interactive rather than on C<ansi>, for two reasons: level
5 can spend several seconds on one move and a dead screen is the worst thing
this program does, while a line that is erased with a carriage return has no
business in a file. Gating it on C<ansi> instead would also put it in a coloured
run and not a plain one, which is exactly the difference the suite forbids.

=head2 interactive

Whether C<out> is something a player is looking at. An explicit C<interactive>
option beats the tty check. It gates the screen clearing and, by default,
L</progress>.

=head2 picking

Whether a move is chosen with the keys rather than typed. Settable, because the
C<t> key and the C<type> command turn it off for the rest of the game and
C<pick> turns it back on. Unset, it follows L</keys_available>; C<quiet> turns
it off outright, there being no board to put a cursor on.

=head2 keys_available

Whether there is anything to read keys with: true when L</keysource> is set, or
when C<in> is a terminal and L<Term::ReadKey> can be loaded.

=head2 enter_raw

Puts the terminal into cbreak and returns the object, or C<undef> if it cannot.

B<cbreak rather than raw>, so an interrupt stays an interrupt rather than
becoming a key this module has to know about.

=head2 leave_raw

Puts it back. F<bin/oware> calls this from a signal handler and after an C<eval>
around the game, because a program that dies in cbreak leaves the shell it came
from with no echo.

=head2 read_char

One character: whatever L</pending> is holding, else L</keysource> if it is set,
else L<Term::ReadKey>. With a false argument it does not block, and returns
C<undef> when there is nothing there.

=head2 read_key

One keystroke, as a name. A character comes back as itself; an escape sequence
comes back as C<up>, C<down>, C<home> and so on, and a control character as
C<enter>, C<tab>, C<backspace>, C<interrupt> or C<eof>. So a name is always
longer than one character and a key never collides with one.

=head2 read_sequence

The tail of an escape sequence, called once the escape has been read. An opener
that turns out not to belong to a sequence is put back on L</pending> rather
than lost, because the escape key and the first byte of an arrow key are the
same byte.

=head2 pick

Draws the board, the option list and the cursor, and reads keys until something
is played or the player stops. Returns 1 if a move was made and 0 if not, the
same contract as the typed turn, and hands over to the typed turn if the keys
turn out not to be available after all.

=head2 preview

    my ($board, $move) = $terminal->preview($house);

What sowing a house would do, resolved against the live position and never
played. The board is a new fourteen cells and the game is untouched.

=head2 describe

One line on what sowing a house would do: how many seeds, whether it laps the
board, what it captures, and whether the capture would be forfeited.

=head2 choice_lines

The option list, one line per legal move, with the one under the cursor marked.
Not windowed, because six is the most there can ever be.

=head2 legend

The keys, as lines to print under the list.

=head2 rows_for

The house indices of the top and bottom rows, from a seat's point of view.

=head2 marks_for

    my $marks = $terminal->marks_for($move);

What a L<Game::Oware::Move> did, as a hashref of house index to mark character.
Built by walking the sow, so it is the move's own account of itself rather than
a diff of two positions.

=head2 board_text

    my @lines = $terminal->board_text($game, $seat, $marks);
    my @lines = $terminal->board_text($board, $seat, $marks);

The board as nine lines, from a seat's point of view. C<$marks> is optional and
comes from L</marks_for>.

A L<Game::Oware> or a bare fourteen cells, because the picker draws a position
no game has been in: the one a candidate move would produce.

=head2 status_text

One line: the seeds still in play, and what wins. Seeds in a house belong to
nobody, so the difference between the stores and the board is worth a number.
Takes a game or a board, for the same reason.

=head2 command

One line of input as an instruction: C<quit>, C<help>, C<board>, C<pick>,
C<type>, C<again> for an empty line, or the text itself.

B<There is no single-letter shortcut for C<board>.> C<b> and C<B> are houses,
and the first draft of this module accepted C<b> as the command, so typing a
perfectly ordinary move redrew the board instead of playing it. C<q> and C<h>
are safe because no house is called either.

=head2 start

Plays the game and returns its L<Game::Oware::Result>, or C<undef> if the player
quit.

=head1 SEE ALSO

L<Game::Oware>, L<Game::Oware::Bot>, L<Game::Oware::Notation>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
