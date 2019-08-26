use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Length

=abstract

Data-Object Array Function (Length) Class

=synopsis

  use Data::Object::Func::Array::Length;

  my $func = Data::Object::Func::Array::Length->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Length is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Length';

ok 1 and done_testing;
