package Geometry::Primitive::Bezier;
use Moose;
use MooseX::Storage;

with qw(Geometry::Primitive::Shape MooseX::Clone MooseX::Storage::Deferred);

use overload ('""' => 'to_string');

use Geometry::Primitive::Point;

has 'control1' => (
    is => 'rw',
    isa => 'Geometry::Primitive::Point',
    required => 1,
    coerce => 1
);
has 'control2' => (
    is => 'rw',
    isa => 'Geometry::Primitive::Point',
    required => 1,
    coerce => 1
);
has 'end' => (
    is => 'rw',
    isa => 'Geometry::Primitive::Point',
    required => 1,
    coerce => 1
);
has 'start' => (
    is => 'rw',
    isa => 'Geometry::Primitive::Point',
    required => 1,
    coerce => 1
);

sub scale {
    my ($self, $amount) = @_;

    $self->start->x($self->start->x * $amount);
    $self->start->y($self->start->y * $amount);

    $self->end->x($self->end->x * $amount);
    $self->end->y($self->end->y * $amount);

    $self->control1->x($self->control1->x * $amount);
    $self->control1->y($self->control1->y * $amount);

    $self->control2->x($self->control2->x * $amount);
    $self->control2->y($self->control2->y * $amount);
}

sub point_end {
    my ($self) = @_; return $self->end;
}

sub point_start {
    my ($self) = @_; return $self->start;
}


sub to_string {
    my ($self) = @_;

    return $self->start->to_string.' - '.$self->control1->to_string
        .' = '.$self->control2->to_string.' = '.$self->end->to_string;
}

__PACKAGE__->meta->make_immutable;

no Moose;
1;

__END__

=encoding UTF-8

=head1 NAME

Geometry::Primitive::Bezier - Cubic Bézier Curve

=head1 DESCRIPTION

Geometry::Primitive::Bezier represents a cubic Bézier curve.

=head1 SYNOPSIS

  use Geometry::Primitive::Bezier;

  my $line = Geometry::Primitive::Bezier->new(
      start => $point1,
      control1 => $point2,
      control2 => $point3,
      end => $point4
  );

=head1 ATTRIBUTES

=head2 control1

Set/Get the first control point of the curve.

=head2 control2

Set/Get the second control point of the curve.

=head2 end

Set/Get the end point of the curve.

=head2 start

Set/Get the start point of the line.

=head1 METHODS

=head2 new

Creates a new Geometry::Primitive::Bezier

=head2 grow

Does nothing, as I'm not sure how.  Patches or hints welcome.

=head2 point_end

Get the end point.  Provided for Shape role.

=head2 point_start

Get the start point.  Provided for Shape role.

=head2 scale

Scales this curve by the amount provided.  Multiplies each coordinate by the
amount.

=head2 to_string

Guess!

=head1 AUTHOR

Cory Watson <gphat@cpan.org>

=head1 COPYRIGHT & LICENSE

You can redistribute and/or modify this code under the same terms as Perl
itself.
