use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Slice

=abstract

Data-Object Array Function (Slice) Class

=synopsis

  use Data::Object::Array::Func::Slice;

  my $func = Data::Object::Array::Func::Slice->new(@args);

  $func->execute;

=description

Data::Object::Array::Func::Slice is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Slice';

ok 1 and done_testing;
