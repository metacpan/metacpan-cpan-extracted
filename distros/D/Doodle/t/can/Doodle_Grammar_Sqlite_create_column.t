use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

create_column

=usage

  use Doodle;

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $c = $t->primary('id');

  my $command = $c->create;

  $self->create_column($command);

  # alter table "users" add column "id" integer primary key

=description

Returns the SQL statement for the create column command.

=signature

create_column(Command $command) : Str

=type

method

=cut

# TESTING

use Doodle;
use Doodle::Grammar::Sqlite;

use_ok 'Doodle::Grammar::Sqlite', 'create_column';

my $d = Doodle->new;
my $g = Doodle::Grammar::Sqlite->new;
my $t = $d->table('users');
my $c = $t->primary('id');

my $command = $c->create;

my $sql = $g->create_column($command);

isa_ok $g, 'Doodle::Grammar::Sqlite';
isa_ok $command, 'Doodle::Command';

is $sql, qq{alter table "users" add column "id" integer primary key};

ok 1 and done_testing;
