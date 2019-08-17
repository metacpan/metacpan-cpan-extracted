use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

create_table

=usage

  use Doodle;

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $c = $t->column('data');

  my $command = $t->create;

  $self->create_table($command);

  # create table [users] ([data] nvarchar(255))

=description

Returns the SQL statement for the create table command.

=signature

create_table(Command $command) : Str

=type

method

=cut

# TESTING

use Doodle;
use Doodle::Grammar::Mssql;

use_ok 'Doodle::Grammar::Mssql', 'create_table';

my $d = Doodle->new;
my $g = Doodle::Grammar::Mssql->new;
my $t = $d->table('users');
my $c = $t->column('data');

my $command = $t->create;

my $sql = $g->create_table($command);

isa_ok $g, 'Doodle::Grammar::Mssql';
isa_ok $command, 'Doodle::Command';

is $sql, qq{create table [users] ([data] nvarchar(255))};

ok 1 and done_testing;
