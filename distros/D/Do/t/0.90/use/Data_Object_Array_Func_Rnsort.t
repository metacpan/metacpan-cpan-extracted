use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::Rnsort

=abstract

Data-Object Array Function (Rnsort) Class

=synopsis

  use Data::Object::Array::Func::Rnsort;

  my $func = Data::Object::Array::Func::Rnsort->new(@args);

  $func->execute;

=inherits

Data::Object::Array::Func

=description

Data::Object::Array::Func::Rnsort is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::Rnsort';

ok 1 and done_testing;
