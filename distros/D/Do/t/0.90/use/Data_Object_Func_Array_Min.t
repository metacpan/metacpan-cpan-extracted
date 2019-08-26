use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Min

=abstract

Data-Object Array Function (Min) Class

=synopsis

  use Data::Object::Func::Array::Min;

  my $func = Data::Object::Func::Array::Min->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Min is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Min';

ok 1 and done_testing;
