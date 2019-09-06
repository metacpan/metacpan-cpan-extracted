use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Code::Func::Curry

=abstract

Data-Object Code Function (Curry) Class

=synopsis

  use Data::Object::Code::Func::Curry;

  my $func = Data::Object::Code::Func::Curry->new(@args);

  $func->execute;

=inherits

Data::Object::Code::Func

=attributes

arg1(Object, req, ro)
args(ArrayRef[Any], opt, ro)

=libraries

Data::Object::Library

=description

Data::Object::Code::Func::Curry is a function object for Data::Object::Code.

=cut

# TESTING

use_ok 'Data::Object::Code::Func::Curry';

ok 1 and done_testing;
