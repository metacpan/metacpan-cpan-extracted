use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Get

=abstract

Data-Object Array Function (Get) Class

=synopsis

  use Data::Object::Array::Func::Get;

  my $func = Data::Object::Array::Func::Get->new(@args);

  $func->execute;

=inherits

Data::Object::Array::Func

=attributes

arg1(ArrayLike, req, ro)
arg2(NumberLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Array::Func::Get is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Get';

ok 1 and done_testing;
