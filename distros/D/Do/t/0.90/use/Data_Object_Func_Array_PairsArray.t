use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::PairsArray

=abstract

Data-Object Array Function (PairsArray) Class

=synopsis

  use Data::Object::Func::Array::PairsArray;

  my $func = Data::Object::Func::Array::PairsArray->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::PairsArray is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::PairsArray';

ok 1 and done_testing;
