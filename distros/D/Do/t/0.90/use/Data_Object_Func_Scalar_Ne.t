use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Scalar::Ne

=abstract

Data-Object Scalar Function (Ne) Class

=synopsis

  use Data::Object::Func::Scalar::Ne;

  my $func = Data::Object::Func::Scalar::Ne->new(@args);

  $func->execute;

=description

Data::Object::Func::Scalar::Ne is a function object for Data::Object::Scalar.

=cut

# TESTING

use_ok 'Data::Object::Func::Scalar::Ne';

ok 1 and done_testing;
