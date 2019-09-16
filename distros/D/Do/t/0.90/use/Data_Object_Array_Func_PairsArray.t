use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::PairsArray

=abstract

Data-Object Array Function (PairsArray) Class

=synopsis

  use Data::Object::Array::Func::PairsArray;

  my $func = Data::Object::Array::Func::PairsArray->new(@args);

  $func->execute;

=inherits

Data::Object::Array::Func

=attributes

arg1(ArrayLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Array::Func::PairsArray is a function object for
Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::PairsArray';

ok 1 and done_testing;
