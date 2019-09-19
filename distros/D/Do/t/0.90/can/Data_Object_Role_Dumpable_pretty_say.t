use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

pretty_say

=usage

  my $pretty_say = $self->pretty_say();

=description

The pretty_say method prints a stringified human-readable representation of the
underlying data. This prints with a trailing newline.

=signature

pretty_say() : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Role::Dumpable';

my $data = 'Data::Object::Role::Dumpable';

can_ok $data, 'pretty_say';

ok 1 and done_testing;
