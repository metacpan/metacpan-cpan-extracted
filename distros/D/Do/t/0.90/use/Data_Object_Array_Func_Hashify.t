use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Hashify

=abstract

Data-Object Array Function (Hashify) Class

=synopsis

  use Data::Object::Array::Func::Hashify;

  my $func = Data::Object::Array::Func::Hashify->new(@args);

  $func->execute;

=inherits

Data::Object::Array::Func

=attributes

arg1(Object, req, ro)
arg2(Undef | CodeRef, opt, ro)
args(ArrayRef[Any], opt, ro)

=libraries

Data::Object::Library

=description

Data::Object::Array::Func::Hashify is a function object for
Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Hashify';

ok 1 and done_testing;
