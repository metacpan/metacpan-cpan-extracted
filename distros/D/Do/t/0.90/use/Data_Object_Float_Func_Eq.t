use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Float::Func::Eq

=abstract

Data-Object Float Function (Eq) Class

=synopsis

  use Data::Object::Float::Func::Eq;

  my $func = Data::Object::Float::Func::Eq->new(@args);

  $func->execute;

=inherits

Data::Object::Float::Func

=description

Data::Object::Float::Func::Eq is a function object for Data::Object::Float.

=cut

# TESTING

use_ok 'Data::Object::Float::Func::Eq';

ok 1 and done_testing;
