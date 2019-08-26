use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Code::Defined

=abstract

Data-Object Code Function (Defined) Class

=synopsis

  use Data::Object::Func::Code::Defined;

  my $func = Data::Object::Func::Code::Defined->new(@args);

  $func->execute;

=description

Data::Object::Func::Code::Defined is a function object for Data::Object::Code.

=cut

# TESTING

use_ok 'Data::Object::Func::Code::Defined';

ok 1 and done_testing;
