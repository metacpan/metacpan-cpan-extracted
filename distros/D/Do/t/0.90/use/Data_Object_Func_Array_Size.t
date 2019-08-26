use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Size

=abstract

Data-Object Array Function (Size) Class

=synopsis

  use Data::Object::Func::Array::Size;

  my $func = Data::Object::Func::Array::Size->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Size is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Size';

ok 1 and done_testing;
