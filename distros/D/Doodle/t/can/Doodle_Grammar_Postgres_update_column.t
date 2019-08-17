use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

update_column

=usage

  use Doodle;

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $c = $t->primary('id');

  my $command = $c->update;

  $self->update_column($command);

  # alter table [users] alter column [id] type integer

  $command = $c->update(set => 'not null');

  $self->update_column($command);

  # alter table [users] alter column [id] set not null

=description

Returns the SQL statement for the update column command.

=signature

update_column(Command $command) : Command

=type

method

=cut

# TESTING

use Doodle;
use Doodle::Grammar::Postgres;

use_ok 'Doodle::Grammar::Postgres', 'update_column';

my $d = Doodle->new;
my $g = Doodle::Grammar::Postgres->new;
my $t = $d->table('users');
my $c = $t->primary('id');

my $command = $c->update;

my $sql = $g->update_column($command);

isa_ok $g, 'Doodle::Grammar::Postgres';
isa_ok $command, 'Doodle::Command';

is $sql, qq{alter table "users" alter column "id" type integer};

$command = $c->update(set => 'not null');
$sql = $g->update_column($command);

isa_ok $command, 'Doodle::Command';

is $sql, qq{alter table "users" alter column "id" set not null};

ok 1 and done_testing;
