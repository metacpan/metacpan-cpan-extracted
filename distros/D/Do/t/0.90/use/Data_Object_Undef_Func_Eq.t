use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Undef::Func::Eq

=abstract

Data-Object Undef Function (Eq) Class

=synopsis

  use Data::Object::Undef::Func::Eq;

  my $func = Data::Object::Undef::Func::Eq->new(@args);

  $func->execute;

=inherits

Data::Object::Undef::Func

=attributes

arg1(Any, req, ro)
arg2(Any, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Undef::Func::Eq is a function object for Data::Object::Undef.

=cut

# TESTING

use_ok 'Data::Object::Undef::Func::Eq';

ok 1 and done_testing;
