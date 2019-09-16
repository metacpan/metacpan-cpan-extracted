use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Number::Func::Neg

=abstract

Data-Object Number Function (Neg) Class

=synopsis

  use Data::Object::Number::Func::Neg;

  my $func = Data::Object::Number::Func::Neg->new(@args);

  $func->execute;

=inherits

Data::Object::Number::Func

=attributes

arg1(NumberLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Number::Func::Neg is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Number::Func::Neg';

ok 1 and done_testing;
