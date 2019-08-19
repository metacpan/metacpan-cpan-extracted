use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

table_delete

=usage

  my $command = $self->table_delete(%args);

=description

Registers a table delete and returns the Command object.

=signature

table_delete(Any %args) : Command

=type

method

=cut

# TESTING

use Doodle::Helpers;

can_ok "Doodle::Helpers", "table_delete";

ok 1 and done_testing;
