use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

eq

=usage

  my $eq = $self->eq();

=description

The eq method returns truthy if argument and object data are equal.

=signature

eq(Any $arg1) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Any';

my $data = Data::Object::Any->new(123);

ok !eval { $data->eq() };

ok 1 and done_testing;
