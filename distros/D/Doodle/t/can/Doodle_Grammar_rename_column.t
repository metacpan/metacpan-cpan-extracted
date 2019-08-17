use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

rename_column

=usage

  my $rename_column = $self->rename_column;

=description

Generate SQL statement for column-rename Command.

=signature

rename_column(Command $command) : Str

=type

method

=cut

# TESTING

use Doodle::Grammar;

can_ok "Doodle::Grammar", "rename_column";

ok 1 and done_testing;
