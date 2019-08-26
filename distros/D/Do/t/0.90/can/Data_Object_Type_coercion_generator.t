use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

coercion_generator

=usage

  my $coercion_generator = $self->coercion_generator();

=description

coercion_generator

=signature

coercion_generator(Object $arg1, Object $arg2, Object $arg3) : Object

=type

method

=cut

# TESTING

use_ok 'Data::Object::Type';

my $data = Data::Object::Type->new();

can_ok $data, 'coercion_generator';

ok 1 and done_testing;
