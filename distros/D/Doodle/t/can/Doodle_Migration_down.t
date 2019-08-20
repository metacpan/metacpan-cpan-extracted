use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

down

=usage

  $doodle = $self->down($doodle);

=description

The migrate "DOWN" method is invoked automatically by the migrator
L<Doodle::Migrator>.

=signature

down(Doodle $doodle) : Doodle

=type

method

=cut

# TESTING

use Doodle::Migration;

can_ok "Doodle::Migration", "down";

ok 1 and done_testing;
