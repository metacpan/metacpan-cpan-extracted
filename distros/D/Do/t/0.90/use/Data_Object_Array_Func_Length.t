use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Length

=abstract

Data-Object Array Function (Length) Class

=synopsis

  use Data::Object::Array::Func::Length;

  my $func = Data::Object::Array::Func::Length->new(@args);

  $func->execute;

=inherits

Data::Object::Array::Func

=attributes

arg1(Object, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Array::Func::Length is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Length';

ok 1 and done_testing;
