use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Sum

=abstract

Data-Object Array Function (Sum) Class

=synopsis

  use Data::Object::Func::Array::Sum;

  my $func = Data::Object::Func::Array::Sum->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Sum is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Sum';

ok 1 and done_testing;
