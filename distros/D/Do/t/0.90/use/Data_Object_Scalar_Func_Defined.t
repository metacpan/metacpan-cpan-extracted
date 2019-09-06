use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Scalar::Func::Defined

=abstract

Data-Object Scalar Function (Defined) Class

=synopsis

  use Data::Object::Scalar::Func::Defined;

  my $func = Data::Object::Scalar::Func::Defined->new(@args);

  $func->execute;

=inherits

Data::Object::Scalar::Func

=attributes

arg1(Object, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Scalar::Func::Defined is a function object for
Data::Object::Scalar.

=cut

# TESTING

use_ok 'Data::Object::Scalar::Func::Defined';

ok 1 and done_testing;
