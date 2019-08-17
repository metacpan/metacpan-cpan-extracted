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

Registers a table delete and returns the Command object.

=signature

delete(Any %args) : Command

=type

method

=cut

# TESTING

use Doodle::Table;

can_ok "Doodle::Table", "delete";

ok 1 and done_testing;
