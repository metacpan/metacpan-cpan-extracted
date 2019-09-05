use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Undef::Func::Ge

=abstract

Data-Object Undef Function (Ge) Class

=synopsis

  use Data::Object::Undef::Func::Ge;

  my $func = Data::Object::Undef::Func::Ge->new(@args);

  $func->execute;

=inherits

Data::Object::Undef::Func

=description

Data::Object::Undef::Func::Ge is a function object for Data::Object::Undef.

=cut

# TESTING

use_ok 'Data::Object::Undef::Func::Ge';

ok 1 and done_testing;
