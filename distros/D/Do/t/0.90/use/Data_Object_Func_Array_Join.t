use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Join

=abstract

Data-Object Array Function (Join) Class

=synopsis

  use Data::Object::Func::Array::Join;

  my $func = Data::Object::Func::Array::Join->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Join is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Join';

ok 1 and done_testing;
