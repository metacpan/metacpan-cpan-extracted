use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

bless

=usage

  # given $space (Foo::Bar)

  $space->bless();

  # bless({}, 'Foo::Bar')

=description

The bless method blesses the given value into the package namespace and returns
an object. If no value is given, an empty hashref is used.

=signature

bless(Any $arg1 = {}) : Object

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'bless';

ok 1 and done_testing;
