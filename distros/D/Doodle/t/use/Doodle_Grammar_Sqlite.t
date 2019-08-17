use 5.014;

use strict;
use warnings;

use Test::More;

=name

Doodle::Grammar::Sqlite

=abstract

Doodle Grammar For SQLite

=synopsis

  use Doodle::Grammar::Sqlite;

  my $self = Doodle::Grammar::Sqlite->new(%args);

=description

Doodle::Grammar::Sqlite determines how Command classes should be interpreted to
produce the correct DDL statements.

=cut

use_ok "Doodle::Grammar::Sqlite";

ok 1 and done_testing;
