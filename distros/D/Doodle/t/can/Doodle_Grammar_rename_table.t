use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

rename_table

=usage

  my $rename_table = $self->rename_table;

=description

Generate SQL statement for table-rename Command.

=signature

rename_table(Command $command) : Str

=type

method

=cut

# TESTING

use Doodle::Grammar;

can_ok "Doodle::Grammar", "rename_table";

ok 1 and done_testing;
