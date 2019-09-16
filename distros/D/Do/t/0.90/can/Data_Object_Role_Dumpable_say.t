use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

say

=usage

  my $say = $self->say();

=description

Output stringified object data with newline.

=signature

say() : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Role::Dumpable';

my $data = 'Data::Object::Role::Dumpable';

can_ok $data, 'say';

ok 1 and done_testing;
