#  SVG maze output
#  Performs transformation, cleanup, and printing of output of Games::Maze

package Games::Maze::SVG::Hex;

use base Games::Maze::SVG::HexCells;

use Carp;
use Games::Maze;
use strict;
use warnings;

=head1 NAME

Games::Maze::SVG::Hex - Build hexagonal mazes in SVG.

=head1 VERSION

Version 0.90

=cut

our $VERSION = 0.90;

=head1 SYNOPSIS

Games::Maze::SVG::Hex uses the Games::Maze module to create hexagonal mazes in
SVG.

    use Games::Maze::SVG;

    my $foo = Games::Maze::SVG->new( 'Hex' );
    ...

=cut

=head1 FUNCTIONS

=cut

# ----------------------------------------------
#  Subroutines

=over 4

=item new

Create a new Games::Maze::SVG object. Supports the following named parameters:

Takes one positional parameter that is the maze type: Rect, RectHex, or Hex

=over 4

=item wallform

String naming the wall format. Legal values are bevel, round, roundcorners,
and straight.

=item crumb

String describing the breadcrumb design. Legal values are dash,
dot, line, and none

=item dx

The size of the tiles in the X direction.

=item dy

The size of the tiles in the Y direction.

=item dir

Directory in which to find the ecmascript for the maze interactivity. Should
either be relative, or in URL form.

=back

=cut

sub  new
{
    my $class = shift;

    my $obj = Games::Maze::SVG::HexCells->new( @_ );
    $obj->{mazeparms}->{form} = 'Hexagon';

    # rebless into this class.
    return bless $obj, $class;
}


=item is_hex

Method returns true.

=cut

sub  is_hex
{
    return 1;
}


=item is_hex_shaped

Method returns true.

=cut

sub  is_hex_shaped
{
    return 1;
}


=item convert_sign_position

Convert the supplied x and y coordinates into the appropriate real coordinates
for a the position of the exit sign.

=over 4

=item $x x coord from the maze

=item $y y coord from the maze

=back

returns a two element list containing (x, y).

=cut

sub convert_sign_position
{
    my $self = shift;
    my ($x, $y) = @_;

    $x *= $self->dx();
    $y *= $self->dy();

    # left or right
    if($x > $self->{width}/2)
    {
        $x += $self->dx();
    }
    else
    {
        $x -= $self->dx();
    }

    # adjust bottom
    if($y > $self->{height}/2)
    {
        $y += 3*$self->dy();
    }
    else
    {
        $y -= $self->dy();
    }

    return ($x, $y);
}

=back

=head1 AUTHOR

G. Wade Johnson, C<< <wade@anomaly.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-game-maze-svg@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Maze-SVG>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks go to Valen Johnson and Jason Wood for extensive test play of the
mazes.

=head1 COPYRIGHT & LICENSE

Copyright 2004-2006 G. Wade Johnson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
