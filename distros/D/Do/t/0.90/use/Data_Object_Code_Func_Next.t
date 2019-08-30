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

=description

Data::Object::Code::Func::Next is a function object for Data::Object::Code.
This package inherits all behavior from L<Data::Object::Code::Func>.

=cut

# TESTING

use_ok 'Data::Object::Code::Func::Next';

ok 1 and done_testing;
