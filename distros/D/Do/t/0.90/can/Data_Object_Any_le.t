use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

le

=usage

  my $le = $self->le();

=description

The le method returns truthy if argument is lesser or equal to the object data.

=signature

le(Any $arg1) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Any';

my $data = Data::Object::Any->new(123);

ok !eval { $data->le() };

ok 1 and done_testing;
