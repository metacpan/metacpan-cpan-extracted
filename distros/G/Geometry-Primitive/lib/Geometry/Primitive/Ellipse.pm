package Geometry::Primitive::Ellipse;
use Moose;
use MooseX::Storage;
use Moose::Util::TypeConstraints;

use Geometry::Primitive::Point;
use Math::Trig ':pi';

with qw(Geometry::Primitive::Shape MooseX::Clone MooseX::Storage::Deferred);

subtype 'My::Geometry::Primitive::Point' => as class_type('Geometry::Primitive::Point');

coerce 'My::Geometry::Primitive::Point'
  => from 'ArrayRef'
    => via { Geometry::Primitive::Point->new(x => $_->[0], y => $_->[1]) };


has 'height' => (
    is => 'rw',
    isa => 'Num',
    default => 0
);
has 'origin' => (
    is => 'rw',
    isa => 'My::Geometry::Primitive::Point',
    coerce => 1
);
has 'width' => (
    is => 'rw',
    isa => 'Num',
    default => 0
);

sub area {
    my ($self) = @_;
    return (pi * $self->width * $self->height) / 4;
};

sub point_end {
    my ($self) = @_;

    return $self->point_start;
}

sub point_start {
    my ($self) = @_;

    return Geometry::Primitive::Point->new(
        x => $self->origin->x,
        y => $self->origin->y - ($self->height / 2)
    );
}

sub scale {
    my ($self, $amount) = @_;

    return Geometry::Primitive::Ellipse->new(
        height => $self->height * $amount,
        width => $self->width * $amount
    );
}

__PACKAGE__->meta->make_immutable;

no Moose;
1;

__END__

=head1 NAME

Geometry::Primitive::Ellipse - An Ellipse

=head1 DESCRIPTION

Geometry::Primitive::Ellipse represents an elliptical conic section.

=head1 SYNOPSIS

  use Geometry::Primitive::Ellipse;

  my $ellipse = Geometry::Primitive::Ellipse->new(
      width => 15,
      height => 10
  );
  print $ellipse->area;

=head1 ATTRIBUTES

=head2 height

Set/Get the height of this ellipse.

=head2 origin

Set/Get the origin of this ellipse.

=head2 width

Set/Get the width of this ellipse.

=head1 METHODS

=head2 new

Creates a new Geometry::Primitive::Ellipse

=head2 area

Returns the area of this ellipse.

=head2 point_end

Gets the "end" point for this Ellipse.  Same as C<point_start>.

=head2 point_start

Get the point that "starts" this Ellipse.  Returns the a point where the X
coordinate is the Ellipse origin X and the origin Y + height / 2.

=head2 scale ($amount)

Returns a new ellipse whose radius is $amount times bigger than this one.

=head1 AUTHOR

Cory Watson <gphat@cpan.org>

=head1 COPYRIGHT & LICENSE

You can redistribute and/or modify this code under the same terms as Perl
itself.