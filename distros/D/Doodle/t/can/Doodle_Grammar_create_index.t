use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

create_index

=usage

  my $create_index = $self->create_index;

=description

Generate SQL statement for index-create Command.

=signature

create_index(Command $command) : Str

=type

method

=cut

# TESTING

use Doodle::Grammar;

can_ok "Doodle::Grammar", "create_index";

ok 1 and done_testing;
