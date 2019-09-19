use 5.014;

use strict;
use warnings;

use Test::More;

plan skip_all => 'Refactoring';

# POD

=name

raise

=usage

  # given $message;

  raise $message; # Exception! thrown in -e at line 1

=description

The raise function will dynamically load and raise an exception object. This
function takes all arguments accepted by the L<Data::Object::Exception> class.

=signature

raise(Any @args) : Object

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'raise';

ok 1 and done_testing;
