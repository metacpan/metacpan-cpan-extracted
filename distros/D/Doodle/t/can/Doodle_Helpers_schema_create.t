use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

schema_create

=usage

  my $command = $self->schema_create(%args);

=description

Registers a schema create and returns the Command object.

=signature

schema_create(Any %args) : Command

=type

method

=cut

# TESTING

use Doodle::Helpers;

can_ok "Doodle::Helpers", "schema_create";

ok 1 and done_testing;
