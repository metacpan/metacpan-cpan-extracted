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

=description

Data::Object::Code::Func::Curry is a function object for Data::Object::Code.
This package inherits all behavior from L<Data::Object::Code::Func>.

=cut

# TESTING

use_ok 'Data::Object::Code::Func::Curry';

ok 1 and done_testing;
