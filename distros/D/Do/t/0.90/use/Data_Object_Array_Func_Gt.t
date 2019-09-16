use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Gt

=abstract

Data-Object Array Function (Gt) Class

=synopsis

  use Data::Object::Array::Func::Gt;

  my $func = Data::Object::Array::Func::Gt->new(@args);

  $func->execute;

=inherits

Data::Object::Array::Func

=attributes

arg1(ArrayLike, req, ro)
arg2(ArrayLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Array::Func::Gt is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Gt';

ok 1 and done_testing;
