use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

delete_column

=usage

  my $delete_column = $self->delete_column;

=description

Generate SQL statement for column-delete Command.

=signature

delete_column(Command $command) : Str

=type

method

=cut

# TESTING

use Doodle::Grammar;

can_ok "Doodle::Grammar", "delete_column";

ok 1 and done_testing;
