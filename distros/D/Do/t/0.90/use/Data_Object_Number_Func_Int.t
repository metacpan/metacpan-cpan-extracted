use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Number::Func::Int

=abstract

Data-Object Number Function (Int) Class

=synopsis

  use Data::Object::Number::Func::Int;

  my $func = Data::Object::Number::Func::Int->new(@args);

  $func->execute;

=inherits

Data::Object::Number::Func

=attributes

arg1(NumberLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Number::Func::Int is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Number::Func::Int';

ok 1 and done_testing;
