use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

column_update

=usage

  my $command = $self->column_update(%args);

=description

Registers a column update and returns the Command object.

=signature

column_update(Any %args) : Command

=type

method

=cut

# TESTING

use Doodle::Helpers;

can_ok "Doodle::Helpers", "column_update";

ok 1 and done_testing;
