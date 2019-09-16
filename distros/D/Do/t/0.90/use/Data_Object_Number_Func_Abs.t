use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Number::Func::Abs

=abstract

Data-Object Number Function (Abs) Class

=synopsis

  use Data::Object::Number::Func::Abs;

  my $func = Data::Object::Number::Func::Abs->new(@args);

  $func->execute;

=inherits

Data::Object::Number::Func

=attributes

arg1(NumberLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Number::Func::Abs is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Number::Func::Abs';

ok 1 and done_testing;
