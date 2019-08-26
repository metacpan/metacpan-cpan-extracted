use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

throw

=usage

  $exception->throw();

=description

Throw error with message and context.

=signature

throw(Str $arg1) : Object

=type

method

=cut

# TESTING

use_ok 'Data::Object::Exception';

my $data = 'Data::Object::Exception';

can_ok $data, 'throw';

ok 1 and done_testing;
