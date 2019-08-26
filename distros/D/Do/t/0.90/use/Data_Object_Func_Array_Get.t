use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Get

=abstract

Data-Object Array Function (Get) Class

=synopsis

  use Data::Object::Func::Array::Get;

  my $func = Data::Object::Func::Array::Get->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Get is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Get';

ok 1 and done_testing;
