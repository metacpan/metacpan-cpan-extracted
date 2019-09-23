use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Kvslice

=abstract

Data-Object Array Function (Kvslice) Class

=synopsis

  use Data::Object::Array::Func::Kvslice;

  my $func = Data::Object::Array::Func::Kvslice->new(@args);

  $func->execute;

=inherits

Data::Object::Array::Func

=attributes

arg1(ArrayLike, req, ro)
args(ArrayRef[StringLike], req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Array::Func::Kvslice is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Kvslice';

ok 1 and done_testing;
