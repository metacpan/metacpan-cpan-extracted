use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::One

=abstract

Data-Object Array Function (One) Class

=synopsis

  use Data::Object::Array::Func::One;

  my $func = Data::Object::Array::Func::One->new(@args);

  $func->execute;

=inherits

Data::Object::Array::Func

=description

Data::Object::Array::Func::One is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::One';

ok 1 and done_testing;
