package Geometry::Primitive::Rectangle;
use Moose;
use MooseX::Storage;

use Geometry::Primitive::Point;

with qw(Geometry::Primitive::Shape MooseX::Clone MooseX::Storage::Deferred);

has 'height' => (
    is => 'rw',
    isa => 'Num',
    required => 1
);
has 'origin' => (
    is => 'rw',
    isa => 'Geometry::Primitive::Point',
    coerce => 1
);
has 'width' => (
    is => 'rw',
    isa => 'Num',
    required => 1
);

sub area {
    my ($self) = @_;

    return $self->height * $self->width;
}

sub get_points {
    my ($self) = @_;

    my @points;
    push(@points, $self->origin);
    push(@points, Geometry::Primitive::Point->new(
        x => $self->origin->x + $self->width, y => $self->origin->y
    ));
    push(@points, Geometry::Primitive::Point->new(
        x => $self->origin->x, y => $self->origin->y + $self->height
    ));
    push(@points, Geometry::Primitive::Point->new(
        x => $self->origin->x + $self->width, y => $self->origin->y + $self->height
    ));
    return \@points
}

sub scale {
    my ($self, $amount) = @_;

    $self->width($self->width * $amount);
    $self->height($self->height * $amount);
}

sub point_end {
    my ($self) = @_; return $self->origin;
}

sub point_start {
    my ($self) = @_; return $self->origin;
}

__PACKAGE__->meta->make_immutable;

no Moose;
1;

__END__

=head1 NAME

Geometry::Primitive::Rectangle - 4 sided polygon

=head1 DESCRIPTION

Geometry::Primitive::Rectangle a space defined by a point, a width and a
height.

=head1 SYNOPSIS

  use Geometry::Primitive::Rectangle;

  my $poly = Geometry::Primitive::Rectangle->new();
  $poly->add_point($point1);
  $poly->height(100);
  $poly->width(100);

=head1 ATTRIBUTES

=head2 height

Set/Get the height of this Rectangle.

=head2 origin

Set/Get the origin of this rectangle.

=head2 width

Set/Get the width of this Rectangle.

=head1 METHODS

=head2 new

Creates a new Geometry::Primitive::Rectangle

=head2 area

Returns the area of this rectangle.

=head2 get_points

Get the points that make up this Rectangle.

=head2 point_end

Get the end point.  Returns the origin. Provided for Shape role.

=head2 point_start

Get the start point.  Returns the origin.  Provided for Shape role.

=head2 scale ($amount)

Scales the hieght and width of this rectangle by the amount specified.

=head1 AUTHOR

Cory Watson <gphat@cpan.org>

=head1 COPYRIGHT & LICENSE

You can redistribute and/or modify this code under the same terms as Perl
itself.