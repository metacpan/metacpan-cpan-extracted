use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

create_column

=usage

  my $create_column = $self->create_column;

=description

Generate SQL statement for column-create Command.

=signature

create_column(Command $command) : Str

=type

method

=cut

# TESTING

use Doodle::Grammar;

can_ok "Doodle::Grammar", "create_column";

ok 1 and done_testing;
