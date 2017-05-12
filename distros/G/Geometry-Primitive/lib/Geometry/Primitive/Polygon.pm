package Geometry::Primitive::Polygon;
use Moose;
use MooseX::Storage;

with qw(Geometry::Primitive::Shape MooseX::Clone MooseX::Storage::Deferred);

has 'points' => (
    traits => [ qw(Array Clone) ],
    is => 'rw',
    isa => 'ArrayRef[Geometry::Primitive::Point]',
    default => sub { [] },
    handles => {
        add_point   => 'push',
        clear_points=> 'clear',
        get_point   => 'get',
        point_count => 'count'
    }
);

sub area {
    my ($self) = @_;

    # http://mathworld.wolfram.com/PolygonArea.html
    my $area = 0;
    my $last = $self->get_point(0);
    for (my $i = 1; $i < $self->point_count; $i++) {
        my $curr = $self->get_point($i);

        $area += ($last->x * $curr->y) - ($curr->x * $last->y);
        $last = $curr;
    }

    return abs($area / 2);
}

sub point_end {
    my ($self) = @_;

    return $self->get_point($self->point_count - 1);
}

sub point_start {
    my ($self) = @_;

    return $self->get_point(0);
}

sub scale {
    my ($self, $amount) = @_;

    foreach my $p (@{ $self->points }) {
        $p->x($p->x * $amount);
        $p->y($p->y * $amount);
    }

}

__PACKAGE__->meta->make_immutable;

no Moose;
1;

__END__

=head1 NAME

Geometry::Primitive::Polygon - Closed shape with an arbitrary number of points.

=head1 DESCRIPTION

Geometry::Primitive::Polygon represents a two dimensional figure bounded by a
series of points that represent a closed path.

=head1 SYNOPSIS

  use Geometry::Primitive::Polygon;

  my $poly = Geometry::Primitive::Polygon->new;
  $poly->add_point($point1);
  $poly->add_point($point2);
  $poly->add_point($point3);
  # No need to close the path, it's handled automatically

=head1 ATTRIBUTES

=head2 points

Set/Get the arrayref of points that make up this Polygon.

=head1 METHODS

=head2 new

Creates a new Geometry::Primitive::Polygon

=head2 area

Area of this polygon.  Assumes it is non-self-intersecting.

=head2 add_point

Add a point to this polygon.

=head2 clear_points

Clears all points from this polygon.

=head2 point_count

Returns the number of points that bound this polygon.

=head2 get_point

Returns the point at the specified offset.

=head2 point_end

Get the end point.  Provided for Shape role.

=head2 point_start

Get the start point.  Provided for Shape role.

=head2 scale ($amount)

Scale this this polygon by the supplied amount.

=head1 AUTHOR

Cory Watson <gphat@cpan.org>

=head1 COPYRIGHT & LICENSE

You can redistribute and/or modify this code under the same terms as Perl
itself.