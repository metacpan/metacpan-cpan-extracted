use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

from_file

=usage

  # given $data

  $data->from_file($file);

  # ...

=description

The from_data method returns content for the given file to be passed to the
constructor. This method isn't meant to be called directly.

=signature

from_file(Str $arg1) : Str

=type

method

=cut

# TESTING

use Data::Object::Data;

can_ok 'Data::Object::Data', 'from_file';

ok 1 and done_testing;
