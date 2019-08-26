use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

lt

=usage

  my $lt = $self->lt();

=description

The lt method returns truthy if argument is lesser than the object data.

=signature

lt(Any $arg1) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Any';

my $data = Data::Object::Any->new(123);

ok !eval { $data->lt() };

ok 1 and done_testing;
