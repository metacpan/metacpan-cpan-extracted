use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

registry

=usage

  registry; # Data::Object::Registry

=description

The registry function returns the registry singleton object where mapping
between namespaces and type libraries are registered.

=signature

registry() : Object

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'registry';

ok 1 and done_testing;
