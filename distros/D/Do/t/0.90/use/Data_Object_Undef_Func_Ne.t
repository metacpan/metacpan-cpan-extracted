use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Undef::Func::Ne

=abstract

Data-Object Undef Function (Ne) Class

=synopsis

  use Data::Object::Undef::Func::Ne;

  my $func = Data::Object::Undef::Func::Ne->new(@args);

  $func->execute;

=inherits

Data::Object::Undef::Func

=attributes

arg1(Object, req, ro)
arg2(Any, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Undef::Func::Ne is a function object for Data::Object::Undef.

=cut

# TESTING

use_ok 'Data::Object::Undef::Func::Ne';

ok 1 and done_testing;
