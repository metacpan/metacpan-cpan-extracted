use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

parameterize_coercions

=usage

  my $parameterize_coercions = $self->parameterize_coercions();

=description

The parameterize_coercions method returns truthy if parameterized type check is valid.

=signature

parameterize(Object $arg1, Object $arg2) : Num

=type

method

=cut

# TESTING

use_ok 'Data::Object::Type::Array';

my $data = Data::Object::Type::Array->new();

can_ok $data, 'parameterize_coercions';

ok 1 and done_testing;
