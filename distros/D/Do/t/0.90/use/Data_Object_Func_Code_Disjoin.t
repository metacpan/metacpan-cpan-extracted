use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Code::Disjoin

=abstract

Data-Object Code Function (Disjoin) Class

=synopsis

  use Data::Object::Func::Code::Disjoin;

  my $func = Data::Object::Func::Code::Disjoin->new(@args);

  $func->execute;

=description

Data::Object::Func::Code::Disjoin is a function object for Data::Object::Code.

=cut

# TESTING

use_ok 'Data::Object::Func::Code::Disjoin';

ok 1 and done_testing;
