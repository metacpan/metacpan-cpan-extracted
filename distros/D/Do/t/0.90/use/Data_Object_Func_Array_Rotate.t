use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Rotate

=abstract

Data-Object Array Function (Rotate) Class

=synopsis

  use Data::Object::Func::Array::Rotate;

  my $func = Data::Object::Func::Array::Rotate->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Rotate is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Rotate';

ok 1 and done_testing;
