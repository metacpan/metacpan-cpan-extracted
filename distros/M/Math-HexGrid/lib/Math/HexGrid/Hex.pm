use strict;
use warnings;
package Math::HexGrid::Hex;
$Math::HexGrid::Hex::VERSION = '0.03';
use overload
  '""' => 'to_string',
  fallback => 1;

sub to_string { $_[0]->{id} }


sub new
{
  my ($class, $q, $r, $s) = @_;

  # if s wasnt provided, calculate it
  $s ||= - $q - $r;

  die 'Invalid coordinates!'
    unless defined $q && defined $r && defined $s
      && $q + $r + $s == 0;

  bless { q => $q, r => $r, s => $s, id => "$q,$r" }, $class;
}


sub id { $_[0]->{id} }


sub hex_equal
{
  my ($self, $hex) = @_;

  $self->{q} == $hex->{q}
    && $self->{r} == $hex->{r}
    && $self->{s} == $hex->{s};
}


sub is_colliding { $_[0]->hex_equal($_[1]) }


sub hex_add
{
  my ($self, $hex) = @_;
  Math::HexGrid::Hex->new(
    $self->{q} + $hex->{q},
    $self->{r} + $hex->{r},
    $self->{s} + $hex->{s},
  );
}


sub hex_subtract
{
  my ($self, $hex) = @_;
  Math::HexGrid::Hex->new(
    $self->{q} - $hex->{q},
    $self->{r} - $hex->{r},
    $self->{s} - $hex->{s},
  );
}


sub hex_multiply
{
  my ($self, $hex) = @_;
  Math::HexGrid::Hex->new(
    $self->{q} * $hex->{q},
    $self->{r} * $hex->{r},
    $self->{s} * $hex->{s},
  );
}

sub hex_length
{
  my ($self) = @_;
  int((abs($self->{q}) + abs($self->{r}) + abs($self->{s})) / 2);
}


sub hex_distance
{
  my ($self, $hex) = @_;
  $self->hex_subtract($hex)->hex_length;
}

my @hex_directions = (
  Math::HexGrid::Hex->new(1,0,-1),
  Math::HexGrid::Hex->new(1,-1,0),
  Math::HexGrid::Hex->new(0,-1,1),
  Math::HexGrid::Hex->new(-1,0,1),
  Math::HexGrid::Hex->new(-1,1,0),
  Math::HexGrid::Hex->new(0,1,-1),
);

sub _hex_direction
{
  # this will handle directions > 6 and < 0
  $hex_directions[(6 + ($_[0] % 6)) % 6];
}


sub hex_neighbor
{
  my ($self, $direction) = @_;
  $self->hex_add(_hex_direction($direction));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Math::HexGrid::Hex

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use Math::HexGrid::Hex;

  my $hex = Math::HexGrid:Hex->new(1,-1); # axial notation
  my $hex = Math::HexGrid:Hex->new(1,-1, 0 ); # cube notation

=head1 DESCRIPTION

This module is a class for representing hexagons on hex grids. It uses the
cube or axial (trapezoidal) coordinate notation. It provides some basic
utility methods for hex operations like add, subtract, multiply, distance
and neighbor.

=head1 NAME

Math::HexGrid::Hex - a hex class for use with hex grids

=head1 METHODS

=head2 new ($q, $r, $s)

Creates a new Hex object, the C<$s> integer is optional.

=head2 id

Returns a comma-separated string of the Hex's q and r coordinates.

=head2 hex_equal ($hex)

Compare two Hex objects for equality

=head2 is_colliding ($hex)

Same as C<hex_equal>.

=head2 hex_add($hex)

Adds another Hex to the object and returns a new Hex object.

=head2 hex_subtract ($hex)

Subtract another Hex object and return a new Hew object.

=head2 hex_multiply ($hex)

Multiply the Hex by another Hex and return a new Hex object.

=head2 hex_distance ($hex)

Get the distance from this Hex object to another.

=head2 hex_neighbor ($direction)

Returns a new neighboring hex in the direction given (0-5).

=head1 AUTHOR

David Farrell <dfarrell@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Farrell.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
