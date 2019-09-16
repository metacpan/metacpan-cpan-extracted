use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

dump

=usage

  my $dump = $self->dump();

=description

The dump method returns a string representation of the underlying data.

=signature

dump() : Str

=type

method

=cut

# TESTING

use_ok 'Data::Object::Role::Dumpable';

my $data = 'Data::Object::Role::Dumpable';

can_ok $data, 'dump';

ok 1 and done_testing;
