package JavaScript::PerlArray;

use strict;
use warnings;

# This is just a documentation module
# implementation is in JavaScript.xs

1;
__END__

=head1 NAME

JavaScript::PerlArray - Encapsulate a Perl array in JavaScript space

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new ()

Creates a new instance with an empty array.

=back

=head2 INSTANCE METHODS

=over 4

=item get_ref ( )

Returns a reference to the underlying array.

=back

=head2 JAVASCRIPT INTERFACE

This class is exposed in JavaScript space as B<PerlArray> and can be instanciated using C<new PerlArray();>.

=head3 Methods

=over 4

=item push (arg, ...)

Pushes the arguments onto the array

=item unshift (arg, ...)

Unshifts (ie inserts in the beginning) the arguments into the array.

=item pop ( )

Returns the top element.

=item shift ( )

Returns the bottom element.

=back

=head3 Properties

Instances of this class can be accessed as a normal array using integer indicies like C<arr[2]> both for 
reading and setting. If a negative index is used it is relative to the tail.

=over 4

=item length

The number of items in the array.

=back

=cut
