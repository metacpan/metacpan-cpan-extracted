use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Scalar::Func::Ne

=abstract

Data-Object Scalar Function (Ne) Class

=synopsis

  use Data::Object::Scalar::Func::Ne;

  my $func = Data::Object::Scalar::Func::Ne->new(@args);

  $func->execute;

=inherits

Data::Object::Scalar::Func

=attributes

arg1(Any, req, ro)
arg2(Any, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Scalar::Func::Ne is a function object for Data::Object::Scalar.

=cut

# TESTING

use_ok 'Data::Object::Scalar::Func::Ne';

ok 1 and done_testing;
