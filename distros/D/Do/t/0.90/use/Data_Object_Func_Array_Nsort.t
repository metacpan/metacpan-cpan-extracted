use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Array::Nsort

=abstract

Data-Object Array Function (Nsort) Class

=synopsis

  use Data::Object::Func::Array::Nsort;

  my $func = Data::Object::Func::Array::Nsort->new(@args);

  $func->execute;

=description

Data::Object::Func::Array::Nsort is a function object for Data::Object::Array.

=cut

# TESTING

use_ok 'Data::Object::Func::Array::Nsort';

ok 1 and done_testing;
