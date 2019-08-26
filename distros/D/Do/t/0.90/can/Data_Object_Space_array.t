use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

array

=usage

  # given Foo/Bar

  $space->array('EXPORT');

  # (,...)

=description

The array method returns the value for the given package array variable name.

=signature

array(Str $arg1) : Any

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'array';

ok 1 and done_testing;
