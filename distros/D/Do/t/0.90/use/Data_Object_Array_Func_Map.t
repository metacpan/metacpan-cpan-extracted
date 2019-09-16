use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Map

=abstract

Data-Object Array Function (Map) Class

=synopsis

  use Data::Object::Array::Func::Map;

  my $func = Data::Object::Array::Func::Map->new(@args);

  $func->execute;

=inherits

Data::Object::Array::Func

=attributes

arg1(ArrayLike, req, ro)
arg2(CodeLike, req, ro)
args(ArrayRef[Any], opt, ro)

=libraries

Data::Object::Library

=description

Data::Object::Array::Func::Map is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Map';

ok 1 and done_testing;
