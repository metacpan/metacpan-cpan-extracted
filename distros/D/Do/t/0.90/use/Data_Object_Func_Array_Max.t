use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Max

=abstract

Data-Object Array Function (Max) Class

=synopsis

  use Data::Object::Func::Array::Max;

  my $func = Data::Object::Func::Array::Max->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Max is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Max';

ok 1 and done_testing;
