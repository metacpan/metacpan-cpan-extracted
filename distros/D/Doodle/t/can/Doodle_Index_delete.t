use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

delete

=usage

  my $delete = $self->delete;

=description

Registers an index delete and returns the Command object.

=signature

delete(Any %args) : Command

=type

method

=cut

# TESTING

use Doodle::Index;

can_ok "Doodle::Index", "delete";

ok 1 and done_testing;
