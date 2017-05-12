package List::Objects::WithUtils::Role::Hash::TiedRO;
$List::Objects::WithUtils::Role::Hash::TiedRO::VERSION = '2.028003';
=for Pod::Coverage *EVERYTHING*

=cut

use strictures 2;
use Carp ();

use Role::Tiny;

around $_ => sub {
  Carp::croak "Attempted to modify a read-only value"
} for qw/
  STORE
  DELETE
  CLEAR
/;

1;
