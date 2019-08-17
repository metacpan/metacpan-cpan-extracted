use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

delete_index

=usage

  my $delete_index = $self->delete_index;

=description

Generate SQL statement for index-delete Command.

=signature

delete_index(Command $command) : Str

=type

method

=cut

# TESTING

use Doodle::Grammar;

can_ok "Doodle::Grammar", "delete_index";

ok 1 and done_testing;
