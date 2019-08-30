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

=description

Data::Object::Code::Func::Disjoin is a function object for Data::Object::Code.
This package inherits all behavior from L<Data::Object::Code::Func>.

=cut

# TESTING

use_ok 'Data::Object::Code::Func::Disjoin';

ok 1 and done_testing;
