use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Eq

=abstract

Data-Object Array Function (Eq) Class

=synopsis

  use Data::Object::Func::Array::Eq;

  my $func = Data::Object::Func::Array::Eq->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Eq is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Eq';

ok 1 and done_testing;
