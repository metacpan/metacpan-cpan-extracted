use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

table_create

=usage

  my $command = $self->table_create(%args);

=description

Registers a table create and returns the Command object.

=signature

table_create(Any %args) : Command

=type

method

=cut

# TESTING

use Doodle::Helpers;

can_ok "Doodle::Helpers", "table_create";

ok 1 and done_testing;
