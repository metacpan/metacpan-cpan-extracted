package JavaScript::PerlHash;

use strict;
use warnings;

# This is just a documentation module
# implementation is in JavaScript.xs

1;
__END__

=head1 NAME

JavaScript::PerlHash - Encapsulate a Perl hash in JavaScript space

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new ()

Creates a new instance with an empty hash.

=back

=head2 INSTANCE METHODS

=over 4

=item get_ref ( )

Returns a reference to the underlying hash.

=back

=head2 JAVASCRIPT INTERFACE

This class is exposed in JavaScript space as B<PerlHash> and can be instanciated using C<new PerlHash();>. Set and get 
properties as a normal C<Object>. Currently enumerating of the keys of the hash is not supported.

=cut
