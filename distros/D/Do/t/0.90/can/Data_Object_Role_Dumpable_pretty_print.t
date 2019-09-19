use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

pretty_print

=usage

  my $pretty_print = $self->pretty_print();

=description

The pretty_print method prints a stringified human-readable representation of
the underlying data.

=signature

pretty_print() : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Role::Dumpable';

my $data = 'Data::Object::Role::Dumpable';

can_ok $data, 'pretty_print';

ok 1 and done_testing;
