use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

schema_delete

=usage

  my $command = $self->schema_delete(%args);

=description

Registers a schema delete and returns the Command object.

=signature

schema_delete(Any %args) : Command

=type

method

=cut

# TESTING

use Doodle;

can_ok "Doodle", "schema_delete";

ok 1 and done_testing;
