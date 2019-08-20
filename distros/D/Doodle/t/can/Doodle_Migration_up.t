use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

up

=usage

  $doodle = $self->up($doodle);

=description

The migrate "UP" method is invoked automatically by the migrator
L<Doodle::Migrator>.

=signature

up(Doodle $doodle) : Doodle

=type

method

=cut

# TESTING

use Doodle::Migration;

can_ok "Doodle::Migration", "up";

ok 1 and done_testing;
