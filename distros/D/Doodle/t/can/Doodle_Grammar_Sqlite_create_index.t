use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

create_index

=usage

  use Doodle;

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $i = $t->index(columns => ['id']);

  my $command = $i->create;

  $self->create_index($command);

  # create index "indx_users_id" on "users" ("id")

=description

Returns the SQL statement for the create index command.

=signature

create_index(Command $command) : Str

=type

method

=cut

# TESTING

use Doodle;
use Doodle::Grammar::Sqlite;

use_ok 'Doodle::Grammar::Sqlite', 'create_index';

my $d = Doodle->new;
my $g = Doodle::Grammar::Sqlite->new;
my $t = $d->table('users');
my $i = $t->index(columns => ['id']);

my $command = $i->create;

my $sql = $g->create_index($command);

isa_ok $g, 'Doodle::Grammar::Sqlite';
isa_ok $command, 'Doodle::Command';

is $sql, qq{create index "indx_users_id" on "users" ("id")};

ok 1 and done_testing;
