use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Scalar::Func::Lt

=abstract

Data-Object Scalar Function (Lt) Class

=synopsis

  use Data::Object::Scalar::Func::Lt;

  my $func = Data::Object::Scalar::Func::Lt->new(@args);

  $func->execute;

=inherits

Data::Object::Scalar::Func

=attributes

arg1(Any, req, ro)
arg2(Any, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Scalar::Func::Lt is a function object for Data::Object::Scalar.

=cut

# TESTING

use_ok 'Data::Object::Scalar::Func::Lt';

ok 1 and done_testing;
