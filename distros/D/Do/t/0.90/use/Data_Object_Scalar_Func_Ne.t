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

=description

Data::Object::Scalar::Func::Ne is a function object for Data::Object::Scalar.
This package inherits all behavior from L<Data::Object::Scalar::Func>.

=cut

# TESTING

use_ok 'Data::Object::Scalar::Func::Ne';

ok 1 and done_testing;
