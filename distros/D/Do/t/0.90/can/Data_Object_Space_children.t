use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

children

=usage

  # given $space (Foo::Bar)

  $space->children();

  # ['Foo::Bar::Baz', ...]

=description

The children method searches C<%INC> and C<@INC> and retuns a list of
L<Data::Object::Space> objects for each child namespace found (one level deep).

=signature

children() : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'children';

ok 1 and done_testing;
