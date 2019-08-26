use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

throw

=usage

  # given $message;

  throw $message; # An exception (...) was thrown in -e at line 1

=description

The throw function will dynamically load and throw an exception object. This
function takes all arguments accepted by the L<Data::Object::Exception> class.

=signature

throw(Any @args) : Object

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'throw';

ok 1 and done_testing;
