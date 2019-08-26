use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Set

=abstract

Data-Object Array Function (Set) Class

=synopsis

  use Data::Object::Func::Array::Set;

  my $func = Data::Object::Func::Array::Set->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Set is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Set';

ok 1 and done_testing;
