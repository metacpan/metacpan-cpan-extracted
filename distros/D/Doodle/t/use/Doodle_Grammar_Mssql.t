use 5.014;

use strict;
use warnings;

use Test::More;

=name

Doodle::Grammar::Mssql

=abstract

Doodle Grammar For MSSQL

=synopsis

  use Doodle::Grammar::Mssql;

  my $self = Doodle::Grammar::Mssql->new(%args);

=description

Doodle::Grammar::Mssql determines how Command classes should be interpreted to
produce the correct DDL statements.

=cut

use_ok "Doodle::Grammar::Mssql";

ok 1 and done_testing;
