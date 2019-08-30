use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Code::Func::Call

=abstract

Data-Object Code Function (Call) Class

=synopsis

  use Data::Object::Code::Func::Call;

  my $func = Data::Object::Code::Func::Call->new(@args);

  $func->execute;

=description

Data::Object::Code::Func::Call is a function object for Data::Object::Code.
This package inherits all behavior from L<Data::Object::Code::Func>.

=cut

# TESTING

use_ok 'Data::Object::Code::Func::Call';

ok 1 and done_testing;
