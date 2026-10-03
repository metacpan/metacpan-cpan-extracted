package Kubernetes::Comb::SVG::Layout;
# ABSTRACT: Places cells in groups and a honeycomb, by dependency depth or packed


use Moo;
use Types::Common::Numeric qw( PositiveInt PositiveNum PositiveOrZeroNum );
use Types::Standard qw( ArrayRef Bool Enum Object );
use namespace::autoclean;

our $VERSION = '0.001';

has cells => ( is => 'ro', isa => ArrayRef[Object], default => sub { [] } );


has columns => ( is => 'ro', isa => PositiveInt, default => 6 );


# Whether columns came from the caller: the packed mode must tell a given 6
# from the default 6.
has _columns_given => ( is => 'rwp', isa => Bool, init_arg => undef, default => 0 );

sub BUILD {
  my ( $self, $args ) = @_;
  $self->_set__columns_given(1) if exists $args->{columns};
}

has mode => ( is => 'ro', isa => Enum[qw( depth packed )], default => 'depth' );


has rows => ( is => 'ro', isa => PositiveInt, predicate => 'has_rows' );


has aspect => ( is => 'ro', isa => PositiveNum, default => 16 / 9 );


has frame_width => ( is => 'ro', isa => PositiveOrZeroNum, default => 0 );


has frame_height => ( is => 'ro', isa => PositiveOrZeroNum, default => 0 );


has size => ( is => 'ro', isa => PositiveNum, default => 56 );


#### Geometry, all derived from size

# Pointy-top hexagon: flat sides left and right, a corner at top and bottom.
sub hex_width { sqrt(3) * $_[0]->size }


sub hex_height { 2 * $_[0]->size }


# Air between the sides of two neighbouring hexagons.
sub gap { $_[0]->size / 7 }


# Centre to centre inside a row.
sub step_x { $_[0]->hex_width + $_[0]->gap }


# Centre to centre between two rows: the same distance as inside a row, seen
# along the diagonal, so the gap is the same on all six sides.
sub step_y { $_[0]->step_x * sqrt(3) / 2 }


# Band above a group that holds its heading; the baseline sits inside it.
sub heading_height { $_[0]->size * 0.6 }


sub heading_baseline { $_[0]->size * 0.4 }


# Between the lowest hexagon of a group and the heading band of the next.
sub group_gap { $_[0]->size * 0.35 }


#### Layout

sub layout {
  my ( $self ) = @_;
  my $cells = $self->_unique_cells;
  my $deps  = $self->_dependencies($cells);
  my $depth = $self->_depths($deps);

  my ( %by_group, $unnamed );
  for my $cell (@$cells) {
    my $group = $cell->group;
    push @{ defined $group ? $by_group{$group} ||= [] : $unnamed ||= [] }, $cell;
  }
  my @groups = map { [ $_, $by_group{$_} ] } sort keys %by_group;
  push @groups, [ undef, $unnamed ] if $unnamed;
  my $headings = @groups > 1 || ( @groups && defined $groups[0][0] );

  my $packed  = $self->mode eq 'packed';
  my $columns = $packed
    ? $self->_packed_columns( [ map { scalar @{ $_->[1] } } @groups ], $headings )
    : undef;

  my $radius = $self->size;
  my ( @placed, @placed_groups );
  my ( $width, $top ) = ( 0, 0 );
  for my $entry (@groups) {
    my ( $name, $members ) = @$entry;
    $top += $self->group_gap if @placed_groups;
    my $comb_top = $top + ( $headings ? $self->heading_height : 0 );
    my @rows = $packed
      ? $self->_packed_rows( $members, $columns || $self->_ceil( @$members / $self->rows ) )
      : $self->_rows( $members, $depth );
    for my $row ( 0 .. $#rows ) {
      my $shift = $row % 2 ? $self->step_x / 2 : 0;
      for my $column ( 0 .. $#{ $rows[$row] } ) {
        my $cell = $rows[$row][$column];
        my $x = $shift + $self->hex_width / 2 + $column * $self->step_x;
        my $right = $x + $self->hex_width / 2;
        $width = $right if $right > $width;
        push @placed, {
          id     => $cell->id,
          name   => $cell->name,
          group  => $name,
          depth  => $depth->{ $cell->id },
          row    => $row,
          column => $column,
          x      => $self->_round($x),
          y      => $self->_round( $comb_top + $radius + $row * $self->step_y )
        };
      }
    }
    my $bottom = $comb_top + $self->hex_height + $#rows * $self->step_y;
    push @placed_groups, {
      name    => $name,
      heading => $headings
        ? { x => 0, y => $self->_round( $top + $self->heading_baseline ) }
        : undef,
      y       => $self->_round($top),
      height  => $self->_round( $bottom - $top )
    };
    $top = $bottom;
  }

  my @edges;
  for my $id ( sort keys %$deps ) {
    push @edges, map { { from => $id, to => $_ } }
      sort grep { $_ ne $id } @{ $deps->{$id} };
  }

  return {
    width  => $self->_round($width),
    height => $self->_round($top),
    groups => \@placed_groups,
    cells  => \@placed,
    edges  => \@edges
  };
}


# The cells with an id, the first of each id.
sub _unique_cells {
  my ( $self ) = @_;
  my %seen;
  return [ grep { defined $_->id && !$seen{ $_->id }++ } @{ $self->cells } ];
}

# id => ids of the cells it depends on, only those in the picture.
sub _dependencies {
  my ( $self, $cells ) = @_;
  my %known = map { $_->id => 1 } @$cells;
  my %deps;
  for my $cell (@$cells) {
    my %seen;
    $deps{ $cell->id } = [
      grep { defined && $known{$_} && !$seen{$_}++ } @{ $cell->dependencies || [] }
    ];
  }
  return \%deps;
}

# id => depth. Tarjan's strongly connected components with an explicit stack,
# so neither a cycle nor a long chain can loop or exhaust the call stack. A
# component is complete only after everything it depends on, so its depth is
# known the moment it is closed; the cells of a cycle get the same one.
sub _depths {
  my ( $self, $deps ) = @_;
  my ( %index, %low, %on_stack, %depth, @stack );
  my $counter = 0;
  for my $root ( sort keys %$deps ) {
    next if defined $index{$root};
    my @work = ( [ $root, 0 ] );
    while (@work) {
      my $frame = $work[-1];
      my $id    = $frame->[0];
      unless ( defined $index{$id} ) {
        $index{$id} = $low{$id} = $counter++;
        push @stack, $id;
        $on_stack{$id} = 1;
      }
      my $descend;
      while ( $frame->[1] < @{ $deps->{$id} } ) {
        my $dep = $deps->{$id}[ $frame->[1]++ ];
        unless ( defined $index{$dep} ) {
          $descend = $dep;
          last;
        }
        $low{$id} = $index{$dep} if $on_stack{$dep} && $index{$dep} < $low{$id};
      }
      if ( defined $descend ) {
        push @work, [ $descend, 0 ];
        next;
      }
      if ( $low{$id} == $index{$id} ) {
        my ( @members, %member );
        while (@stack) {
          my $member = pop @stack;
          delete $on_stack{$member};
          $member{$member} = 1;
          push @members, $member;
          last if $member eq $id;
        }
        my $level = 0;
        for my $dep ( map { @{ $deps->{$_} } } @members ) {
          next if $member{$dep};
          $level = $depth{$dep} + 1 if $depth{$dep} >= $level;
        }
        $depth{$_} = $level for @members;
      }
      pop @work;
      next unless @work;
      my $parent = $work[-1][0];
      $low{$parent} = $low{$id} if $low{$id} < $low{$parent};
    }
  }
  return \%depth;
}

# The drawn rows of one group: one depth after the other, each sorted by
# name and cut into rows of at most `columns` cells.
sub _rows {
  my ( $self, $cells, $depth ) = @_;
  my %by_depth;
  push @{ $by_depth{ $depth->{ $_->id } } }, $_ for @$cells;
  my @rows;
  for my $level ( sort { $a <=> $b } keys %by_depth ) {
    my @sorted = sort { $a->name cmp $b->name || $a->id cmp $b->id }
      @{ $by_depth{$level} };
    push @rows, [ splice @sorted, 0, $self->columns ] while @sorted;
  }
  return @rows;
}

#### Packed

# The column count all blocks share, or nothing when `rows` decides it block
# by block. A given `columns` wins; else, without `rows`, the count whose
# content, with the caller's frame around it, comes closest to `aspect`,
# compared as a ratio so that too wide and too tall weigh the same.
sub _packed_columns {
  my ( $self, $sizes, $headings ) = @_;
  return $self->columns if $self->_columns_given;
  return if $self->has_rows;
  my ( $most ) = sort { $b <=> $a } @$sizes;
  my ( $best, $miss ) = ( 1 );
  for my $columns ( 1 .. $most || 1 ) {
    my ( $width, $height ) = $self->_packed_extent( $sizes, $columns, $headings );
    my $off = abs( log( ( $width + $self->frame_width ) / ( $height + $self->frame_height ) )
      - log( $self->aspect ) );
    ( $best, $miss ) = ( $columns, $off ) if !defined $miss || $off < $miss;
  }
  return $best;
}

# Width and height of the content when blocks of these sizes are packed into
# $columns: the same sums `layout` makes while it places the cells.
sub _packed_extent {
  my ( $self, $sizes, $columns, $headings ) = @_;
  my ( $width, $height ) = ( 0, 0 );
  for my $index ( 0 .. $#$sizes ) {
    my $rows = $self->_ceil( $sizes->[$index] / $columns );
    for my $row ( 0 .. $rows - 1 ) {
      my $count = $row < $rows - 1 ? $columns : $sizes->[$index] - $row * $columns;
      my $right = ( $row % 2 ? $self->step_x / 2 : 0 )
        + $self->hex_width + ( $count - 1 ) * $self->step_x;
      $width = $right if $right > $width;
    }
    $height += ( $index ? $self->group_gap : 0 )
      + ( $headings ? $self->heading_height : 0 )
      + $self->hex_height + ( $rows - 1 ) * $self->step_y;
  }
  return ( $width || 1, $height || 1 );
}

# The drawn rows of one packed block: sorted by id, cut into rows of
# $columns cells.
sub _packed_rows {
  my ( $self, $cells, $columns ) = @_;
  my @sorted = sort { $a->id cmp $b->id } @$cells;
  my @rows;
  push @rows, [ splice @sorted, 0, $columns ] while @sorted;
  return @rows;
}

sub _ceil {
  my ( $self, $value ) = @_;
  return int($value) + ( $value > int($value) ? 1 : 0 );
}

# Two decimals, as a number: the same on every platform, and no '-0'.
sub _round {
  my ( $self, $value ) = @_;
  return sprintf( '%.2f', $value ) + 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::Comb::SVG::Layout - Places cells in groups and a honeycomb, by dependency depth or packed

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Kubernetes::Comb::SVG::Layout;

  my $layout = Kubernetes::Comb::SVG::Layout->new(
    cells   => \@cells,
    columns => 6,
    size    => 56
  )->layout;

  for my $cell ( @{ $layout->{cells} } ) {
    # $cell->{id}, $cell->{x}, $cell->{y}, $cell->{row}, $cell->{column}
  }

  # packed, for a 16:9 screen: no dependency rows, a compact block
  my $packed = Kubernetes::Comb::SVG::Layout->new(
    cells  => \@cells,
    mode   => 'packed',
    aspect => 16 / 9
  )->layout;

=head1 DESCRIPTION

Places cells in a honeycomb and returns plain data. It knows neither the
custom resource nor SVG: a cell is anything answering C<id>, C<name>,
C<group> and C<dependencies>, as L<Kubernetes::Comb::SVG::Cell> does.

There are two modes, see L</mode>. In C<depth>, the default, a cell sits in
the row of its dependency depth. In C<packed>, the status monitor, the
dependencies play no part in placement: the cells of a group are sorted by
C<id> and fill one compact honeycomb, its shape chosen by L</columns>, else
L</rows>, else L</aspect>. The rules below on groups, hexagons and the result
hold for both; those on depth and rows by name are the C<depth> mode.

=over

=item * Groups are stacked top to bottom in name order, the cells without a
group last. With more than one group, or one named group, every group has a
heading; a lone unnamed group has none.

=item * Inside a group a cell sits in the row of its dependency depth: depth 0
without a dependency in the picture, else one below its deepest dependency.
Depth is computed over all cells, not per group, so an edge between groups
still points the right way. Dependencies on ids that are not among the cells
do not count.

=item * The cells of a dependency cycle share one depth, one below the deepest
dependency outside the cycle. A cell depending on itself counts as no
dependency. A cycle, or a long chain, never loops or dies.

=item * Rows are sorted by name (then by id), and a depth with more cells than
L</columns> wraps into further rows. A group therefore has one or more rows
for each depth that occurs in it; a depth no cell of the group has is
skipped, so the row number is not the depth.

=item * Pointy-top hexagons; every second row is shifted by half a step, so
rows interlock.

=back

=head2 cells

Default empty. ArrayRef of cell objects, each answering C<id>, C<name>,
C<group> (a string or C<undef>) and C<dependencies> (the ids it depends on).
Of several with one C<id> the first is kept; an object without an C<id> is
left out.

=head2 columns

Default C<6>, a positive integer. Cells per row before a row wraps. In the
packed L</mode> it is the cells per row of every block, and only when it was
given to the constructor: the default does not count there, so L</rows> and
L</aspect> can apply.

=head2 mode

Default C<depth>: rows by dependency depth, as described above. C<packed>
ignores the dependencies for placement: the cells of a group are sorted by
C<id> and fill the rows left to right, top to bottom, so a cell keeps its
place as long as the set of cells is the same. Each group is its own packed
block. The grid comes from L</columns> when given, else from L</rows>, else
from L</aspect>. The C<depth> of each cell and the C<edges> in the result are
computed the same way in both modes; in C<packed> the depth is data only and
does not decide the row.

=head2 rows

Optional, a positive integer; C<packed> only, and only without a given
L</columns>. Every block gets the fewest columns that fit its cells into this
many rows, so a block has at most C<rows> rows -- fewer when its cells do not
fill them.

=head2 aspect

Default C<16/9>, a positive number; C<packed> only, and only with neither a
given L</columns> nor L</rows>. Width divided by height of the area to fill.
All blocks get the one column count whose picture -- C<width> by C<height> of
L</layout>, group headings included, plus the L</frame_width> and
L</frame_height> -- comes closest to it; of two equally close the one with
fewer columns.

=head2 frame_width

Default C<0>, a number of at least zero. The width the caller will add around
the content (padding on both sides), so that L</aspect> is met by the whole
picture and not by the honeycomb alone. Only counted when choosing the
columns by C<aspect>; the result of L</layout> never includes it.

=head2 frame_height

Default C<0>, a number of at least zero. The height the caller will add around
the content (padding, title, legend); see L</frame_width>.

=head2 size

Default C<56>, a positive number. Radius of a hexagon, centre to corner, in
the units of the result. Every measure below derives from it.

=head2 hex_width

Width of one pointy-top hexagon, flat side to flat side: C<sqrt(3) * size>.

=head2 hex_height

Height of one hexagon, corner to corner: C<2 * size>.

=head2 gap

Air between the sides of two neighbouring hexagons: C<size / 7>.

=head2 step_x

Distance between the centres of two neighbours in a row:
L</hex_width> plus L</gap>.

=head2 step_y

Distance between the centres of two rows: L</step_x> C<* sqrt(3) / 2>, so the
gap is the same on all six sides of a hexagon.

=head2 heading_height

Room above a group for its heading: C<0.6 * size>. Only taken when the
picture has headings.

=head2 heading_baseline

Distance of the heading's baseline from the top of its group: C<0.4 * size>.

=head2 group_gap

Space between the lowest hexagon of a group and the heading band of the next:
C<0.35 * size>.

=head2 layout

  my $layout = $self->layout;

Places the cells and returns a plain hash. With the defaults (C<size> 56) and
two cells in one group, C<db> without dependency and C<api> depending on it:

  {
    width  => 149.49,
    height => 236.53,
    groups => [
      { name => 'alpha', heading => { x => 0, y => 22.4 }, y => 0, height => 236.53 }
    ],
    cells => [
      { id => 'lab/db',  name => 'db',  group => 'alpha', depth => 0,
        row => 0, column => 0, x => 48.5,  y => 89.6 },
      { id => 'lab/api', name => 'api', group => 'alpha', depth => 1,
        row => 1, column => 0, x => 100.99, y => 180.53 }
    ],
    edges => [ { from => 'lab/api', to => 'lab/db' } ]
  }

=over

=item * C<width>, C<height>: the extent of the content, which starts at
C<0,0>. The canvas is the caller's: padding and title are not included.

=item * C<groups>: one hash per group, in order. C<name> is the group name,
C<undef> for the cells without one. C<heading> is C<< { x, y } >>, the left
end of the baseline of the heading, or C<undef> when the picture has no
headings. C<y> and C<height> span the group including its heading band.

=item * C<cells>: one hash per cell, group by group and row by row. C<id>,
C<name> and C<group> are the cell's; C<depth> is the dependency depth over the
whole picture; C<row> and C<column> count inside the group; C<x> and C<y> are
the centre of the hexagon.

=item * C<edges>: C<< { from, to } >> by C<id>, from a cell to a cell it
depends on, sorted by C<from> then C<to>, without duplicates. Only ids among
the cells; a cell depending on itself gives none.

=back

All coordinates are rounded to two decimals, so the result is the same on
every platform. No cells give width and height C<0> and empty lists.

=head1 SEE ALSO

=over

=item * L<Kubernetes::Comb::SVG>

=item * L<Kubernetes::Comb::SVG::Cell>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-kubernetes-comb-svg/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
