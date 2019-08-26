use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Push

=abstract

Data-Object Array Function (Push) Class

=synopsis

  use Data::Object::Func::Array::Push;

  my $func = Data::Object::Func::Array::Push->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Push is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Push';

ok 1 and done_testing;
