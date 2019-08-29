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

=description

Data::Object::Scalar::Func::Lt is a function object for Data::Object::Scalar.

=cut

# TESTING

use_ok 'Data::Object::Scalar::Func::Lt';

ok 1 and done_testing;
