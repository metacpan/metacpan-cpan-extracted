use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Set

=abstract

Data-Object Array Function (Set) Class

=synopsis

  use Data::Object::Array::Func::Set;

  my $func = Data::Object::Array::Func::Set->new(@args);

  $func->execute;

=inherits

Data::Object::Array::Func

=description

Data::Object::Array::Func::Set is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Set';

ok 1 and done_testing;
