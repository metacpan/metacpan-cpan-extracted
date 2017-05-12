package Geometry::Primitive::Circle;
use Moose;
use MooseX::Storage;

with qw(Geometry::Primitive::Shape MooseX::Clone MooseX::Storage::Deferred);

use Geometry::Primitive::Point;
use Math::Trig ':pi';

has 'origin' => (
    is => 'rw',
    isa => 'Geometry::Primitive::Point',
    coerce => 1
);
has 'radius' => (
    is => 'rw',
    isa => 'Num',
    default => 0
);

sub area {
    my ($self) = @_;
    return $self->radius**2 * pi;
};

sub circumference {
    my ($self) = @_;

    return $self->diameter * pi;
}

sub diameter {
    my ($self) = @_;

    return $self->radius * 2;
}

sub point_end {
    my ($self) = @_;

    return $self->point_start;
}

sub point_start {
    my ($self) = @_;

    return Geometry::Primitive::Point->new(
        x => $self->origin->x,
        y => $self->origin->y - ($self->radius / 2)
    );
}

sub scale {
    my ($self, $amount) = @_;

    return Geometry::Primitive::Circle->new(
        radius => $self->radius * $amount
    );
}

__PACKAGE__->meta->make_immutable;

no Moose;
1;

__END__

=head1 NAME

Geometry::Primitive::Circle - A Circle

=head1 DESCRIPTION

Geometry::Primitive::Circle represents an ellipse with equal width and height.

=head1 SYNOPSIS

  use Geometry::Primitive::Circle;

  my $circle = Geometry::Primitive::Circle->new(
      radius => 15
  );
  print $circle->diameter;

=head1 ATTRIBUTES

=head2 origin

Set/Get the origin of this circle.

=head2 radius

Set/Get the radius of this circle.

=head1 METHODS

=head2 new

Creates a new Geometry::Primitive::Circle

=head2 area

Returns the area of this circle.

=head2 circumference

Returns the circumference of this circle.

=head2 diameter

Returns the diameter of this circle

=head2 scale ($amount)

Returns a new circle whose radius is $amount times bigger than this one.

=head2 point_end

Set/Get the "end" point of this cicle.  Calls C<point_start>.

=head2 point_start

Set/Get the "start" point of this cicle.  Returns the point at the circle's
origin X coordinate and the origin Y coordinate + radius / 2.

=head1 AUTHOR

Cory Watson <gphat@cpan.org>

=head1 COPYRIGHT & LICENSE

You can redistribute and/or modify this code under the same terms as Perl
itself.