use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

ne

=usage

  my $ne = $self->ne();

=description

The ne method returns truthy if argument and object data are not equal.

=signature

ne(Any $arg1) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Any';

my $data = Data::Object::Any->new(123);

ok !eval { $data->ne() };

ok 1 and done_testing;
