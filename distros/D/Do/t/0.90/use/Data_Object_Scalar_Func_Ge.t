use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Scalar::Func::Ge

=abstract

Data-Object Scalar Function (Ge) Class

=synopsis

  use Data::Object::Scalar::Func::Ge;

  my $func = Data::Object::Scalar::Func::Ge->new(@args);

  $func->execute;

=description

Data::Object::Scalar::Func::Ge is a function object for Data::Object::Scalar.
This package inherits all behavior from L<Data::Object::Scalar::Func>.

=cut

# TESTING

use_ok 'Data::Object::Scalar::Func::Ge';

ok 1 and done_testing;
