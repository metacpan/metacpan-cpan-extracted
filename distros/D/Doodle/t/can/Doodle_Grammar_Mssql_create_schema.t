use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

create_schema

=usage

  use Doodle;

  my $d = Doodle->new;
  my $s = $d->schema('app');

  my $command = $s->create;

  $self->create_schema($command);

  # create database [app]

=description

Returns the SQL statement for the create schema command.

=signature

create_schema(Command $command) : Str

=type

method

=cut

# TESTING

use Doodle;
use Doodle::Grammar::Mssql;

use_ok 'Doodle::Grammar::Mssql', 'create_schema';

my $d = Doodle->new;
my $g = Doodle::Grammar::Mssql->new;
my $s = $d->schema('app');

my $command = $s->create;

my $sql = $g->create_schema($command);

isa_ok $g, 'Doodle::Grammar::Mssql';
isa_ok $command, 'Doodle::Command';

is $sql, qq{create database [app]};

ok 1 and done_testing;

