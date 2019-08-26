use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::One

=abstract

Data-Object Array Function (One) Class

=synopsis

  use Data::Object::Func::Array::One;

  my $func = Data::Object::Func::Array::One->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::One is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::One';

ok 1 and done_testing;
