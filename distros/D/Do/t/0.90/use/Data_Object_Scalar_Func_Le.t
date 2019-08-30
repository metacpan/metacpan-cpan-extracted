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

=description

Data::Object::Scalar::Func::Le is a function object for Data::Object::Scalar.
This package inherits all behavior from L<Data::Object::Scalar::Func>.

=cut

# TESTING

use_ok 'Data::Object::Scalar::Func::Le';

ok 1 and done_testing;
