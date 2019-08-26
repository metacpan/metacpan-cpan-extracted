use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Scalar::Gt

=abstract

Data-Object Scalar Function (Gt) Class

=synopsis

  use Data::Object::Func::Scalar::Gt;

  my $func = Data::Object::Func::Scalar::Gt->new(@args);

  $func->execute;

=description

Data::Object::Func::Scalar::Gt is a function object for Data::Object::Scalar.

=cut

# TESTING

use_ok 'Data::Object::Func::Scalar::Gt';

ok 1 and done_testing;
