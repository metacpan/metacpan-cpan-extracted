use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Le

=abstract

Data-Object Array Function (Le) Class

=synopsis

  use Data::Object::Func::Array::Le;

  my $func = Data::Object::Func::Array::Le->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Le is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Le';

ok 1 and done_testing;
