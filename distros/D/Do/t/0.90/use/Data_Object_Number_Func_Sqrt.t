use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Number::Func::Sqrt

=abstract

Data-Object Number Function (Sqrt) Class

=synopsis

  use Data::Object::Number::Func::Sqrt;

  my $func = Data::Object::Number::Func::Sqrt->new(@args);

  $func->execute;

=inherits

Data::Object::Number::Func

=attributes

arg1(NumberLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Number::Func::Sqrt is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Number::Func::Sqrt';

ok 1 and done_testing;
