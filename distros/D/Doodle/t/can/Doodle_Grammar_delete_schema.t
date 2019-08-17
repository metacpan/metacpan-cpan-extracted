use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

delete_schema

=usage

  my $delete_schema = $self->delete_schema;

=description

Generate SQL statement for schema-delete Command.

=signature

delete_schema(Command $command) : Str

=type

method

=cut

# TESTING

use Doodle::Grammar;

can_ok "Doodle::Grammar", "delete_schema";

ok 1 and done_testing;
