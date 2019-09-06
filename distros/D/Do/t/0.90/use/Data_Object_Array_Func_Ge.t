use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Ge

=abstract

Data-Object Array Function (Ge) Class

=synopsis

  use Data::Object::Array::Func::Ge;

  my $func = Data::Object::Array::Func::Ge->new(@args);

  $func->execute;

=inherits

Data::Object::Array::Func

=attributes

arg1(Object, req, ro)
arg2(ArrayLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Array::Func::Ge is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Ge';

ok 1 and done_testing;
