package Karel::Grid;

=head1 NAME

Karel::Grid

=head1 DESCRIPTION

Represents the map in which the robot moves.

=head1 METHODS

=over 4

=item 'Karel::Grid'->new

  my $grid = 'Karel::Grid'->new( x => 10, y => 12 );

The constructor creates an empty grid of the given size.

=cut

use warnings;
use strict;

use Carp;
use Karel::Util qw{ positive_int m_to_n };
use List::Util qw{ any none };
use Moo;
use namespace::clean;

=item $grid->x, $grid->y

    my ($x, $y) = map $grid->$_, qw( x y );

Returns the size of the grid.

=cut

has [qw[ x y ]] => (is       => 'ro',
                    isa      => \&positive_int,
                    required => 1,
                   );


has _grid => ( is  => 'rw',
               isa => sub {
                   croak "Grid should be an AoA!"
                       if 'ARRAY' ne ref $_[0]
                       || any { 'ARRAY' ne ref } @{ $_[0] };
               },
             );

# Create an empty grid
sub BUILD {
    my ($self) = @_;
    my ($x, $y) = map $self->$_, qw( x y );
    $self->_grid([ map [ (' ') x ($y + 2) ], 0 .. $x + 1 ]);
    $self->_set($_, 0, 'W'), $self->_set($_, $y + 1, 'W') for 0 .. $x + 1;
    $self->_set(0, $_, 'W'), $self->_set($x + 1, $_, 'W') for 0 .. $y + 1;
    return $self
}

=item $grid->at($x, $y)

Returns a space if there's nothing at the given position. For marks,
it returns 1 - 9. For walls, it returns "W" (outer walls) or "w"
(inner walls).

=cut

sub at {
    my ($self, $x, $y) = @_;
    m_to_n($x, 0, $self->x + 1);
    m_to_n($y, 0, $self->y + 1);
    return $self->_grid->[$x][$y]
}


sub _set {
    my ($self, $x, $y, $what) = @_;
    m_to_n($x, 0, $self->x + 1);
    m_to_n($y, 0, $self->y + 1);
    croak "Unknown object '$what'."
        if none { $_ eq $what } ' ', '0' .. '9', 'w', 'W';
    $self->_grid->[$x][$y] = $what;
}

=item $grid->build_wall($x, $y)

Builds a wall ("w") at the given coordinates.

=cut

sub build_wall {
    my ($self, $x, $y) = @_;
    m_to_n($x, 1, $self->x);
    m_to_n($y, 1, $self->y);
    $self->_set($x, $y, 'w');
}

=item $gird->remove_wall($x, $y)

Removes a wall ("w") from the given coordinates. Dies if there's no
wall.

=cut

sub remove_wall {
    my ($self, $x, $y) = @_;
    croak "Not a removable wall at $x, $y." unless 'w' eq $self->at($x, $y);
    $self->_set($x, $y, ' ');
}

=item $grid->drop_mark($x, $y)

Drop a mark at the given position. There must be an empty place or
less than 9 marks, otherwise the method dies.

=cut

sub drop_mark {
    my ($self, $x, $y) = @_;
    my $previous = $self->at($x, $y);
    croak "Can't drop mark to '$previous'."
        if none { $_ eq $previous } ' ', '1' .. '8';
    $previous = 0 if ' ' eq $previous;
    $self->_set($x, $y, $previous + 1);
}

=item $grid->pick_mark($x, $y)

Pick up a mark from the given position. Dies if there's no mark.

=cut

sub pick_mark {
    my ($self, $x, $y) = @_;
    my $previous = $self->at($x, $y);
    croak "Can't pick mark from '$previous'."
        if none { $_ eq $previous } '1' .. '9';
    $self->_set($x, $y, ($previous - 1) || ' ');
}

=item $grid->clear($x, $y)

Set the given position to empty (" ").

=cut

sub clear {
    my ($self, $x, $y) = @_;
    m_to_n($x, 1, $self->x);
    m_to_n($y, 1, $self->y);
    $self->_set($x, $y, ' ');
}

=back

=cut

__PACKAGE__
