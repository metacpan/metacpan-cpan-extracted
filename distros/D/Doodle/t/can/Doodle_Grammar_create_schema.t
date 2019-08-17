use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

create_schema

=usage

  my $create_schema = $self->create_schema;

=description

Generate SQL statement for schema-create Command.

=signature

create_schema(Command $command) : Str

=type

method

=cut

# TESTING

use Doodle::Grammar;

can_ok "Doodle::Grammar", "create_schema";

ok 1 and done_testing;
