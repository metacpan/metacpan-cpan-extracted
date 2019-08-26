use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Scalar::Le

=abstract

Data-Object Scalar Function (Le) Class

=synopsis

  use Data::Object::Func::Scalar::Le;

  my $func = Data::Object::Func::Scalar::Le->new(@args);

  $func->execute;

=description

Data::Object::Func::Scalar::Le is a function object for Data::Object::Scalar.

=cut

# TESTING

use_ok 'Data::Object::Func::Scalar::Le';

ok 1 and done_testing;
