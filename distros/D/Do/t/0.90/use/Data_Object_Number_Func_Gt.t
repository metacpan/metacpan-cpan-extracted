use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Number::Func::Gt

=abstract

Data-Object Number Function (Gt) Class

=synopsis

  use Data::Object::Number::Func::Gt;

  my $func = Data::Object::Number::Func::Gt->new(@args);

  $func->execute;

=inherits

Data::Object::Number::Func

=attributes

arg1(NumberLike, req, ro)
arg2(StringLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Number::Func::Gt is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Number::Func::Gt';

ok 1 and done_testing;
