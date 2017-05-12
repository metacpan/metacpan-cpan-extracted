package Graphics::Primitive::Insets;
use Moose;
use MooseX::Storage;

with 'Geometry::Primitive::Equal';

with 'MooseX::Clone';
with Storage (format => 'JSON', io => 'File');

use Moose::Util::TypeConstraints;

coerce 'Graphics::Primitive::Insets'
    => from 'ArrayRef'
        => via {
            Graphics::Primitive::Insets->new(
                top => $_->[0], right => $_->[1],
                bottom => $_->[2], left => $_->[3]
            )
        };

coerce 'Graphics::Primitive::Insets'
    => from 'Num'
        => via {
            Graphics::Primitive::Insets->new(
                top => $_, right => $_,
                bottom => $_, left => $_
            )
        };

has 'top' => ( is => 'rw', isa => 'Num', default => 0 );
has 'bottom' => ( is => 'rw', isa => 'Num', default => 0 );
has 'left' => ( is => 'rw', isa => 'Num', default => 0 );
has 'right' => ( is => 'rw', isa => 'Num', default => 0 );

sub as_array {
    my ($self) = @_;

    return ($self->top, $self->right, $self->bottom, $self->left);
}

sub equal_to {
    my ($self, $other) = @_;

    return ($self->top == $other->top) && ($self->bottom == $other->bottom)
        && ($self->left == $other->left) && ($self->right == $other->right);
}

sub width {
    my ($self, $width) = @_;

    $self->top($width); $self->bottom($width);
    $self->left($width); $self->right($width);
}

sub zero {
    my ($self) = @_;

    $self->width(0);
}

__PACKAGE__->meta->make_immutable;

no Moose;
1;
__END__
=head1 NAME

Graphics::Primitive::Insets - Space between things

=head1 DESCRIPTION

Graphics::Primitive::Insets represents the amount of space that surrounds
something.  This object can be used to represent either padding or margins
(in the CSS sense, one being inside the bounding box, the other being outside)

=head1 SYNOPSIS

  use Graphics::Primitive::Insets;

  my $insets = Graphics::Primitive::Insets->new({
    top     => 5,
    bottom  => 5,
    left    => 5,
    right   => 5
  });

=head1 METHODS

=head2 Constructor

=over 4

=item I<new>

Creates a new Graphics::Primitive::Insets.

=back

=head2 Instance Methods

=over 4

=item I<as_array>

Return these insets as an array in the form of top, right, bottom and left.

=item I<bottom>

Set/Get the inset from the bottom.

=item I<equal_to>

Determine if these Insets are equal to another.

=item I<left>

Set/Get the inset from the left.

=item I<right>

Set/Get the inset from the right.

=item I<top>

Set/Get the inset from the top.

=item I<zero>

Sets all the insets (top, left, bottom, right) to 0.

=back

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

=head1 SEE ALSO

perl(1)

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 by Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.