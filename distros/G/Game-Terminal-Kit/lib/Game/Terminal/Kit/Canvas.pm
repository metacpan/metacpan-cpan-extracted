package Game::Terminal::Kit::Canvas;

use 5.014;
use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.05';

has [qw/width height/] => (
	is => 'rw',
	isa => Int,
	default => 0
);

has cells => (
	is => 'rw',
	isa => ArrayRef
);

sub BUILD {
	my ($self) = @_;
	$self->wipe;
	return $self;
}

sub wipe {
	my ($self) = @_;
	my ($width, $height) = ($self->width, $self->height);
	$self->cells([ map { [ map { [' '] } 1 .. $width ] } 1 .. $height ]);
	return $self;
}

sub _style {
	my (%style) = @_;
	return join ';', grep { defined $_ && length $_ } $style{ink}, $style{ground};
}

sub _set {
	my ($self, $x, $y, $glyph, $style, $half) = @_;
	return if $y < 0 || $y >= $self->height || $x < 0 || $x >= $self->width;
	my $row = $self->cells->[$y];
	if ($row->[$x][2] && $x > 0) {
		$row->[ $x - 1 ] = [ ' ', $row->[ $x - 1 ][1] ];
	}
	if ($x + 1 < $self->width && $row->[ $x + 1 ][2]) {
		$row->[ $x + 1 ] = [ ' ', $row->[ $x + 1 ][1] ];
	}
	$row->[$x] = [ $glyph, $style, $half ];
	return;
}

sub put {
	my ($self, $x, $y, $text, %style) = @_;
	return $self unless defined $text;
	my $style = _style(%style);
	for my $glyph (split //, $text) {
		if ($style{wide}) {
			if ($x >= 0 && $x + 1 < $self->width) {
				$self->_set($x, $y, $glyph, $style);
				$self->_set($x + 1, $y, '', $style, 1);
			} else {
				$self->_set($x, $y, ' ', $style);
				$self->_set($x + 1, $y, ' ', $style);
			}
			$x += 2;
			next;
		}
		$self->_set($x, $y, $glyph, $style);
		$x++;
	}
	return $self;
}

sub fill {
	my ($self, $x, $y, $width, $height, $glyph, %style) = @_;
	$glyph = ' ' unless defined $glyph && length $glyph;
	for my $row ($y .. $y + $height - 1) {
		$self->put($x, $row, $glyph x $width, %style);
	}
	return $self;
}

sub box {
	my ($self, $x, $y, $width, $height, $glyphs, %style) = @_;
	return $self if $width < 2 || $height < 2;
	my $inner = $width - 2;
	$self->put($x, $y, $glyphs->{tl} . ($glyphs->{t} x $inner) . $glyphs->{tr}, %style);
	for my $row ($y + 1 .. $y + $height - 2) {
		$self->put($x, $row, $glyphs->{l}, %style);
		$self->put($x + $width - 1, $row, $glyphs->{r}, %style);
	}
	$self->put($x, $y + $height - 1, $glyphs->{bl} . ($glyphs->{b} x $inner) . $glyphs->{br}, %style);
	return $self;
}

sub lines {
	my ($self, $screen) = @_;
	my $colour = $screen && $screen->colour;
	my @lines;
	for my $row (@{ $self->cells }) {
		my @cells = @{$row};
		pop @cells while @cells
			&& ($cells[-1][0] eq ' ' || $cells[-1][0] eq '')
			&& !($colour && defined $cells[-1][1] && length $cells[-1][1]);
		my ($line, $held) = ('', '');
		for my $cell (@cells) {
			my $want = $colour && defined $cell->[1] ? $cell->[1] : '';
			if ($want ne $held) {
				$line .= length $want ? (length $held ? "\e[0;${want}m" : "\e[${want}m") : "\e[0m";
				$held = $want;
			}
			$line .= $cell->[0];
		}
		$line .= "\e[0m" if length $held;
		push @lines, $line;
	}
	return @lines;
}

sub text {
	my ($self) = @_;
	return $self->lines;
}

1;

__END__

=head1 NAME

Game::Terminal::Kit::Canvas - a grid of characters to draw a board on

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    use Game::Terminal::Kit::Canvas;
    use Game::Terminal::Kit::Frame;

    my $canvas = Game::Terminal::Kit::Canvas->new(width => 40, height => 12);

    $canvas->fill(0, 0, 40, 12, ' ', ground => '48;5;22');
    $canvas->box(2, 1, 5, 3, Game::Terminal::Kit::Frame::box('cursor', $ascii));
    $canvas->put(3, 2, 'K', ink => '1;31');
    $canvas->put(10, 2, 'your move', ink => '1');

    $screen->show([ $canvas->lines($screen) ]);

=head1 DESCRIPTION

A board whose pieces sit at places, drawn by putting each thing where it
goes and then asking for the rows. It saves a game from building each row of
the screen out of pieces of string in the right order.

A place is a column and a row counted from 0 at the top left. Anything put
outside the canvas is dropped, a piece at a time, so a thing half off the
edge shows the half that is on.

=head2 Colour

A cell has an ink and a ground, each the parameters of an SGR sequence such
as C<'1;31'> or C<'48;5;22'>. L</lines> writes a sequence only where the
style changes along a row and resets at the end of the row, and writes none
at all for a screen without colour, so a canvas is as cheap to print plain
as it is coloured.

=head2 Wide characters

Some glyphs take two columns: the Mahjong tiles, a Chinese chess piece. Put
them with C<< wide => 1 >> and each takes two cells, so what is put after
them lands where it will be seen. A wide glyph with only one column left at
the edge is dropped, and one that is half overwritten is cleared.

=head1 ATTRIBUTES

=head2 width

=head2 height

The size, in columns and rows.

=head2 cells

The grid itself, rows of cells. Read it if you must; write it with L</put>.

=head1 METHODS

Each but L</lines> and L</text> returns the canvas.

=head2 put

    $canvas->put($x, $y, $text, ink => '1;31', ground => '44', wide => 0);

The text, left to right from that place, a column a character or two with
C<wide>.

=head2 fill

    $canvas->fill($x, $y, $width, $height, $glyph, %style);

A rectangle of one character, a space when none is given.

=head2 box

    $canvas->box($x, $y, $width, $height, $glyphs, %style);

The outline of a rectangle, from the eight glyphs
L<Game::Terminal::Kit::Frame/box> returns. What is inside is left alone.
Nothing is drawn for a box less than two wide or two high.

=head2 wipe

Every cell back to a space with no style.

=head2 lines

    my @lines = $canvas->lines($screen);

One string a row. Coloured when given a L<Game::Terminal::Kit::Screen> whose
colour is on. Spaces at the end of a row are left off unless they have a
ground to show.

=head2 text

The rows with no colour, whatever the screen: what a test compares.

=head1 SEE ALSO

L<Game::Terminal::Kit>, L<Game::Terminal::Kit::Frame>,
L<Game::Terminal::Kit::Screen>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
