use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Scalar::Func::Ge

=abstract

Data-Object Scalar Function (Ge) Class

=synopsis

  use Data::Object::Scalar::Func::Ge;

  my $func = Data::Object::Scalar::Func::Ge->new(@args);

  $func->execute;

=inherits

Data::Object::Scalar::Func

=attributes

arg1(Any, req, ro)
arg2(Any, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Scalar::Func::Ge is a function object for Data::Object::Scalar.

=cut

# TESTING

use_ok 'Data::Object::Scalar::Func::Ge';

ok 1 and done_testing;
