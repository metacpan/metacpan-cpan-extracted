use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

pluck

=usage

  =pod help

  Example content

  =cut

  # given $data

  $data->pluck('item', 'help');

  # {,...}

=description

The pluck method splices and returns metadata for the pod-like section that
matches the given list or item by name.

=signature

pluck(Str $arg1, Str $arg2) : HashRef

=type

method

=cut

# TESTING

use Data::Object::Data;

can_ok 'Data::Object::Data', 'pluck';

ok 1 and done_testing;

