use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Keyed

=abstract

Data-Object Array Function (Keyed) Class

=synopsis

  use Data::Object::Array::Func::Keyed;

  my $func = Data::Object::Array::Func::Keyed->new(@args);

  $func->execute;

=inherits

Data::Object::Array::Func

=attributes

arg1(Object, req, ro)
args(ArrayRef[Str], req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Array::Func::Keyed is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Keyed';

ok 1 and done_testing;
