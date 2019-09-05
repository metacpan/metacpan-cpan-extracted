use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Values

=abstract

Data-Object Array Function (Values) Class

=synopsis

  use Data::Object::Array::Func::Values;

  my $func = Data::Object::Array::Func::Values->new(@args);

  $func->execute;

=inherits

Data::Object::Array::Func

=description

Data::Object::Array::Func::Values is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Values';

ok 1 and done_testing;
