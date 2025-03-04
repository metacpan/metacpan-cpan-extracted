use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Number::Func::To

=abstract

Data-Object Number Function (To) Class

=synopsis

  use Data::Object::Number::Func::To;

  my $func = Data::Object::Number::Func::To->new(@args);

  $func->execute;

=inherits

Data::Object::Number::Func

=attributes

arg1(NumberLike, req, ro)
arg2(StringLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Number::Func::To is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Number::Func::To';

ok 1 and done_testing;
