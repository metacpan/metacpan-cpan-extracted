use strict;
use warnings;

package Medical::OPCS4::Term;
# ABSTRACT: An OPCS4 term object.

use base 'Class::Accessor';

Medical::OPCS4::Term->mk_accessors( qw( term description) );

=head1 METHODS

=head2 description

Returns a scalar containing the term's description.

   my $desc = $O->description;

=cut

=head2 term

Returns a scalar containing the term's name.

   my $term = $O->term;

=cut

1;