package Geo::ShapeFile::Shape::Index;
#use 5.010;  #  not yet
use strict;
use warnings;
use POSIX qw /floor/;
use Carp;
use autovivification;

our $VERSION = '3.03';

#  should also handle X cells
sub new {
    my ($class, $n, $x_min, $y_min, $x_max, $y_max) = @_;

    my $self = bless {}, $class;

    $n ||= 10;  #  need a better default?
    $n   = int $n;
    die 'Number of blocks must be positive and >=1'
      if $n <= 0;

    my $y_range = abs ($y_max - $y_min);
    my $y_tol   = $y_range / 1000;
    $y_range   += 2 * $y_tol;
    $y_min     -= $y_tol;
    $y_max     += $y_tol;

    my $block_ht = $y_range / $n;

    $self->{x_min} = $x_min;
    $self->{y_min} = $y_min;
    $self->{x_max} = $x_max;
    $self->{y_max} = $y_max;
    $self->{y_res} = $block_ht;
    $self->{y_n}   = $n;
    $self->{x_n}   = 1;

    my %blocks;
    my $y = $y_min;
    foreach my $i (1 .. $n) {
        my $key = $self->snap_to_index($x_min, $y);  #  index by lower left
        $blocks{$key} = [];
        $y += $block_ht;
    }
    $self->{containers} = \%blocks;

    return $self;
}

sub get_x_min {$_[0]->{x_min}}
sub get_x_max {$_[0]->{x_max}}
sub get_y_min {$_[0]->{y_min}}
sub get_y_max {$_[0]->{y_max}}
sub get_y_res {$_[0]->{y_res}}

#  return an anonymous array if we are out of the index bounds
sub _get_container_ref {
    my ($self, $id) = @_;

    no autovivification;

    my $containers = $self->{containers};
    my $container  = $containers->{$id} || [];

    return $container;
};

#  need to handle X coords as well
sub snap_to_index {
    my ($self, $x, $y) = @_;

    #my $x_min = $self->get_x_min;
    my $y_min = $self->get_y_min;
    my $y_res = $self->get_y_res;

    #  take the floor, but add a small tolerance to
    #  avoid precision issues with snapping
    my $partial = ($y - $y_min) / $y_res;
    my $y_block = floor ($partial * 1.001);

    return wantarray ? (0, $y_block) : "0:$y_block";
}

#  inserts into whichever blocks overlap the bounding box
sub insert {
    my ($self, $item, @bbox) = @_;

    my @index_id1 = $self->snap_to_index (@bbox[0, 1]);
    my @index_id2 = $self->snap_to_index (@bbox[2, 3]);

    my $insert_count = 0;
    foreach my $y ($index_id1[1] .. $index_id2[1]) {
        my $index_id  = "0:$y";  #  hackish
        my $container = $self->_get_container_ref ($index_id);
        push @$container, $item;
        $insert_count++;
    }

    return $insert_count;
}

#  $storage ref arg is for Tree::R compat - still needed?
sub query_point {
    my ($self, $x, $y, $storage_ref) = @_;

    my $index_id  = $self->snap_to_index ($x, $y);
    my $container = $self->_get_container_ref ($index_id);

    if ($storage_ref) {
        push @$storage_ref, @$container;
    }

    return wantarray ? @$container : [@$container];
}


1;

__END__
=head1 NAME

Geo::ShapeFile::Shape - Geo::ShapeFile utility class.

=head1 SYNOPSIS

  use Geo::ShapeFile::Shape::Index;

  my $index = Geo::ShapeFile::Shape->new;
  #  $pt1 and $pt2 are point objects in this example.  
  my $segment = [$pt1, $pt2];  #  example of something to pack into the index.
  my @bbox = ($x_min, $y_min, $x_max, $y_max);
  $index->insert($segment, @bbox);


=head1 ABSTRACT

  This is a utility class for L<Geo::ShapeFile> that indexes shape objects.

=head1 DESCRIPTION

This is a 2-d block-based index class for Geo::ShapeFile::Shape objects.
It probably has more generic applications, of course.

It uses a flat 2-d structure comprising a series of blocks of full width
which slice the shape along the y-axis (it should really also use blocks
along the x axis).

The index coordinates are simply the number of blocks across and up
from the minimum coordinate specified in the new() call.  These are stoed as
strings jpoined by a colon, so 0:0 is the lower left.
Negative block coordinates can occur if data are added which fall outside the
speficied bounds.  This should not affect the index, though, as it is merely
a relative offset.

It is used internally by Geo::ShapeFile::Shape, so look there for examples.  
The method names are adapted from Tree::R to make transition easier during development,
albeit the argument have morphed so it is not a drop-in replacement. 


=head2 EXPORT

None by default.

=head1 METHODS

=over 4

=item new($n_blocks_y, @bbox)

Creates a new Geo::ShapeFile::Shape::Index objectand returns it.

$n_blocks_y is the number of blocks along the y-axis.
@bbox is the bounding box the index represents (x_min, y_min, x_max, y_max).

=item insert($item, $min_x, $min_y, $max_x, $max_y)

Adds item $item to the blocks which overlap with the specified bounds.
Returns the number of blocks the item was added to.

=item query_point($x, $y)

Returns an array of objects on the block contains point $x,$y.
Returns an arrayref in scalar context.


=item get_x_max() get_x_min() get_y_max() get_y_min()

Bounds of the index, as set in the call to ->new().
There is no guarantee they are the bounds of the data, as
data outside the original bounds can be indexed.

=item get_y_res()

Block resolution along the y-axis.

=item snap_to_index ($x, $y)

Returns the index key associated with point $x,$y.
Does not check if it is outside the bounds of the index,
so negative index values are possible.


=back

=head1 REPORTING BUGS

Please send any bugs, suggestions, or feature requests to
  L<https://github.com/shawnlaffan/Geo-ShapeFile/issues>.

=head1 SEE ALSO

L<Geo::ShapeFile::Shape>

=head1 AUTHOR

Shawn Laffan, E<lt>shawnlaffan@gmail.comE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright 2014-2023 by Shawn Laffan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
