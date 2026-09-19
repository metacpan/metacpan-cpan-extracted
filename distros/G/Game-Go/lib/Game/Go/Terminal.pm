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

our $VERSION = '0.01';

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
	my ($self, $colour) = @_;
	my ($black, $white) = $self->ascii ? ('X', 'O') : ("\x{25cf}", "\x{25cb}");
	return $colour == $B ? $self->_ink('1;30', $black)
	     : $colour == $W ? $self->_ink('1;37', $white)
	     : '.';
}

sub board_text {
	my ($self, %o) = @_;
	my $game = $self->game;
	my $size = $game->size;
	my $board = $game->board;

	my @letters = map { Game::Go::Notation::col_letter($_) } 0 .. $size - 1;
	my $width = length $size;
	$o{stars} = { map { $_ => 1 } @{ $game->star_points } };

	my @lines;
	push @lines, sprintf('%*s %s', $width, '', join ' ', @letters);

	for my $row (0 .. $size - 1) {
		my $number = $size - $row;
		my @cells;
		for my $col (0 .. $size - 1) {
			my $at = $board->at($col, $row);
			my $pt = $game->point($col, $row);
			my $cell = $at == Game::Go::Rules::EMPTY
				? ($o{stars}{$pt} ? '+' : '.')
				: $self->glyph($at);
			$cell = $self->_ink('31', $cell)
				if defined $o{last} && $o{last} == $pt && $at != Game::Go::Rules::EMPTY;
			push @cells, $cell;
		}
		push @lines, sprintf('%*d %s %d', $width, $number, join(' ', @cells), $number);
	}

	push @lines, sprintf('%*s %s', $width, '', join ' ', @letters);
	return @lines;
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
	chomp $line;
	return $line;
}

sub _human_turn {
	my ($self, $who) = @_;
	my $game = $self->game;

	return $self->_human_marking($who) if $game->phase eq 'marking';

	$self->_show(last => $self->_last_point);

	while (1) {
		my $line = $self->_prompt('your move> ');
		return 0 unless defined $line;
		$line =~ s/\A\s+|\s+\z//g;
		next unless length $line;

		if ($line =~ /\Ahelp\z/i)  { $self->_help; next }
		if ($line =~ /\Aboard\z/i) { $self->_show(last => $self->_last_point); next }
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

	$self->_show(last => $self->_last_point);

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
			if ($line =~ /\Aboard\z/i) { $self->_show(last => $self->_last_point); next }

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
	$self->_show(last => $self->_last_point);

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

Version 0.01

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
