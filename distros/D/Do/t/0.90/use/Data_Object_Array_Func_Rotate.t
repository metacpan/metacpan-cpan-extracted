use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Rotate

=abstract

Data-Object Array Function (Rotate) Class

=synopsis

  use Data::Object::Array::Func::Rotate;

  my $func = Data::Object::Array::Func::Rotate->new(@args);

  $func->execute;

=description

Data::Object::Array::Func::Rotate is a function object for Data::Object::Array.
This package inherits all behavior from L<Data::Object::Array::Func>.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Rotate';

ok 1 and done_testing;
