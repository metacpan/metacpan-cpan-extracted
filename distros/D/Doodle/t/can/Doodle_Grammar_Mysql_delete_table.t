use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

delete_table

=usage

  use Doodle;

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $c = $t->column('data');

  my $command = $t->delete;

  $self->delete_table($command);

  # drop table `users`

=description

Returns the SQL statement for the delete table command.

=signature

delete_table(Command $command) : Str

=type

method

=cut

# TESTING

use Doodle;
use Doodle::Grammar::Mysql;

use_ok 'Doodle::Grammar::Mysql', 'delete_table';

my $d = Doodle->new;
my $g = Doodle::Grammar::Mysql->new;
my $t = $d->table('users');
my $c = $t->column('data');

my $command = $t->delete;

my $sql = $g->delete_table($command);

isa_ok $g, 'Doodle::Grammar::Mysql';
isa_ok $command, 'Doodle::Command';

is $sql, qq{drop table `users`};

ok 1 and done_testing;
