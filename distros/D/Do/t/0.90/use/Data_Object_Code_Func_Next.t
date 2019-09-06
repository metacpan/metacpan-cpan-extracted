use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Code::Func::Next

=abstract

Data-Object Code Function (Next) Class

=synopsis

  use Data::Object::Code::Func::Next;

  my $func = Data::Object::Code::Func::Next->new(@args);

  $func->execute;

=inherits

Data::Object::Code::Func

=attributes

arg1(Object, req, ro)
args(ArrayRef[Any], opt, ro)

=libraries

Data::Object::Library

=description

Data::Object::Code::Func::Next is a function object for Data::Object::Code.

=cut

# TESTING

use_ok 'Data::Object::Code::Func::Next';

ok 1 and done_testing;
