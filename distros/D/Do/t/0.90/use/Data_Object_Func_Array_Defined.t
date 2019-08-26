use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Defined

=abstract

Data-Object Array Function (Defined) Class

=synopsis

  use Data::Object::Func::Array::Defined;

  my $func = Data::Object::Func::Array::Defined->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Defined is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Defined';

ok 1 and done_testing;
