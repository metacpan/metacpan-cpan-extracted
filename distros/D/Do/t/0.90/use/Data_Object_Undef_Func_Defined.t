use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Undef::Func::Defined

=abstract

Data-Object Undef Function (Defined) Class

=synopsis

  use Data::Object::Undef::Func::Defined;

  my $func = Data::Object::Undef::Func::Defined->new(@args);

  $func->execute;

=inherits

Data::Object::Undef::Func

=attributes

arg1(Object, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Undef::Func::Defined is a function object for
Data::Object::Undef.

=cut

# TESTING

use_ok 'Data::Object::Undef::Func::Defined';

ok 1 and done_testing;
