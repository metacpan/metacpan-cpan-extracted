use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

delete_column

=usage

  use Doodle;

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $c = $t->primary('id');

  my $command = $c->delete;

  $self->delete_column($command);

  # alter table "users" drop column "id"

=description

Returns the SQL statement for the delete column command.

=signature

delete_column(Command $command) : Str

=type

method

=cut

# TESTING

use Doodle;
use Doodle::Grammar::Sqlite;

use_ok 'Doodle::Grammar::Sqlite', 'delete_column';

my $d = Doodle->new;
my $g = Doodle::Grammar::Sqlite->new;
my $t = $d->table('users');
my $c = $t->primary('id');

my $command = $c->delete;

my $sql = $g->delete_column($command);

isa_ok $g, 'Doodle::Grammar::Sqlite';
isa_ok $command, 'Doodle::Command';

is $sql, qq{alter table "users" drop column "id"};

ok 1 and done_testing;
