use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

update

=usage

  my $update = $self->update;

=description

Registers a column update and returns the Command object.

=signature

update(Any %args) : Command

=type

method

=cut

# TESTING

use Doodle::Column;

can_ok "Doodle::Column", "update";

ok 1 and done_testing;
