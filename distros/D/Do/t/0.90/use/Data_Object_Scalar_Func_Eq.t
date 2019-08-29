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

=description

Data::Object::Scalar::Func::Eq is a function object for Data::Object::Scalar.

=cut

# TESTING

use_ok 'Data::Object::Scalar::Func::Eq';

ok 1 and done_testing;
