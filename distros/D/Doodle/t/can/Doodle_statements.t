use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

statements

=usage

  my $statements = $self->statements($grammar);

=description

Returns a set of Statement objects for the given grammar.

=signature

statements(Grammar $g) : [Statement]

=type

method

=cut

# TESTING

use Doodle;

can_ok "Doodle", "statements";

ok 1 and done_testing;
