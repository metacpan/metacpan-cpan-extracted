use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

column_delete

=usage

  my $command = $self->column_delete(%args);

=description

Registers a column delete and returns the Command object.

=signature

column_delete(Any %args) : Command

=type

method

=cut

# TESTING

use Doodle;

can_ok "Doodle", "column_delete";

ok 1 and done_testing;
