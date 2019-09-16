use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Exists

=abstract

Data-Object Array Function (Exists) Class

=synopsis

  use Data::Object::Array::Func::Exists;

  my $func = Data::Object::Array::Func::Exists->new(@args);

  $func->execute;

=inherits

Data::Object::Array::Func

=attributes

arg1(ArrayLike, req, ro)
arg2(NumberLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Array::Func::Exists is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Exists';

ok 1 and done_testing;
