use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

delete_index

=usage

  use Doodle;

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $i = $t->index(columns => ['id']);

  my $command = $i->delete;

  $self->delete_index($command);

  # drop index `indx_users_id`

=description

Returns the SQL statement for the delete index command.

=signature

delete_index(Command $command) : Str

=type

method

=cut

# TESTING

use Doodle;
use Doodle::Grammar::Mysql;

use_ok 'Doodle::Grammar::Mysql', 'delete_index';

my $d = Doodle->new;
my $g = Doodle::Grammar::Mysql->new;
my $t = $d->table('users');
my $i = $t->index(columns => ['id']);

my $command = $i->delete;

my $sql = $g->delete_index($command);

isa_ok $g, 'Doodle::Grammar::Mysql';
isa_ok $command, 'Doodle::Command';

is $sql, qq{drop index `indx_users_id`};

ok 1 and done_testing;
