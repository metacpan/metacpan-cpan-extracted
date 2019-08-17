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

Registers an index create and returns the Command object.

=signature

create(Any %args) : Command

=type

method

=cut

# TESTING

use Doodle::Index;

can_ok "Doodle::Index", "create";

ok 1 and done_testing;
