use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

table

=usage

  my $table = $self->table;

=description

Returns a new Table object.

=signature

table(Str $name, Any @args) : Table

=type

method

=cut

# TESTING

use Doodle::Schema;

can_ok "Doodle::Schema", "table";

ok 1 and done_testing;
