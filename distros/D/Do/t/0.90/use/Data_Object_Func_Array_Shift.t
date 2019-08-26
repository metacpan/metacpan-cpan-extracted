use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Shift

=abstract

Data-Object Array Function (Shift) Class

=synopsis

  use Data::Object::Func::Array::Shift;

  my $func = Data::Object::Func::Array::Shift->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Shift is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Shift';

ok 1 and done_testing;
