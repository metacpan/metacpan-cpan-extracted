package Game::Merrills::Notation;

use strict;
use warnings;

use Game::Merrills::Points;

our $VERSION = '0.03';

our (%CELL, %GLYPH, %TURN, %LETTER, %SIDE);

BEGIN {
	%CELL = ('.' => 0, W => 1, B => -1);
	%GLYPH = (0 => '.', 1 => 'W', -1 => 'B');
	%TURN = (w => 'white', b => 'black');
	%LETTER = (white => 'w', black => 'b');
	%SIDE = (white => 1, black => 1);
}

sub parse_move {
	my ($text) = @_;
	return undef unless defined $text && !ref $text;
	my ($from, $to, $remove) = $text =~ m/
		^\s*
		([a-g][1-7])
		(?:\s*-\s*([a-g][1-7]))?
		(?:\s*x\s*([a-g][1-7]))?
		\s*$
	/xi or return undef;
	($from, $to) = (undef, $from) unless defined $to;
	my %move;
	for my $part ([from => $from], [to => $to], [remove => $remove]) {
		my ($key, $name) = @{$part};
		next unless defined $name;
		my $point = Game::Merrills::Points::point($name);
		return undef unless defined $point;
		$move{$key} = $point;
	}
	return undef if defined $move{from} && $move{from} == $move{to};
	return undef if defined $move{remove}
		&& ($move{remove} == $move{to}
			|| (defined $move{from} && $move{remove} == $move{from}));
	return \%move;
}

sub format_move {
	my ($move) = @_;
	die 'a move needs a point to go to' unless ref $move eq 'HASH' && defined $move->{to};
	my $text = Game::Merrills::Points::name($move->{to});
	$text = Game::Merrills::Points::name($move->{from}) . '-' . $text
		if defined $move->{from};
	$text .= 'x' . Game::Merrills::Points::name($move->{remove})
		if defined $move->{remove};
	return $text;
}

sub format_position {
	my ($position) = @_;
	die 'position: not a hashref' unless ref $position eq 'HASH';
	my $cells = $position->{cells};
	die 'position: cells must be an arrayref of 24 values'
		unless ref $cells eq 'ARRAY' && @{$cells} == Game::Merrills::Points::POINTS;
	my $board = '';
	for my $point (Game::Merrills::Points::all_points()) {
		my $value = $cells->[$point];
		die 'position: cell ' . Game::Merrills::Points::name($point) . ' must be -1, 0 or 1'
			unless defined $value && exists $GLYPH{$value};
		$board .= $GLYPH{$value};
	}
	my $turn = $position->{turn};
	die 'position: turn must be white or black'
		unless defined $turn && exists $LETTER{$turn};
	my $hand = $position->{hand} || {};
	my $text = join ' ', $board, $LETTER{$turn},
		map({ defined $hand->{$_} ? $hand->{$_} : 0 } qw/white black/),
		$position->{no_mill} || 0, $position->{ply} || 0;
	parse_position($text);
	return $text;
}

sub parse_position {
	my ($text) = @_;
	die 'position: nothing to read' unless defined $text && !ref $text;
	my @field = split ' ', $text;
	die 'position: six fields are needed, got ' . scalar @field unless @field == 6;
	my ($board, $turn, $white, $black, $no_mill, $ply) = @field;

	die 'position: the board must be 24 of W, B and .'
		unless $board =~ m/^[WB.]{24}$/;
	die "position: the side to move must be w or b, got '$turn'"
		unless exists $TURN{$turn};
	for my $count ([white => $white], [black => $black]) {
		die "position: men in hand for $count->[0] must be 0 .. 9, got '$count->[1]'"
			unless $count->[1] =~ m/^[0-9]$/;
	}
	die "position: plies since a mill must be a number, got '$no_mill'"
		unless $no_mill =~ m/^[0-9]+$/;
	die "position: the ply must be a number, got '$ply'"
		unless $ply =~ m/^[0-9]+$/;

	my @cells = map { $CELL{$_} } split //, $board;
	my %on = (white => scalar(grep { $_ == 1 } @cells), black => scalar(grep { $_ == -1 } @cells));
	die 'position: white has more than nine men' if $on{white} + $white > 9;
	die 'position: black has more than nine men' if $on{black} + $black > 9;

	return {
		cells => \@cells,
		turn => $TURN{$turn},
		hand => { white => $white + 0, black => $black + 0 },
		no_mill => $no_mill + 0,
		ply => $ply + 0,
	};
}

sub format_record {
	my ($moves, %option) = @_;
	die 'record: moves must be an arrayref' unless ref $moves eq 'ARRAY';
	my $header = '';
	if (defined $option{position}) {
		$header = 'position ' . format_position(parse_position($option{position})) . "\n";
	}
	$header .= "flying no\n" if defined $option{flying} && !$option{flying};
	my $footer = '';
	if (defined $option{offer}) {
		die "record: the offer must be white or black, got '$option{offer}'"
			unless $SIDE{ $option{offer} };
		$footer .= "offer $option{offer}\n";
	}
	if (defined $option{result}) {
		my ($winner, $reason) = @{ $option{result} };
		$winner = 'draw' unless defined $winner;
		die "record: the result must be a winner or draw and a reason, got '$winner $reason'"
			unless _result_ok($winner, $reason);
		$footer .= "result $winner $reason\n";
	}
	my @text;
	for my $i (0 .. $#{$moves}) {
		my $move = $moves->[$i];
		my $written = !ref $move ? $move
			: ref $move eq 'HASH' ? format_move($move)
			: $move->notation;
		die 'record: move ' . ($i + 1) . ', ' . (defined $written ? "'$written'" : 'undef')
			. ' is not a move'
			unless parse_move($written);
		push @text, format_move(parse_move($written));
	}
	my @line;
	for (my $i = 0; $i < @text; $i += 2) {
		push @line, join ' ', (($i / 2) + 1) . '.', grep { defined } @text[ $i, $i + 1 ];
	}
	return join '', $header, (map { "$_\n" } @line), $footer;
}

sub parse_record {
	my ($text) = @_;
	die 'record: nothing to read' unless defined $text && !ref $text;
	$text =~ s/^[ \t]*#[^\n]*$//mg;
	$text =~ s/^[ \t]*position[ \t]+[^\n]*$//m;
	$text =~ s/^[ \t]*(?:flying|offer|result)[ \t]+[^\n]*$//mg;
	my @moves;
	for my $token (split ' ', $text) {
		next if $token =~ m/^[0-9]+\.$/;
		my $move = parse_move($token);
		die 'record: move ' . (@moves + 1) . ", '$token' is not a move" unless $move;
		push @moves, $move;
	}
	return \@moves;
}

sub record_position {
	my ($text) = @_;
	die 'record: nothing to read' unless defined $text && !ref $text;
	my ($position) = $text =~ m/^[ \t]*position[ \t]+([^\n]*)$/m or return undef;
	return format_position(parse_position($position));
}

sub record_state {
	my ($text) = @_;
	die 'record: nothing to read' unless defined $text && !ref $text;
	my %state;
	for my $line (split m/\n/, $text) {
		next unless $line =~ m/^[ \t]*(flying|offer|result)[ \t]+(.*?)[ \t]*$/;
		my ($word, $value) = ($1, $2);
		die "record: a second $word line" if exists $state{$word};
		if ($word eq 'flying') {
			die "record: flying must be yes or no, got '$value'" unless $value =~ m/^(?:yes|no)$/;
			$state{flying} = $value eq 'yes' ? 1 : 0;
		}
		elsif ($word eq 'offer') {
			die "record: the offer must be white or black, got '$value'" unless $SIDE{$value};
			$state{offer} = $value;
		}
		else {
			my ($winner, $reason) = split ' ', $value;
			die "record: the result must be a winner or draw and a reason, got '$value'"
				unless _result_ok($winner, $reason) && $value =~ m/^\S+ \S+$/;
			$state{result} = [ $winner eq 'draw' ? undef : $winner, $reason ];
		}
	}
	return \%state;
}

sub _result_ok {
	my ($winner, $reason) = @_;
	return 0 unless defined $winner && defined $reason;
	return $winner eq 'draw' if $reason eq 'agreement';
	return $SIDE{$winner} && ($reason eq 'resign' || $reason eq 'timeout') ? 1 : 0;
}

1;

__END__

=head1 NAME

Game::Merrills::Notation - moves, positions and whole games as text

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

	use Game::Merrills::Notation;

	my $move = Game::Merrills::Notation::parse_move('d2-d3xa1');
	# { from => 19, to => 16, remove => 21 }

	Game::Merrills::Notation::format_move($move);      # 'd2-d3xa1'

	my $position = Game::Merrills::Notation::parse_position(
		'W..........B............ w 8 8 0 2'
	);

	my $moves = Game::Merrills::Notation::parse_record("1. d2 f4\n2. d6");

=head1 DESCRIPTION

Three things are written down: a move, a position, and a game.

=head2 A move

Points are named by their coordinates, C<a1> to C<g7>, as in
L<Game::Merrills::Points>.

	d2            a man is placed on d2
	d2-d3         the man on d2 moves to d3
	d2xa1         a man is placed on d2, closes a mill and takes the man on a1
	d2-d3xa1      the man on d2 moves to d3, closes a mill and takes a1

Case does not matter when reading, and spaces around the C<-> and the C<x>
are forgiven. What is written is always lower case with no spaces.

A flying move is written like any other move. Whether a man flew is plain
from the two points.

=head2 A position

One line of six fields, separated by spaces:

	W..........B............ w 8 8 0 2

=over 4

=item 1

The 24 points in point order, C<W> for a white man, C<B> for a black one and
C<.> for an empty point.

=item 2

The side to move, C<w> or C<b>.

=item 3

The men white has yet to place.

=item 4

The men black has yet to place.

=item 5

The plies played since a mill was last closed, which a draw is counted from.

=item 6

The plies played in the game so far.

=back

A position holds no history. A game begun from one has no earlier positions
to repeat, so a count of repeated positions starts again from nothing.

=head2 A game

The moves in order, numbered in pairs, white's move and then black's:

	1. d2 f4
	2. d6 b4
	3. d7

Reading takes the moves in the order they come and ignores the numbers and
the line breaks.

A game that did not begin from the empty board says where it began, on a
line of its own before the moves:

	position WWW.BB..B..W....B..W.B.. w 4 4 0 10
	1. d2 f4

A game played without flying says so on a line of its own before the moves,
and a game with a draw offer standing, or ended by a resignation, a timeout
or an agreed draw, says so on lines of their own after them. Each of the
three is written only when it is so:

	flying no
	1. d2 f4
	offer black
	result white resign

The result names the winner, or C<draw>, and the reason. Only the endings
the moves cannot show are written; the rest come back from playing the moves.

A line that begins with C<#> is a note and is passed over when reading.

=head1 FUNCTIONS

None is exported.

=head2 parse_move

Reads a move. Returns a hashref with C<to>, and with C<from> and C<remove>
when the move has them, each a point number. Returns undef for anything that
is not a move, and never dies, so it can be handed whatever a player typed.

A move that names the same point twice is not a move. Whether a move is legal
is not asked here.

	my $move = Game::Merrills::Notation::parse_move('D2 - D3');

=head2 format_move

Writes a move from a hashref of C<from>, C<to> and C<remove>. Dies when there
is no C<to>.

	Game::Merrills::Notation::format_move({ to => 19 });     # 'd2'

=head2 format_position

Writes a position from a hashref of C<cells>, C<turn>, C<hand>, C<no_mill>
and C<ply>, the shape L</parse_position> returns. The hand and the two counts
are taken as 0 when left out. Dies when what it is given could not be a
position.

	my $text = Game::Merrills::Notation::format_position({
		cells => \@cells,
		turn => 'white',
		hand => { white => 9, black => 9 },
	});

=head2 parse_position

Reads a position. Returns a hashref of C<cells> (24 values, 1 for white, -1
for black, 0 for empty), C<turn> (C<white> or C<black>), C<hand> (a hashref
keyed by side), C<no_mill> and C<ply>. Dies, saying what is wrong, when the
text is not a position or gives a side more than nine men.

	my $position = Game::Merrills::Notation::parse_position($text);

=head2 format_record

Writes a game from an arrayref of moves. Each may be a string, a hashref as
L</parse_move> returns, or a L<Game::Merrills::Move>. Dies, naming the move,
when one of them is not a move. Give C<position> for a game that began
somewhere other than the empty board, C<flying> as 0 for a game played
without it, C<offer> as the side whose draw offer stands, and C<result> as an
arrayref of the winner (undef for a draw) and the reason for a game ended by
C<resign>, C<timeout> or C<agreement>. Dies when one of those is not so.

	my $text = Game::Merrills::Notation::format_record(\@moves);
	my $text = Game::Merrills::Notation::format_record(\@moves, position => $start);

=head2 parse_record

Reads a game. Returns an arrayref of moves as L</parse_move> returns them.
A position line is passed over; L</record_position> reads it. The flying,
offer and result lines are passed over too; L</record_state> reads them. Dies, naming
the move by its place in the game, when one cannot be read.

	my $moves = Game::Merrills::Notation::parse_record($text);

=head2 record_position

The position a written game began from, or undef when it names none and so
began from the empty board. Dies when the position line is not a position.

	my $position = Game::Merrills::Notation::record_position($text);

=head2 record_state

What a written game says beside its moves and its start, as a hashref with
C<flying> (1 or 0) when the game names it, C<offer> (a side) when a draw
offer stands, and C<result> (an arrayref of the winner, undef for a draw, and
the reason) when the game was resigned, timed out or agreed drawn. Dies,
saying what is wrong, when one of those lines cannot be read or comes twice.

	my $state = Game::Merrills::Notation::record_state($text);

=head1 PACKAGE VARIABLES

=over 4

=item C<%CELL>, C<%GLYPH>

The cell value of each board character, and the character of each value.

=item C<%TURN>, C<%LETTER>

The side of each side letter, and the letter of each side.

=item C<%SIDE>

The two sides, C<white> and C<black>, each true.

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
