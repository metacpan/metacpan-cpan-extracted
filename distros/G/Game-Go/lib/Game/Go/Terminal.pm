package Game::Go::Terminal;

use 5.010;
use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Go;
use Game::Go::Bot;
use Game::Go::Rules;
use Game::Go::Notation;
use Game::Go::Scoring;

our $VERSION = '0.02';

our %STONE = (
	wide => {
		black => "\x{25cf}", white => "\x{25cb}",
		black_last => "\x{25c9}", white_last => "\x{25ce}",
		took => "\x{00d7}",
		star => "\x{254b}",
		cross => "\x{253c}",
		tl => "\x{250c}", tr => "\x{2510}", bl => "\x{2514}", br => "\x{2518}",
		t  => "\x{252c}", b  => "\x{2534}", l  => "\x{251c}", r  => "\x{2524}",
		bar => "\x{2500}",
	},
	ascii => {
		black => 'X', white => 'O',
		black_last => 'x', white_last => 'o',
		took => 'x',
		star => '*',
		cross => '+',
		tl => '+', tr => '+', bl => '+', br => '+',
		t  => '+', b  => '+', l  => '+', r  => '+',
		bar => '-',
	},
);

my $B = Game::Go::Rules::BLACK;
my $W = Game::Go::Rules::WHITE;

has in  => (is => 'ro');
has out => (is => 'ro');

has size     => (is => 'ro', isa => Int, default => 9);
has level    => (is => 'ro', isa => Int, default => 2);
has colour   => (is => 'ro', default => 'b');
has komi     => (is => 'ro');
has handicap => (is => 'ro', isa => Int, default => 0);
has seed     => (is => 'ro', default => 'terminal');

has ascii => (is => 'ro', default => 0);
has quiet => (is => 'ro', default => 0);
has ansi  => (is => 'rw');

has game => (is => 'rw');
has bot  => (is => 'rw');

has raw => (is => 'rw', default => 0);

has keysource => (is => 'rw');

has pending => (is => 'rw', default => sub { [] });

has _picking => (is => 'rw', init_arg => 'picking', private => 1);

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

has _human => (is => 'rw', private => 1);
has _shown => (is => 'rw', private => 1, default => 0);

sub BUILD {
	my ($self) = @_;

	my $size = $self->size;
	die "Game::Go::Terminal: size must be 9, 13 or 19, not '$size'\n"
		unless grep { $_ == $size } Game::Go->sizes;

	my $level = $self->level;
	die "Game::Go::Terminal: level must be 1 to 5, not '$level'\n"
		unless $level >= 1 && $level <= 5;

	my $colour = lc $self->colour;
	$colour = 'b' if $colour eq 'black' || $colour eq 'dark';
	$colour = 'w' if $colour eq 'white' || $colour eq 'light';
	my $who = Game::Go::Rules::from_letter($colour);
	die "Game::Go::Terminal: colour must be black or white, not '" . $self->colour . "'\n"
		unless $who;
	$self->_human($who);

	my $most = Game::Go::Rules::max_handicap($size);
	die "Game::Go::Terminal: handicap must be 0 to $most on a ${size}x$size board\n"
		if $self->handicap < 0 || $self->handicap > $most;

	if (defined $self->komi) {
		die "Game::Go::Terminal: komi must be a multiple of 0.5\n"
			unless $self->komi =~ /\A-?[0-9]+(?:\.[05])?\z/;
	}

	$self->game(Game::Go->new(
		size     => $size,
		handicap => $self->handicap,
		(defined $self->komi ? (komi => $self->komi) : ()),
		seed     => $self->seed,
	));
	$self->bot(Game::Go::Bot->new(level => $level, seed => $self->seed));

	$self->ansi($self->_want_ansi) unless defined $self->ansi;
	$self->_encode_out;
	return;
}

sub _encode_out {
	my ($self) = @_;
	return if $self->ascii;

	my $out = $self->out or return;
	my @layers = eval { PerlIO::get_layers($out) };
	return if $@;
	return if grep { /\A(?:utf8|encoding)/ } @layers;

	binmode $out, ':encoding(UTF-8)';
	return;
}

sub _want_ansi {
	my ($self) = @_;
	return 0 if exists $ENV{NO_COLOR};
	my $out = $self->out;
	return 0 unless $out;
	return -t $out ? 1 : 0;
}

sub _say {
	my ($self, @lines) = @_;
	return if $self->quiet;
	my $out = $self->out or return;
	print {$out} "$_\n" for @lines;
	return;
}

sub _ink {
	my ($self, $code, $text) = @_;
	return $text unless $self->ansi;
	return "\e[${code}m$text\e[0m";
}

sub glyph {
	my ($self, $colour, %o) = @_;

	my $set = $self->ascii ? 'ascii' : 'wide';
	my $stone = $STONE{$set};

	if ($colour == $B || $colour == $W) {
		my $face = $o{last}
			? ($colour == $B ? $stone->{black_last} : $stone->{white_last})
			: ($colour == $B ? $stone->{black} : $stone->{white});
		my $ink = $o{last} ? '1;31' : $colour == $B ? '1;30' : '1;37';
		return $self->_ink($ink, $face);
	}

	return $o{took} ? $self->_ink('1;31', $stone->{took})
	     : $o{star} ? $stone->{star}
	     : $stone->{$o{line} || 'cross'};
}

sub board_text {
	my ($self, %o) = @_;
	my $game = $self->game;
	my $size = $game->size;
	my $board = $game->board;

	my @letters = map { Game::Go::Notation::col_letter($_) } 0 .. $size - 1;
	my $width = length $size;
	$o{stars} = { map { $_ => 1 } @{ $game->star_points } };

	my $set = $self->ascii ? 'ascii' : 'wide';
	my $bar = $STONE{$set}{bar};
	my %took = map { $_ => 1 } @{ $o{took} || [] };

	my @lines;
	push @lines, sprintf('%*s %s', $width, '', join ' ', @letters);

	for my $row (0 .. $size - 1) {
		my $number = $size - $row;
		my @cells;
		for my $col (0 .. $size - 1) {
			my $at = $board->at($col, $row);
			my $pt = $game->point($col, $row);

			my $on = defined $o{cursor} && $o{cursor} == $pt;

			my $cell = $on && $at == Game::Go::Rules::EMPTY
				? $self->_ink('7', $self->glyph($o{to_play} || $B))
				: $on
				? $self->_ink('7', $self->glyph($at))
				: $self->glyph($at,
					star => $o{stars}{$pt},
					took => ($at == Game::Go::Rules::EMPTY && $took{$pt}),
					last => (defined $o{last} && $o{last} == $pt),
					line => $self->_line_at($col, $row, $size));

			push @cells, { text => $cell, cursor => $on };
		}

		my $line = '';
		for my $i (0 .. $#cells) {
			$line .= $cells[$i]{cursor} ? '['
				: $cells[ $i - 1 ]{cursor} ? ']'
				: $self->_ink('2', $bar)
				if $i;
			$line .= $cells[$i]{text};
		}

		push @lines, sprintf('%*d%s%s%s%d', $width, $number,
			($cells[0]{cursor}  ? '[' : ' '), $line,
			($cells[-1]{cursor} ? ']' : ' '), $number);
	}

	push @lines, sprintf('%*s %s', $width, '', join ' ', @letters);
	return @lines;
}

sub _line_at {
	my ($self, $col, $row, $size) = @_;
	my $top    = $row == 0;
	my $bottom = $row == $size - 1;
	my $left   = $col == 0;
	my $right  = $col == $size - 1;

	return 'tl' if $top && $left;
	return 'tr' if $top && $right;
	return 'bl' if $bottom && $left;
	return 'br' if $bottom && $right;
	return 't'  if $top;
	return 'b'  if $bottom;
	return 'l'  if $left;
	return 'r'  if $right;
	return 'cross';
}

sub _show {
	my ($self, %o) = @_;
	my $game = $self->game;
	$self->_say('', $self->board_text(%o));

	my $p = $game->prisoners;
	$self->_say(sprintf('  captures: black %d, white %d    komi %s',
		$p->{$B}, $p->{$W}, $game->komi));
	return;
}


sub start {
	my ($self) = @_;
	my $game = $self->game;

	$self->_intro;

	my $guard = 0;
	while ($game->status eq 'active' && $guard++ < 4 * $game->size * $game->size) {
		my ($who) = $game->waiting_on;
		last unless defined $who;

		my $ok = $who == $self->_human ? $self->_human_turn($who)
		                               : $self->_bot_turn($who);
		last unless $ok;
	}

	$self->_finish;
	return $game->outcome || $game->result;
}

sub _intro {
	my ($self) = @_;
	my $game = $self->game;
	$self->_say(
		sprintf('Go, %dx%d, komi %s%s.', $game->size, $game->size, $game->komi,
			$game->handicap ? sprintf(', handicap %d', $game->handicap) : ''),
		sprintf('You are %s; the bot is level %d.',
			Game::Go::Rules::colour_name($self->_human), $self->bot->level),
		'Enter a point such as D4, or: pass, resign, board, libs D4, help.',
	);
	return;
}

sub _prompt {
	my ($self, $text) = @_;
	my $out = $self->out;
	print {$out} $text unless $self->quiet;
	my $in = $self->in or return undef;
	my $line = <$in>;
	return undef unless defined $line;

	print {$out} "\n" unless $self->quiet;

	chomp $line;
	return $line;
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
	return 0 if $self->quiet;
	return $self->_picking ? 1 : 0 if defined $self->_picking;
	return $self->keys_available;
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

sub preview {
	my ($self, $who, $pt) = @_;

	my $game = $self->game;
	my ($col, $row) = $game->col_row($pt);
	my $at = $game->board->at($col, $row);

	return { refused => 'there is a stone there' }
		if $at != Game::Go::Rules::EMPTY;

	my $trial = $game->clone;
	my $move = $trial->play($who, $pt);
	return { refused => $move->message } if ref $move eq 'Game::Go::Error';

	return {
		move => $move,
		caps => scalar @{ $move->caps || [] },
		libs => $trial->board->libs($col, $row),
		size => $trial->board->chain_size($col, $row),
	};
}

sub point_line {
	my ($self, $who, $pt) = @_;

	my $game = $self->game;
	my $name = Game::Go::Notation::to_human($game->size, $game->col_row($pt));
	my $peek = $self->preview($who, $pt);

	return "$name: " . $peek->{refused} if $peek->{refused};

	my $line = "$name: ";
	$line .= sprintf 'takes %d, ', $peek->{caps} if $peek->{caps};
	$line .= $peek->{size} == 1
		? sprintf('a lone stone with %d liberties', $peek->{libs})
		: sprintf('joins a group of %d with %d liberties',
			$peek->{size}, $peek->{libs});
	$line .= $self->_ink('1;31', '  (atari)') if $peek->{libs} == 1;

	return $line;
}

sub interactive {
	my ($self) = @_;
	my $out = $self->out or return 0;
	return (eval { -t $out }) ? 1 : 0;
}

sub clear {
	my ($self) = @_;
	return $self unless $self->interactive;
	my $out = $self->out;
	print {$out} "\e[2J\e[3J\e[H";
	return $self;
}

sub pick_point {
	my ($self, $who) = @_;

	my $game = $self->game;
	my $size = $game->size;
	my $at = $self->_last_point;
	$at = $game->point(int($size / 2), int($size / 2)) unless defined $at;

	my ($col, $row) = $game->col_row($at);
	my @notice;

	while (1) {
		my $pt = $game->point($col, $row);
		$self->clear;
		$self->_show($self->_since, cursor => $pt, to_play => $who);
		$self->_say('  ' . $self->point_line($who, $pt));
		$self->_say('  ' . $self->_ink('2', $_)) for @notice;
		@notice = ();
		$self->_say('  ' . $self->_ink('2',
			'arrows to move, enter to play, p pass, ? for the keys'));

		my $key = $self->read_key;
		return 0 if !defined $key || $key eq 'eof' || $key eq 'interrupt';

		if ($key eq 'left')  { $col = ($col - 1) % $size; next }
		if ($key eq 'right') { $col = ($col + 1) % $size; next }
		if ($key eq 'up')    { $row = ($row - 1) % $size; next }
		if ($key eq 'down')  { $row = ($row + 1) % $size; next }
		if ($key eq 'home')  { $col = 0;         next }
		if ($key eq 'end')   { $col = $size - 1; next }

		if ($key eq 'enter' || $key eq ' ') {
			my $move = $game->play($who, $pt);
			if (ref $move eq 'Game::Go::Error') {
				@notice = ($move->message);
				next;
			}
			$self->_say(sprintf('  you play %s%s.',
				Game::Go::Notation::to_human($size, $col, $row),
				$self->_took($move)));
			return 1;
		}

		if ($key eq 'p') {
			my $out = $game->pass($who);
			return $self->_refused($out) if ref $out eq 'Game::Go::Error';
			$self->_say('  you pass.');
			return 1;
		}

		if ($key eq 'r') { $game->resign($who); return 0 }
		if ($key eq 'q') { return 0 }

		if ($key eq 't') { $self->picking(0); return $self->_typed_turn($who) }

		if ($key eq '?') { @notice = $self->pick_help; next }

		@notice = ('that key does nothing here. ? for the ones that do');
	}
}

sub pick_help {
	return (
		'arrows move the cursor, enter plays the point it is on.',
		'the line under the board says what that move would do.',
		'p passes, r resigns, t goes back to typing, q stops.',
	);
}

sub _human_turn {
	my ($self, $who) = @_;
	my $game = $self->game;

	return $self->_human_marking($who) if $game->phase eq 'marking';

	if ($self->picking) {
		return $self->pick_point($who) if $self->enter_raw;
		$self->picking(0);
	}

	return $self->_typed_turn($who);
}

sub _typed_turn {
	my ($self, $who) = @_;
	my $game = $self->game;

	$self->_show($self->_since);

	while (1) {
		my $line = $self->_prompt('your move> ');
		return 0 unless defined $line;
		$line =~ s/\A\s+|\s+\z//g;
		next unless length $line;

		if ($line =~ /\Ahelp\z/i)  { $self->_help; next }
		if ($line =~ /\Aboard\z/i) { $self->_show($self->_since); next }
		if ($line =~ /\Alibs\s+(\S+)\z/i) { $self->_libs($1); next }
		if ($line =~ /\A(?:resign|quit)\z/i) { $game->resign($who); return 0 }

		if ($line =~ /\Apass\z/i) {
			my $out = $game->pass($who);
			return $self->_refused($out) if ref $out eq 'Game::Go::Error';
			$self->_say('  you pass.');
			return 1;
		}

		my ($col, $row) = Game::Go::Notation::from_human($game->size, $line);
		unless (defined $col) {
			$self->_say("  '$line' is not a point on this board. Try D4, or help.");
			next;
		}

		my $move = $game->play($who, $game->point($col, $row));
		if (ref $move eq 'Game::Go::Error') { $self->_say('  ' . $move->message); next }

		$self->_say(sprintf('  you play %s%s.', uc $line, $self->_took($move)));
		return 1;
	}
}

sub _bot_turn {
	my ($self, $who) = @_;
	my $game = $self->game;

	my $move = $self->bot->choose($game, $who);
	unless ($move) { $self->_say('  the bot has nothing to play.'); return 0 }

	my $name = Game::Go::Rules::colour_name($who);

	if ($move->kind eq 'pass') {
		$game->pass($who);
		$self->_say("  $name passes.");
		return 1;
	}
	if ($move->kind eq 'play') {
		my $out = $game->play($who, $move->point);
		return $self->_refused($out) if ref $out eq 'Game::Go::Error';
		my ($col, $row) = $game->col_row($move->point);
		$self->_say(sprintf('  %s plays %s%s.', $name,
			Game::Go::Notation::to_human($game->size, $col, $row), $self->_took($out)));
		return 1;
	}

	my $answer =
		  $move->kind eq 'mark'    ? $game->mark($who, $move->point)
		: $move->kind eq 'done'    ? $game->done($who)
		: $move->kind eq 'accept'  ? $game->accept($who)
		: $move->kind eq 'dispute' ? $game->dispute($who)
		: undef;
	return $self->_refused($answer) if ref $answer eq 'Game::Go::Error';

	$self->_say("  $name: " . $self->_marking_words($move->kind));
	return 1;
}

sub _took {
	my ($self, $move) = @_;
	return '' unless ref $move eq 'Game::Go::Move' && $move->captured;
	my $game = $self->game;
	my @names = map {
		Game::Go::Notation::to_human($game->size, $game->col_row($_))
	} @{ $move->caps };
	return sprintf(', taking %s', join ' ', @names);
}

sub _last_point {
	my ($self) = @_;
	for my $e (reverse @{ $self->game->log }) {
		return $e->{payload}{pt} if $e->{kind} eq 'play';
	}
	return undef;
}

sub _last_took {
	my ($self) = @_;
	for my $e (reverse @{ $self->game->log }) {
		return $e->{payload}{caps} || [] if $e->{kind} eq 'play';
	}
	return [];
}

sub _since {
	my ($self) = @_;
	return (last => $self->_last_point, took => $self->_last_took);
}

sub _refused {
	my ($self, $out) = @_;
	$self->_say('  ' . $out->message) if ref $out eq 'Game::Go::Error';
	return 0;
}

sub _libs {
	my ($self, $name) = @_;
	my $game = $self->game;
	my ($col, $row) = Game::Go::Notation::from_human($game->size, $name);
	unless (defined $col) { $self->_say("  '$name' is not a point."); return }

	my $board = $game->board;
	my $at = $board->at($col, $row);
	if ($at == Game::Go::Rules::EMPTY) { $self->_say('  ' . uc($name) . ' is empty.'); return }

	$self->_say(sprintf('  %s is a %s group of %d, with %d liberties.',
		uc $name, Game::Go::Rules::colour_name($at),
		$board->chain_size($col, $row), $board->libs($col, $row)));
	return;
}

sub _help {
	my ($self) = @_;
	$self->_say(
		'',
		'  D4        play there. Columns are A to T with I left out,',
		'            and rows are numbered from the bottom.',
		'  pass      pass. Two passes in a row stop play.',
		'  board     draw the board again.',
		'  libs D4   how many liberties that group has.',
		'  resign    give up.',
		'',
	);
	return;
}

sub _marking_words {
	my ($self, $kind) = @_;
	return 'marks a group as dead'        if $kind eq 'mark';
	return 'unmarks a group'              if $kind eq 'unmark';
	return 'offers that as the count'     if $kind eq 'done';
	return 'agrees, and the game is over' if $kind eq 'accept';
	return 'disagrees, so play resumes'   if $kind eq 'dispute';
	return $kind;
}

sub _human_marking {
	my ($self, $who) = @_;
	my $game = $self->game;
	my $m = $game->marking;

	unless ($self->_shown) {
		$self->_say(
			'',
			'  Both players passed, so play has STOPPED. The game is not over yet:',
			'  before it can be counted you have to agree which stones are dead.',
		);
		$self->_shown(1);
	}

	$self->_show($self->_since);

	if (!$m->proposed) {
		$self->_say(
			sprintf('  It is your count to offer. Marked dead so far: %s.',
				$self->_dead_words),
			'  Type a point to mark that group dead, or "done" to offer the count.',
		);
		while (1) {
			my $line = $self->_prompt('mark> ');
			return 0 unless defined $line;
			$line =~ s/\A\s+|\s+\z//g;
			next unless length $line;
			if ($line =~ /\Adone\z/i) { $game->done($who); return 1 }
			if ($line =~ /\Aboard\z/i) { $self->_show($self->_since); next }

			my ($col, $row) = Game::Go::Notation::from_human($game->size, $line);
			unless (defined $col) { $self->_say("  '$line' is not a point."); next }
			my $out = $game->mark($who, $game->point($col, $row));
			if (ref $out eq 'Game::Go::Error') { $self->_say('  ' . $out->message); next }
			$self->_say(sprintf('  %s: %s', uc $line, $self->_marking_words($out->kind)));
			$self->_say('  Marked dead: ' . $self->_dead_words);
		}
	}

	$self->_say(
		sprintf('  The bot offers this count. Marked dead: %s.', $self->_dead_words),
		'  Type "accept" to agree and finish, or "dispute" to put it back on the',
		'  board and play it out. Disputing costs you the move: your opponent',
		'  plays first.',
	);
	while (1) {
		my $line = $self->_prompt('accept or dispute> ');
		return 0 unless defined $line;
		$line =~ s/\A\s+|\s+\z//g;
		if ($line =~ /\Aaccept\z/i)  { $game->accept($who); return 1 }
		if ($line =~ /\Adispute\z/i) {
			my $out = $game->dispute($who);
			if (ref $out eq 'Game::Go::Error') { $self->_say('  ' . $out->message); next }
			$self->_shown(0);
			$self->_say('  Back to the board, and your opponent has the move.');
			return 1;
		}
		$self->_say('  "accept" or "dispute".');
	}
}

sub _dead_words {
	my ($self) = @_;
	my $game = $self->game;
	my $m = $game->marking or return 'nothing';
	my @points = @{ $m->dead_points };
	return 'nothing' unless @points;
	return join ' ', map {
		Game::Go::Notation::to_human($game->size, $game->col_row($_))
	} @points;
}


sub _finish {
	my ($self) = @_;
	my $game = $self->game;
	$self->_show($self->_since);

	my $r = $game->outcome;
	unless ($r) {
		$self->_say('', '  ' . ($game->result || 'unfinished') . '.');
		return;
	}

	my $t = $r->territory;
	my $p = $r->prisoners;
	$self->_say(
		'',
		sprintf('  black  %3d territory  -%3d prisoners%s = %s',
			$t->{$B} // 0, $p->{$W} // 0, ' ' x 12, $r->scores->{$B}),
		sprintf('  white  %3d territory  -%3d prisoners  + %s komi = %s',
			$t->{$W} // 0, $p->{$B} // 0, $r->komi, $r->scores->{$W}),
		'',
		'  ' . $r->stringify . '.',
	);

	$self->_say('  The count was not agreed, so it was scored by area.')
		if ($r->scored_by || '') eq 'area';

	$self->_say('  A negative score means the game was long past resigning.')
		if grep { $_ < 0 } values %{ $r->scores };

	return;
}

1;

__END__

=encoding utf8

=head1 NAME

Game::Go::Terminal - a playable game on two filehandles

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    my $t = Game::Go::Terminal->new(size => 9, level => 2);
    my $result = $t->start;       # returns, never exits

=head1 DESCRIPTION

A game of Go against the bot, on C<in> and C<out>.

It is a separate module from L<Game::Go> for a reason a sibling distribution
paid for: that one put a thousand lines of escape codes in its top-level
namespace module, which is why only its board class ever turned out to be
reusable.

=head2 Why it ships

B<The confirmation phase is a two-person negotiation and no unit test will tell
you it is unusable.> This is where somebody finds out that the proposal is the
wrong way round, or that the prompt never says which stones are marked, or that
"dispute" reads like a refusal rather than a request to play on. Finding that
out here costs an afternoon; finding it out after the JavaScript is written
costs the JavaScript too.

=head2 What the display has to get right

These are rules rather than decoration:

B<Coordinates on both axes>, C<A> to C<T> with C<I> left out and rows numbered
from the bottom. A Go player reads them off the edge constantly, which is not
true of any other game on this roster.

B<The last move marked and the captures named.> A capture of a large group is
the most important thing that can happen in Go and it is completely invisible in
an after-picture.

B<The confirmation phase spelled out.> Two passes stop play; they do not end the
game. A player told "the game is over" and then shown a board they can still
type at will file a bug, and they will be right.

B<The final arithmetic, line by line.> A board full of stones followed by
"W+6.5" with no working reads as something the program made up, and komi and
prisoners are both invisible on the board.

=head2 The board is drawn as a board

Grid lines, not a lattice of dots: C<┌─┬─┐> with C<╋> on the star points and
stones sitting on the intersections. A go board has a line between every two
points and drawing it costs nothing, because the space between two cells was
already there.

That space is also what the cursor spends. See L</pick_point>.

=head2 A mark has to be a shape

The last move is drawn as a B<ringed> stone, C<◉> or C<◎>, and a point a
capture has just emptied as C<×>. Both are characters, so they survive
C<--ascii>, C<NO_COLOR> and a redirected handle.

That is not a preference, it is a bug this had. The last move was marked by
wrapping the cell in C<\e[31m>, but the cell was already C<\e[1;30m●\e[0m>
from L</glyph>, so the inner code won and the reset closed it: the mark was
emitted on every board and never once visible. A colour laid over a colour is
not a mark.

=head2 You point at the move you mean

On a terminal with L<Term::ReadKey> installed the arrow keys walk a cursor
over the board, the point under it shows the stone you would play, and return
plays it. C<p> passes, C<r> resigns, C<t> goes back to typing, C<?> lists the
keys and C<q> stops. Without L<Term::ReadKey>, or off a terminal, every move
is typed as before.

B<A list would be absurd here>, which is what makes this different from the
other terminals on this roster. A 19x19 board offers up to 362 legal moves, so
there is nothing to enumerate: the board already shows every one of them, laid
out in the shape the player is thinking in. The cursor is two-dimensional for
the same reason.

=head2 What the point under the cursor says

One line, from the engine rather than from arithmetic here: whether the point
can be played and why not if it cannot, what the move would capture, and how
many liberties the resulting group would have.

    E5: a lone stone with 4 liberties
    A8: takes 1, a lone stone with 3 liberties
    C9: joins a group of 2 with 6 liberties
    A9: that move would leave your own stones with no liberty

It is the engine's own answer because L</preview> plays the point on a
B<clone> and asks the clone. Nothing is played, which matters more here than
in the other games on this roster: a preview that moved the game would be
worse than no preview, and the suite asserts the board and the turn are
untouched after one.

A clone is 0.009 ms on 19x19, so the line can be recomputed on every keystroke
without anybody noticing.

=head1 ATTRIBUTES

=head2 in, out

The two filehandles. Keeping them as attributes is what lets a test play a whole
game in process against tied in-memory handles, with no fork and no subprocess
to eat the test output.

=head2 size, level, colour, komi, handicap, seed, ascii, quiet

B<Every one is validated in the constructor.> A sibling's terminal refused a bad
colour with a tidy sentence and exit 2, and died on a bad variant with a raw
Perl message and exit 255, because one option was checked in the constructor and
the other several calls deeper.

C<colour> accepts C<b>, C<w>, C<black>, C<white>, C<dark> and C<light>.

=head2 game, bot

The L<Game::Go> being played and the L<Game::Go::Bot> playing the other side,
built in the constructor from the options above. They are readable so that a
test can assert against the position rather than against the drawn board, which
is the difference between a test that checks the rules and one that checks the
spacing.

=head2 ansi

Whether to colour the output. Worked out at construction if not given:
B<C<NO_COLOR> wins over an explicit request>, which is the whole point of the
convention, and otherwise colour is used only when C<out> is a terminal.

=head1 METHODS

=head2 start

Plays the game and B<returns> the L<Game::Go::Result>. It never calls C<exit>: a
module that exits cannot be tested in process.

=head2 board_text

The board as lines, coordinates and all.

=head2 glyph

=head2 interactive, clear

Whether C<out> is a terminal, and the screen clear the picker does before each
frame. A 19x19 board is twenty-three lines, so a picker that scrolled one of
them per keystroke would be unusable.

=head2 picking

Whether a point is pointed at rather than typed. Settable, because a failed
C<enter_raw> and the C<t> key turn it off for the rest of the game. Unset, it
follows L</keys_available>.

=head2 keys_available, enter_raw, leave_raw

Whether there is anything to read keys with, and cbreak on and off. B<cbreak
rather than raw>, so an interrupt stays an interrupt.

=head2 keysource, pending, raw

A coderef returning ONE character in place of L<Term::ReadKey>, characters read
and given back, and the cbreak state. C<keysource> is what lets F<t/23> drive
the whole key loop with no terminal and no L<Term::ReadKey> installed; one
character a call, because a source handing back C<"\e[C"> whole never becomes a
right arrow.

=head2 read_char, read_key, read_sequence

One character, one keystroke as a name, and the tail of an escape sequence. A
name is always longer than one character so it never collides with one, and an
opener that turns out not to open a sequence goes back on L</pending>.

=head2 pick_point, pick_help

The cursor loop and its key list. C<pick_point> returns true if a turn was
taken and false to stop, the same contract as the typed turn.

=head2 preview

    my $peek = $terminal->preview($colour, $point);

What playing a point would do, as C<< { refused => $why } >> or
C<< { move, caps, libs, size } >>. Played on a clone; the game is not touched.

=head2 point_line

L</preview> as the one line printed under the board.

One point's character.

=head1 SEE ALSO

L<Game::Go>, L<Game::Go::Bot>, F<bin/go>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
