use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

obj

=usage

  my $obj = $registry->obj($key);

=description

Return the L<Type::Registry> object for a given namespace.

=signature

obj(ClassName $arg1) : InstanceOf[Type::Registry]

=type

method

=cut

# TESTING

use_ok 'Data::Object::Registry';

my $data = Data::Object::Registry->new();

isa_ok $data->obj('main'), 'Type::Registry';

ok 1 and done_testing;
