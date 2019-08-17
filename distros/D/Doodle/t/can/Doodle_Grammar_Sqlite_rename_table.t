use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

rename_table

=usage

  use Doodle;

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $c = $t->column('data');

  my $command = $t->rename('people');

  $self->rename_table($command);

  # alter table "users" rename to "people"

=description

Returns the SQL statement for the rename table command.

=signature

rename_table(Command $command) : Str

=type

method

=cut

# TESTING

use Doodle;
use Doodle::Grammar::Sqlite;

use_ok 'Doodle::Grammar::Sqlite', 'rename_table';

my $d = Doodle->new;
my $g = Doodle::Grammar::Sqlite->new;
my $t = $d->table('users');
my $c = $t->column('data');

my $command = $t->rename('people');

my $sql = $g->rename_table($command);

isa_ok $g, 'Doodle::Grammar::Sqlite';
isa_ok $command, 'Doodle::Command';

is $sql, qq{alter table "users" rename to "people"};

ok 1 and done_testing;
