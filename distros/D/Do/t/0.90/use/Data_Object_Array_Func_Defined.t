use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Defined

=abstract

Data-Object Array Function (Defined) Class

=synopsis

  use Data::Object::Array::Func::Defined;

  my $func = Data::Object::Array::Func::Defined->new(@args);

  $func->execute;

=inherits

Data::Object::Array::Func

=attributes

arg1(ArrayLike, req, ro)
arg2(NumberLike, opt, ro)

=libraries

Data::Object::Library

=description

Data::Object::Array::Func::Defined is a function object for
Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Defined';

ok 1 and done_testing;
