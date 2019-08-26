use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Pairs

=abstract

Data-Object Array Function (Pairs) Class

=synopsis

  use Data::Object::Func::Array::Pairs;

  my $func = Data::Object::Func::Array::Pairs->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Pairs is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Pairs';

ok 1 and done_testing;
