use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::All

=abstract

Data-Object Array Function (All) Class

=synopsis

  use Data::Object::Array::Func::All;

  my $func = Data::Object::Array::Func::All->new(@args);

  $func->execute;

=inherits

Data::Object::Array::Func

=description

Data::Object::Array::Func::All is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::All';

ok 1 and done_testing;
