use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Ne

=abstract

Data-Object Array Function (Ne) Class

=synopsis

  use Data::Object::Array::Func::Ne;

  my $func = Data::Object::Array::Func::Ne->new(@args);

  $func->execute;

=inherits

Data::Object::Array::Func

=attributes

arg1(ArrayLike, req, ro)
arg2(ArrayLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Array::Func::Ne is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Ne';

ok 1 and done_testing;
