package Game::Dominoes::Notation;

use strict;
use warnings;

use Exporter 'import';

use Game::Dominoes::Tile;
use Game::Dominoes::Layout;

our $VERSION = '0.01';
our @EXPORT_OK = qw(
	tile_text parse_tile
	move_text parse_move
	to_text from_text to_layout
);

sub tile_text {
	my ($tile) = @_;
	die 'Game::Dominoes::Notation: tile_text wants a tile' unless ref $tile;
	return $tile->stringify;
}

sub parse_tile {
	my ($text) = @_;
	die 'Game::Dominoes::Notation: not a tile: '
		. (defined $text ? "'$text'" : 'undef')
		unless defined $text && $text =~ /\A([0-6])-([0-6])\z/;
	return Game::Dominoes::Tile->of($1, $2);
}

sub move_text {
	my ($move) = @_;
	die 'Game::Dominoes::Notation: move_text wants a move' unless ref $move;

	if (ref $move ne 'HASH') {
		my $played = $move->tile->stringify . '@' . $move->arm;
		$played .= '*' if $move->spinner;
		return $played;
	}

	my $kind = $move->{kind} || 'play';
	return 'P' if $kind eq 'pass';
	return '|' if $kind eq 'hand_end';
	if ($kind eq 'draw') {
		my $n = $move->{count} || 1;
		return $n > 1 ? "D$n" : 'D';
	}
	my $text = $move->{tile}->stringify . '@' . $move->{arm};
	$text .= '*' if $move->{spinner};
	return $text;
}

sub parse_move {
	my ($token) = @_;
	die 'Game::Dominoes::Notation: empty move' unless defined $token && length $token;

	return { kind => 'pass' } if $token eq 'P';
	return { kind => 'hand_end' } if $token eq '|';
	if ($token =~ /\AD(\d*)\z/) {
		my $n = length $1 ? $1 + 0 : 1;
		die "Game::Dominoes::Notation: a draw of $n is not a draw" if $n < 1;
		return { kind => 'draw', count => $n };
	}
	if ($token =~ /\A([0-6]-[0-6])\@([LRUD])(\*?)\z/) {
		return {
			kind    => 'play',
			tile    => parse_tile($1),
			arm     => $2,
			spinner => $3 ? 1 : 0,
		};
	}
	die "Game::Dominoes::Notation: not a move: '$token'";
}

sub to_text {
	my ($moves) = @_;
	die 'Game::Dominoes::Notation: to_text wants an arrayref'
		unless ref $moves eq 'ARRAY';
	return join ' ', map { move_text($_) } @$moves;
}

sub from_text {
	my ($text) = @_;
	return [] unless defined $text;
	$text =~ s/\A\s+//;
	$text =~ s/\s+\z//;
	return [] unless length $text;
	return [ map { parse_move($_) } split /\s+/, $text ];
}

sub to_layout {
	my ($text) = @_;
	my $moves = ref $text eq 'ARRAY' ? $text : from_text($text);
	my $layout = Game::Dominoes::Layout->new;
	for my $move (@$moves) {
		next unless ($move->{kind} || 'play') eq 'play';
		$layout->place($move->{tile}, $move->{arm});
	}
	return $layout;
}

1;

__END__

=head1 NAME

Game::Dominoes::Notation - tiles, plays and whole hands as text

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	use Game::Dominoes::Notation qw(parse_move to_text from_text to_layout);

	to_text([ $play, $another ]);        # '5-5@L* 5-2@L'
	from_text('5-5@L* 5-2@L D2 P |');    # the moves, as hashrefs
	my $layout = to_layout('5-5@L* 5-2@L');

=head1 DESCRIPTION

B<There is no published standard notation for dominoes>, the way chess has PGN
and draughts has PDN. The notation here is this distribution's own invention.
It is written down and kept stable, but it is not an authority and nothing
outside this distribution is obliged to read it.

=head2 The grammar

	6-4      a tile, higher face first
	6-4@L    a play: that tile on arm L
	6-6@L*   a play that made the spinner
	D        a draw from the boneyard
	D3       three draws in one turn
	P        a pass
	|        the end of a hand

Tokens are separated by whitespace. Arms are C<L> and C<R> along the main
line and C<U> and C<D> off the spinner, as L<Game::Dominoes::Layout> names
them.

=head2 Text is the fixture format on purpose

A diff of ordered text is readable, and there is no hash-ordering trap to sort
around. There is no JSON fixture in this distribution: decoded JSON has no
order, and a test that depends on one fails about one run in five.

=head1 FUNCTIONS

=head2 tile_text, parse_tile

	tile_text($tile);      # '6-4'
	parse_tile('6-4');     # a Game::Dominoes::Tile

One tile. C<parse_tile> accepts the faces in either order and dies on anything
that is not two faces from 0 to 6.

=head2 move_text, parse_move

	move_text($play);        # '5-5@L*'
	parse_move('D3');        # { kind => 'draw', count => 3 }

One move. C<move_text> takes a L<Game::Dominoes::Play> or a hashref in the
same shape. C<parse_move> returns a hashref whose C<kind> is C<play>, C<draw>,
C<pass> or C<hand_end>.

=head2 to_text, from_text

	to_text(\@moves);                     # a line of tokens
	from_text('5-5@L* 5-2@L D2 P |');     # an arrayref of move hashrefs

A whole sequence. C<from_text> on empty or undefined text gives an empty
arrayref rather than dying, because a hand with no moves yet is not an error.

=head2 to_layout

	my $layout = to_layout('5-5@L* 5-2@L 5-3@R');

Replays the plays onto a fresh L<Game::Dominoes::Layout>, ignoring draws and
passes, which change a hand and not the table.

This is for drawing a diagram. B<It is not enough to restore a game from>: the
text carries neither the hands nor the boneyard order, and both of those
decide the result. The move log is the canonical serialisation, and a position
never is.

=head1 SEE ALSO

L<Game::Dominoes::Layout>, whose arms this names;
L<Game::Dominoes::Play>, what a play token comes from.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-dominoes at rt.cpan.org>,
or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Dominoes>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Game::Dominoes::Notation

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
