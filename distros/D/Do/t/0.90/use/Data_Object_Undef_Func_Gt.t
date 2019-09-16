use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Undef::Func::Gt

=abstract

Data-Object Undef Function (Gt) Class

=synopsis

  use Data::Object::Undef::Func::Gt;

  my $func = Data::Object::Undef::Func::Gt->new(@args);

  $func->execute;

=inherits

Data::Object::Undef::Func

=attributes

arg1(Any, req, ro)
arg2(Any, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Undef::Func::Gt is a function object for Data::Object::Undef.

=cut

# TESTING

use_ok 'Data::Object::Undef::Func::Gt';

ok 1 and done_testing;
