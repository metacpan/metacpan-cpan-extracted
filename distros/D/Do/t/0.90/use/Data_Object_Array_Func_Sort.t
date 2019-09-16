use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Sort

=abstract

Data-Object Array Function (Sort) Class

=synopsis

  use Data::Object::Array::Func::Sort;

  my $func = Data::Object::Array::Func::Sort->new(@args);

  $func->execute;

=inherits

Data::Object::Array::Func

=attributes

arg1(ArrayLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Array::Func::Sort is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Sort';

ok 1 and done_testing;
