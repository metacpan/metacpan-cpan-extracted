use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Pop

=abstract

Data-Object Array Function (Pop) Class

=synopsis

  use Data::Object::Array::Func::Pop;

  my $func = Data::Object::Array::Func::Pop->new(@args);

  $func->execute;

=description

Data::Object::Array::Func::Pop is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Pop';

ok 1 and done_testing;
