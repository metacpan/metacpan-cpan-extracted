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

  # alter table `users` add column `id` int auto_increment primary key

=description

Returns the SQL statement for the create column command.

=signature

create_column(Command $command) : Str

=type

method

=cut

# TESTING

use Doodle;
use Doodle::Grammar::Mysql;

use_ok 'Doodle::Grammar::Mysql', 'create_column';

my $d = Doodle->new;
my $g = Doodle::Grammar::Mysql->new;
my $t = $d->table('users');
my $c = $t->primary('id');

my $command = $c->create;

my $sql = $g->create_column($command);

isa_ok $g, 'Doodle::Grammar::Mysql';
isa_ok $command, 'Doodle::Command';

is $sql, qq{alter table `users` add column `id` int auto_increment primary key};

ok 1 and done_testing;
