use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

update_column

=usage

  my $update_column = $self->update_column;

=description

Generate SQL statement for column-update Command.

=signature

update_column(Any @args) : Object

=type

method

=cut

# TESTING

use Doodle::Grammar;

can_ok "Doodle::Grammar", "update_column";

ok 1 and done_testing;
