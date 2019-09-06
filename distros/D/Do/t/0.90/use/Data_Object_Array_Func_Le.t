use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Le

=abstract

Data-Object Array Function (Le) Class

=synopsis

  use Data::Object::Array::Func::Le;

  my $func = Data::Object::Array::Func::Le->new(@args);

  $func->execute;

=inherits

Data::Object::Array::Func

=attributes

arg1(Object, req, ro)
arg2(ArrayLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Array::Func::Le is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Le';

ok 1 and done_testing;
