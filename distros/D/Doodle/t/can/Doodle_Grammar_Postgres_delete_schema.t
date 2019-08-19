use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

delete_schema

=usage

  use Doodle;

  my $d = Doodle->new;
  my $s = $d->schema('app');

  my $command = $s->create;

  $self->delete_schema($command);

  # drop database "app"

=description

Returns the SQL statement for the create schema command.

=signature

delete_schema(Command $command) : Str

=type

method

=cut

# TESTING

use Doodle;
use Doodle::Grammar::Postgres;

use_ok 'Doodle::Grammar::Postgres', 'delete_schema';

my $d = Doodle->new;
my $g = Doodle::Grammar::Postgres->new;
my $s = $d->schema('app');

my $command = $s->create;

my $sql = $g->delete_schema($command);

isa_ok $g, 'Doodle::Grammar::Postgres';
isa_ok $command, 'Doodle::Command';

is $sql, qq{drop database "app"};

ok 1 and done_testing;

