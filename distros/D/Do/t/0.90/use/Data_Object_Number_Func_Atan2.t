use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Number::Func::Atan2

=abstract

Data-Object Number Function (Atan2) Class

=synopsis

  use Data::Object::Number::Func::Atan2;

  my $func = Data::Object::Number::Func::Atan2->new(@args);

  $func->execute;

=inherits

Data::Object::Number::Func

=attributes

arg1(NumberLike, req, ro)
arg2(StringLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Number::Func::Atan2 is a function object for
Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Number::Func::Atan2';

ok 1 and done_testing;
