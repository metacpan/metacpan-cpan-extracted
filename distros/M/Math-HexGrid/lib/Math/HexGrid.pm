use strict;
use warnings;
package Math::HexGrid;
$Math::HexGrid::VERSION = '0.03';
# ABSTRACT: Math::HexGrid - create hex coordinate grids

use Math::HexGrid::Hex;
use List::Util qw/min max/;




sub new_hexagon
{
  my ($class, $radius) = @_;

  my %map;
  for (my $q = - $radius; $q <= $radius; $q++)
  {
    my $r1 = max(-$radius, -$q - $radius);
    my $r2 = min($radius, -$q + $radius);

    for (my $r = $r1; $r <= $r2; $r++)
    {
      $map{"$q$r"} = Math::HexGrid::Hex->new($q, $r);
    }
  }

  bless {
    map  => \%map,
    type => 'hexagon',
  }, $class;
}


sub new_triangle
{
  my ($class, $rows) = @_;

  my %map;
  for (my $q = 0; $q <= $rows; $q++)
  {
    for (my $r = 0; $r <= $rows - $q; $r++)
    {
      $map{"$q$r"} = Math::HexGrid::Hex->new($q, $r);
    }
  }
  bless {
    map  => \%map,
    type => 'triangle',
  }, $class;
}


sub hexgrid { $_[0]->{map} }


sub hex
{
  my ($self, $q, $r) = @_;
  $self->{map}{"$q$r"};
}


sub count_sides
{
  my ($self) = @_;
  my $n = keys %{$self->{map}};

  if ($self->{type} eq 'hexagon')
  {
    ($n-1) * 3 + $n-1 + 6;
  }
  elsif ($self->{type} eq 'triangle')
  {
    $n * 4 + 3;
  }
  else
  {
    die "Unknown map type!";
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Math::HexGrid - Math::HexGrid - create hex coordinate grids

=head1 VERSION

version 0.03

=head1 DESCRIPTION

This module is for creating hex grids of C<Math::HexGrid::Grid> objects. For
now it only supports hexagonally-shaped grids. It supports both cube and
axial (trapezoidal) coordinate systems.

=head1 METHODS

=head2 new_hexagon ($radius)

Constructs a new hexagonally-shaped grid of size C<$radius>.

=head2 new_triangle ($rows)

Constructs a new triangle-shaped grid with C<$rows> number of rows.

=head2 hexgrid

Returns a hashref of all hexes in the grid.

=head2 hex ($q, $r)

Returns the hex at location C<$q> and C<$r>.

=head2 count_sides

Returns a count of all unique sides (edges) in the grid.

=head1 SEE ALSO

This code was helped by Amit Patel's L<articles|http://www.redblobgames.com/grids/hexagons/> on hexagonal grids.

=head1 AUTHOR

David Farrell <dfarrell@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Farrell.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
