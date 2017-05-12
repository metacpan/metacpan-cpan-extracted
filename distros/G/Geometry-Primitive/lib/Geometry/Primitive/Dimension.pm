package Geometry::Primitive::Dimension;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Storage;

with qw(Geometry::Primitive::Equal MooseX::Clone MooseX::Storage::Deferred);

use overload ('""' => 'to_string');

has 'height' => (
    is => 'rw',
    isa => 'Num',
    default => 0,
);
has 'width' => (
    is => 'rw',
    isa => 'Num',
    default => 0
);

coerce 'Geometry::Primitive::Dimension'
    => from 'ArrayRef'
        => via { Geometry::Primitive::Dimension->new(width => $_->[0], height => $_->[1]) };

sub equal_to {
    my ($self, $other) = @_;

    return (($self->width == $other->width) && $self->height == $other->height);
}

sub to_string {
    my ($self) = @_;

    return $self->width.'x'.$self->height;
}

__PACKAGE__->meta->make_immutable;

no Moose;
1;

=head1 NAME

Geometry::Primitive::Dimension - A width and height

=head1 DESCRIPTION

Geometry::Primitive::Dimension encapsulates a height and width.

=head1 SYNOPSIS

  use Geometry::Primitive::Dimension;

  my $point = Geometry::Primitive::Dimeions->new(width => 100, height => 100);

=head1 ATTRIBUTES

=head2 height

Set/Get the height value.

=head2 width

Set/Get the width value.

=head1 METHODS

=head2 new

Creates a new Geometry::Primitive::Point.

=head2 equal_to

Compares this dimesion to another.

=head2 to_string

Return this dimesion as a string $widthx$height

=head1 AUTHOR

Cory Watson <gphat@cpan.org>

=head1 COPYRIGHT & LICENSE

You can redistribute and/or modify this code under the same terms as Perl
itself.
