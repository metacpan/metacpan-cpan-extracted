use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Tail

=abstract

Data-Object Array Function (Tail) Class

=synopsis

  use Data::Object::Array::Func::Tail;

  my $func = Data::Object::Array::Func::Tail->new(@args);

  $func->execute;

=inherits

Data::Object::Array::Func

=description

Data::Object::Array::Func::Tail is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Tail';

ok 1 and done_testing;
