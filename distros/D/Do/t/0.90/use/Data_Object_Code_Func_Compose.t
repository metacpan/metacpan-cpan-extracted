use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Code::Func::Compose

=abstract

Data-Object Code Function (Compose) Class

=synopsis

  use Data::Object::Code::Func::Compose;

  my $func = Data::Object::Code::Func::Compose->new(@args);

  $func->execute;

=inherits

Data::Object::Code::Func

=attributes

arg1(Object, req, ro)
arg2(CodeLike, req, ro)
args(ArrayRef[Any], req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Code::Func::Compose is a function object for Data::Object::Code.

=cut

# TESTING

use_ok 'Data::Object::Code::Func::Compose';

ok 1 and done_testing;
