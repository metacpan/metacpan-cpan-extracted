use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Join

=abstract

Data-Object Array Function (Join) Class

=synopsis

  use Data::Object::Array::Func::Join;

  my $func = Data::Object::Array::Func::Join->new(@args);

  $func->execute;

=description

Data::Object::Array::Func::Join is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Join';

ok 1 and done_testing;
