use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Unshift

=abstract

Data-Object Array Function (Unshift) Class

=synopsis

  use Data::Object::Array::Func::Unshift;

  my $func = Data::Object::Array::Func::Unshift->new(@args);

  $func->execute;

=description

Data::Object::Array::Func::Unshift is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Unshift';

ok 1 and done_testing;
