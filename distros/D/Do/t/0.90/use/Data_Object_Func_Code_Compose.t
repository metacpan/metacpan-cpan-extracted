use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Code::Compose

=abstract

Data-Object Code Function (Compose) Class

=synopsis

  use Data::Object::Func::Code::Compose;

  my $func = Data::Object::Func::Code::Compose->new(@args);

  $func->execute;

=description

Data::Object::Func::Code::Compose is a function object for Data::Object::Code.

=cut

# TESTING

use_ok 'Data::Object::Func::Code::Compose';

ok 1 and done_testing;
