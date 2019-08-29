use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Any::Func::Ge

=abstract

Data-Object Any Function (Ge) Class

=synopsis

  use Data::Object::Any::Func::Ge;

  my $func = Data::Object::Any::Func::Ge->new(@args);

  $func->execute;

=description

Data::Object::Any::Func::Ge is a function object for Data::Object::Any.

=cut

# TESTING

use_ok 'Data::Object::Any::Func::Ge';

ok 1 and done_testing;
