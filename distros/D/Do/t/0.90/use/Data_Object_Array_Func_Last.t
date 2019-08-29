use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Last

=abstract

Data-Object Array Function (Last) Class

=synopsis

  use Data::Object::Array::Func::Last;

  my $func = Data::Object::Array::Func::Last->new(@args);

  $func->execute;

=description

Data::Object::Array::Func::Last is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Last';

ok 1 and done_testing;
