use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Number::Func::Decr

=abstract

Data-Object Number Function (Decr) Class

=synopsis

  use Data::Object::Number::Func::Decr;

  my $func = Data::Object::Number::Func::Decr->new(@args);

  $func->execute;

=inherits

Data::Object::Number::Func

=attributes

arg1(NumberLike, req, ro)
arg2(StringLike, opt, ro)

=libraries

Data::Object::Library

=description

Data::Object::Number::Func::Decr is a function object for Data::Object::Number.

=cut

# TESTING

use_ok 'Data::Object::Number::Func::Decr';

ok 1 and done_testing;
