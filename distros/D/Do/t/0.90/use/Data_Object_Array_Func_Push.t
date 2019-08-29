use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Push

=abstract

Data-Object Array Function (Push) Class

=synopsis

  use Data::Object::Array::Func::Push;

  my $func = Data::Object::Array::Func::Push->new(@args);

  $func->execute;

=description

Data::Object::Array::Func::Push is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Push';

ok 1 and done_testing;
