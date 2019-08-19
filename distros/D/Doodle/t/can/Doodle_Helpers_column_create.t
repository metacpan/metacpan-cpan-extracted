use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

column_create

=usage

  my $command = $self->column_create(%args);

=description

Registers a column create and returns the Command object.

=signature

column_create(Any %args) : Command

=type

method

=cut

# TESTING

use Doodle::Helpers;

can_ok "Doodle::Helpers", "column_create";

ok 1 and done_testing;
