use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Number::Func::Eq

=abstract

Data-Object Number Function (Eq) Class

=synopsis

  use Data::Object::Number::Func::Eq;

  my $func = Data::Object::Number::Func::Eq->new(@args);

  $func->execute;

=inherits

Data::Object::Number::Func

=attributes

arg1(Object, req, ro)
arg2(StringLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Number::Func::Eq is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Number::Func::Eq';

ok 1 and done_testing;
