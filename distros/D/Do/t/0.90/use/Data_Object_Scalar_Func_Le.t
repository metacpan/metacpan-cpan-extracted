use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Scalar::Func::Le

=abstract

Data-Object Scalar Function (Le) Class

=synopsis

  use Data::Object::Scalar::Func::Le;

  my $func = Data::Object::Scalar::Func::Le->new(@args);

  $func->execute;

=inherits

Data::Object::Scalar::Func

=attributes

arg1(Any, req, ro)
arg2(Any, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Scalar::Func::Le is a function object for Data::Object::Scalar.

=cut

# TESTING

use_ok 'Data::Object::Scalar::Func::Le';

ok 1 and done_testing;
