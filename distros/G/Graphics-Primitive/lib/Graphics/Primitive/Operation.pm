package Graphics::Primitive::Operation;
use Moose;

has 'preserve' => (
    isa => 'Bool',
    is  => 'rw',
    default =>  sub { 0 },
);

__PACKAGE__->meta->make_immutable;

no Moose;
1;
=head1 NAME

Graphics::Primitive::Operation - A drawing instruction

=head1 DESCRIPTION

Graphics::Primitive::Operation is the base class for operations.  An operation
is an action that is performed on a path such as a
L<Fill|Graphics::Primitive::Operation::Fill> or
L<Fill|Graphics::Primitive::Operation::Stroke>.

=head1 METHODS

=over 4

=item I<preserve>

Informs the canvas to not clear the current path when performing this
operation.  Also provides a hint to the driver.

=back

=head1 AUTHOR

Cory Watson <gphat@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 by Cory G Watson.

You can redistribute and/or modify this code under the same terms as Perl
itself.
