use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Unique

=abstract

Data-Object Array Function (Unique) Class

=synopsis

  use Data::Object::Array::Func::Unique;

  my $func = Data::Object::Array::Func::Unique->new(@args);

  $func->execute;

=inherits

Data::Object::Array::Func

=attributes

arg1(ArrayLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Array::Func::Unique is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Unique';

ok 1 and done_testing;
