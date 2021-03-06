use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Size

=abstract

Data-Object Array Function (Size) Class

=synopsis

  use Data::Object::Array::Func::Size;

  my $func = Data::Object::Array::Func::Size->new(@args);

  $func->execute;

=inherits

Data::Object::Array::Func

=attributes

arg1(ArrayLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Array::Func::Size is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Size';

ok 1 and done_testing;
