use 5.014;

use Do;
use Test::Auto;
use Test::More;

=name

Doodle::Relation

=cut

=abstract

Doodle Relation Class

=cut

=includes

method: create
method: delete
method: doodle

=cut

=synopsis

  use Doodle;
  use Doodle::Relation;
  use Doodle::Table;

  my $ddl = Doodle->new;

  my $table = Doodle::Table->new(
    name => 'users',
    doodle => $ddl
  );

  my $self = Doodle::Relation->new(
    table => $table,
    column => 'person_id',
    foreign_table => 'persons',
    foreign_column => 'id'
  );

=cut

=attributes

name: ro, opt, Str
table: ro, req, Table
column: ro, req, Str
foreign_table: ro, req, Str
foreign_column: ro, req, Str
data: ro, opt, Data

=cut

=integrates

Doodle::Relation::Helpers

=cut

=description

This package provides a representation of a table relation.

=cut

=libraries

Doodle::Library

=cut

=method create

Registers a relation create and returns the Command object.

=cut

=signature create

create(Any %args) : Command

=cut

=example-1 create

  # given: synopsis

  my $create = $self->create;

=cut

=method delete

Registers a relation update and returns the Command object.

=cut

=signature delete

delete(Any %args) : Command

=cut

=example-1 delete

  # given: synopsis

  my $delete = $self->delete;

=cut

=method doodle

Returns the associated Doodle object.

=cut

=signature doodle

doodle(Any %args) : Doodle

=cut

=example-1 doodle

  # given: synopsis

  my $doodle = $self->doodle;

=cut

package main;

my $test = Test::Auto->new(__FILE__);

my $subtests = $test->subtests->standard;

$subtests->synopsis(fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'create', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'delete', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'doodle', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

subtest 't/0.05/can/Doodle_Relation_create.t', fun() {
  my $d = Doodle->new;
  my $t = $d->table('users');
  my $r = $t->relation('profile_id', 'profiles', 'id');
  my $x = $r->create;

  isa_ok $r, 'Doodle::Relation';
  isa_ok $x, 'Doodle::Command';

  is $x->name, 'create_relation';
  is $x->relation->name, 'fkey_users_profile_id_profiles_id';
  is $x->relation->column, 'profile_id';
  is $x->relation->foreign_table, 'profiles';
  is $x->relation->foreign_column, 'id';

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Relation_doodle.t', fun() {
  my $d = Doodle->new;
  my $t = $d->table('users');
  my $r = $t->relation('profile_id', 'profiles', 'id');

  isa_ok $r->doodle, 'Doodle';

  is $r->doodle, $d;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Relation_delete.t', fun() {
  my $d = Doodle->new;
  my $t = $d->table('users');
  my $x = $t->delete;

  isa_ok $x, 'Doodle::Command';

  is $x->name, 'delete_table';

  ok 1 and done_testing;
};

ok 1 and done_testing;
