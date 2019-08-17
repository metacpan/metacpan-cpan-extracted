use 5.014;

use strict;
use warnings;

use Test::More;

=name

Doodle::Grammar::Postgres

=abstract

Doodle Grammar For PostgreSQL

=synopsis

  use Doodle::Grammar::Postgres;

  my $self = Doodle::Grammar::Postgres->new(%args);

=description

Doodle::Grammar::Postgres determines how Command classes should be interpreted
to produce the correct DDL statements.

=cut

use_ok "Doodle::Grammar::Postgres";

ok 1 and done_testing;
