use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

rename_column

=usage

  use Doodle;

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $c = $t->primary('id');

  my $command = $c->rename('uid');

  $self->rename_column($command);

  # alter table "users" rename column "id" to "uid"

=description

Returns the SQL statement for the rename column command.

=signature

rename_column(Command $command) : Str

=type

method

=cut

# TESTING

use Doodle;
use Doodle::Grammar::Postgres;

use_ok 'Doodle::Grammar::Postgres', 'rename_column';

my $d = Doodle->new;
my $g = Doodle::Grammar::Postgres->new;
my $t = $d->table('users');
my $c = $t->primary('id');

my $command = $c->rename('uid');

my $sql = $g->rename_column($command);

isa_ok $g, 'Doodle::Grammar::Postgres';
isa_ok $command, 'Doodle::Command';

is $sql, qq{alter table "users" rename column "id" to "uid"};

ok 1 and done_testing;
