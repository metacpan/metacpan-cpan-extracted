use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Code::Func::Conjoin

=abstract

Data-Object Code Function (Conjoin) Class

=synopsis

  use Data::Object::Code::Func::Conjoin;

  my $func = Data::Object::Code::Func::Conjoin->new(@args);

  $func->execute;

=inherits

Data::Object::Code::Func

=attributes

arg1(Object, req, ro)
arg2(CodeRef, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Code::Func::Conjoin is a function object for Data::Object::Code.

=cut

# TESTING

use_ok 'Data::Object::Code::Func::Conjoin';

ok 1 and done_testing;
