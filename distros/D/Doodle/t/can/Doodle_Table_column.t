use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

column

=usage

  my $column = $self->column;

=description

Returns a new Column object.

=signature

column(Str $name, Any @args) : Column

=type

method

=cut

# TESTING

use Doodle::Table;

can_ok "Doodle::Table", "column";

ok 1 and done_testing;
