use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Delete

=abstract

Data-Object Array Function (Delete) Class

=synopsis

  use Data::Object::Func::Array::Delete;

  my $func = Data::Object::Func::Array::Delete->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Delete is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Delete';

ok 1 and done_testing;
