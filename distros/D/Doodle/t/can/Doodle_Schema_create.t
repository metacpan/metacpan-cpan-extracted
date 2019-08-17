use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

create

=usage

  my $create = $self->create;

=description

Registers a schema create and returns the Command object.

=signature

create(Any %args) : Command

=type

method

=cut

# TESTING

use Doodle::Schema;

can_ok "Doodle::Schema", "create";

ok 1 and done_testing;
