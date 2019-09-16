use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Hash

=abstract

Data-Object Array Function (Hash) Class

=synopsis

  use Data::Object::Array::Func::Hash;

  my $func = Data::Object::Array::Func::Hash->new(@args);

  $func->execute;

=inherits

Data::Object::Array::Func

=attributes

arg1(ArrayLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Array::Func::Hash is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Hash';

ok 1 and done_testing;
