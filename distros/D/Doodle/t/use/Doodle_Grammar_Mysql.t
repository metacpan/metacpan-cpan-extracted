use 5.014;

use strict;
use warnings;

use Test::More;

=name

Doodle::Grammar::Mysql

=abstract

Doodle Grammar For MySQL

=synopsis

  use Doodle::Grammar::Mysql;

  my $self = Doodle::Grammar::Mysql->new(%args);

=description

Doodle::Grammar::Mysql determines how Command classes should be interpreted to
produce the correct DDL statements.

=cut

use_ok "Doodle::Grammar::Mysql";

ok 1 and done_testing;
