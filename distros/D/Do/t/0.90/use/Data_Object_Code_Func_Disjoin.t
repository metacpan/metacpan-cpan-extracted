use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Code::Func::Disjoin

=abstract

Data-Object Code Function (Disjoin) Class

=synopsis

  use Data::Object::Code::Func::Disjoin;

  my $func = Data::Object::Code::Func::Disjoin->new(@args);

  $func->execute;

=inherits

Data::Object::Code::Func

=attributes

arg1(CodeLike, req, ro)
arg2(CodeLike, req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Code::Func::Disjoin is a function object for Data::Object::Code.

=cut

# TESTING

use_ok 'Data::Object::Code::Func::Disjoin';

ok 1 and done_testing;
