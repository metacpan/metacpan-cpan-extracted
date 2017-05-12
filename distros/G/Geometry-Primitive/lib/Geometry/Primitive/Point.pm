package Geometry::Primitive::Point;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Storage;

with qw(Geometry::Primitive::Equal MooseX::Clone MooseX::Storage::Deferred);

use overload ('""' => 'to_string');

has 'x' => (
    is => 'rw',
    isa => 'Num'
);
has 'y' => (
    is => 'rw',
    isa => 'Num'
);

coerce 'Geometry::Primitive::Point'
    => from 'ArrayRef'
        => via { Geometry::Primitive::Point->new(x => $_->[0], y => $_->[1]) };

sub equal_to {
    my ($self, $other) = @_;

    return (($self->x == $other->x) && $self->y == $other->y);
}

sub to_string {
    my ($self) = @_;

    return $self->x.','.$self->y;
}

__PACKAGE__->meta->make_immutable;

no Moose;
1;

=head1 NAME

Geometry::Primitive::Point - An XY coordinate

=head1 DESCRIPTION

Geometry::Primitive::Point represents a location in two dimensional space.

=head1 SYNOPSIS

  use Geometry::Primitive::Point;

  my $point = Geometry::Primitive::Point->new({ x => 2, y => 0 });

=head1 ATTRIBUTES

=head2 x

Set/Get the X value.

=head2 y

Set/Get the Y value.

=head1 METHODS

=head2 new

Creates a new Geometry::Primitive::Point.

=head2 equal_to

Compares this point to another.

=head2 to_string

Return this point as a string $x,$y

=head1 AUTHOR

Cory Watson <gphat@cpan.org>

=head1 COPYRIGHT & LICENSE

You can redistribute and/or modify this code under the same terms as Perl
itself.
