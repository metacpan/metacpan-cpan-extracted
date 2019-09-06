use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Number::Func::Pow

=abstract

Data-Object Number Function (Pow) Class

=synopsis

  use Data::Object::Number::Func::Pow;

  my $func = Data::Object::Number::Func::Pow->new(@args);

  $func->execute;

=inherits

Data::Object::Number::Func

=attributes

arg1(Object, req, ro)
arg2(StringLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Number::Func::Pow is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Number::Func::Pow';

ok 1 and done_testing;
