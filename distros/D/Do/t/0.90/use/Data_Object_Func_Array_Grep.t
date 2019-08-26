use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Grep

=abstract

Data-Object Array Function (Grep) Class

=synopsis

  use Data::Object::Func::Array::Grep;

  my $func = Data::Object::Func::Array::Grep->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Grep is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Grep';

ok 1 and done_testing;
