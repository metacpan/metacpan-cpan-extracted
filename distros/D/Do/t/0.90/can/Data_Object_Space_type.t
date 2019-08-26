use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type

=usage

  # given $space (Foo/Bar.pod)

  $space->type();

  # pod

=description

The type method returns the parsed filetype and defaults to C<pm>. This value
is used when calling the C<file> method.

=signature

type() : Str

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'type';

ok 1 and done_testing;
