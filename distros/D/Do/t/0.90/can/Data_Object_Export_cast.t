use 5.014;

use strict;
use warnings;

use Test::More;

plan skip_all => 'Refactoring';

# POD

=name

cast

=usage

  # given 123

  my $num = cast(123); # Data::Object::Number
  my $str = cast(123, 'string'); # Data::Object::String

=description

The cast function returns a data object for the argument provided. If the data
passed is blessed then that same object will be returned.

=signature

cast(Any $arg1, Str $type) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'cast';

ok 1 and done_testing;
