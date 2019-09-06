use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Shift

=abstract

Data-Object Array Function (Shift) Class

=synopsis

  use Data::Object::Array::Func::Shift;

  my $func = Data::Object::Array::Func::Shift->new(@args);

  $func->execute;

=inherits

Data::Object::Array::Func

=attributes

arg1(Object, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Array::Func::Shift is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Shift';

ok 1 and done_testing;
