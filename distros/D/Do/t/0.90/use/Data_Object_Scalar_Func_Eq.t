use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Scalar::Func::Eq

=abstract

Data-Object Scalar Function (Eq) Class

=synopsis

  use Data::Object::Scalar::Func::Eq;

  my $func = Data::Object::Scalar::Func::Eq->new(@args);

  $func->execute;

=inherits

Data::Object::Scalar::Func

=attributes

arg1(Object, req, ro)
arg2(Any, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Scalar::Func::Eq is a function object for Data::Object::Scalar.

=cut

# TESTING

use_ok 'Data::Object::Scalar::Func::Eq';

ok 1 and done_testing;
