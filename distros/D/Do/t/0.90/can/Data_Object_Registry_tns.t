use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

tns

=usage

  my $tns = $registry->tns();

=description

Returns the registered type-namespaces.

=signature

tns() : HashRef

=type

method

=cut

# TESTING

use_ok 'Data::Object::Registry';

my $data = Data::Object::Registry->new();

is_deeply $data->tns(), {};

ok 1 and done_testing;
