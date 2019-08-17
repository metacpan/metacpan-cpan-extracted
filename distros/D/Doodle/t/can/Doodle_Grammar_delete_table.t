use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

delete_table

=usage

  my $delete_table = $self->delete_table;

=description

Generate SQL statement for table-delete Command.

=signature

delete_table(Command $command) : Str

=type

method

=cut

# TESTING

use Doodle::Grammar;

can_ok "Doodle::Grammar", "delete_table";

ok 1 and done_testing;
