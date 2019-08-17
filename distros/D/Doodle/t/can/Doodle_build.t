use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

build

=usage

  $self->build($grammar, sub {
    my $statement = shift;

    # e.g. $db->do($statement->sql);
  });

=description

Execute a given callback for each generated SQL statement.

=signature

build(Grammar $g, CodeRef $callback) : ()

=type

method

=cut

# TESTING

use Doodle;

can_ok "Doodle", "build";

ok 1 and done_testing;
