package List::Objects::WithUtils::Role::Array::TiedRO;
$List::Objects::WithUtils::Role::Array::TiedRO::VERSION = '2.028003';
=for Pod::Coverage *EVERYTHING*

=cut

use strictures 2;
use Carp ();

# This role can be applied to the objects backing tied arrays
# after construction time in order to swap a mutable tied array
# for an immutable implementation;
# Array::Immutable::Typed::immarray_of does this in order to retain
# normal tied type array behavior until construction is complete.

use Role::Tiny;

around $_ => sub {
  Carp::croak "Attempted to modify a read-only value"
} for qw/
  STORE
  STORESIZE
  CLEAR
  PUSH
  POP
  SHIFT
  SPLICE
  UNSHIFT
  EXTEND
/;

1;
