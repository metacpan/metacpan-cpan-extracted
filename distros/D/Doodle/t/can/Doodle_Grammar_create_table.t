use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

create_table

=usage

  my $create_table = $self->create_table;

=description

Generate SQL statement for table-create Command.

=signature

create_table(Command $command) : Str

=type

method

=cut

# TESTING

use Doodle::Grammar;

can_ok "Doodle::Grammar", "create_table";

ok 1 and done_testing;
