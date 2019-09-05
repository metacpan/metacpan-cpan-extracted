use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Code::Func::Defined

=abstract

Data-Object Code Function (Defined) Class

=synopsis

  use Data::Object::Code::Func::Defined;

  my $func = Data::Object::Code::Func::Defined->new(@args);

  $func->execute;

=inherits

Data::Object::Code::Func

=description

Data::Object::Code::Func::Defined is a function object for Data::Object::Code.

=cut

# TESTING

use_ok 'Data::Object::Code::Func::Defined';

ok 1 and done_testing;
