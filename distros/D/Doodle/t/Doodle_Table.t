use 5.014;

use Do;
use Test::Auto;
use Test::More;

=name

Doodle::Table

=cut

=abstract

Doodle Table Class

=cut

=includes

method: column
method: create
method: delete
method: doodle
method: index
method: relation
method: rename

=cut

=synopsis

  use Doodle;
  use Doodle::Table;

  my $ddl = Doodle->new;

  my $self = Doodle::Table->new(
    name => 'users',
    doodle => $ddl
  );

=cut

=attributes

name: ro, req, Str
doodle: ro, req, Doodle
schema: ro, opt, Schema
columns: ro, opt, Columns
indices: ro, opt, Indices
relations: ro, opt, Relations
data: ro, opt, Data
engine: ro, opt, Str
charset: ro, opt, Str
collation: ro, opt, Str

=cut

=integrates

Doodle::Table::Helpers

=cut

=description

This package provides database table representation.

=cut

=libraries

Doodle::Library

=cut

=method column

Returns a new Column object.

=cut

=signature column

column(Str $name, Any @args) : Column

=cut

=example-1 column

  # given: synopsis

  my $column = $self->column('id');

=cut

=method create

Registers a table create and returns the Command object.

=cut

=signature create

create(Any %args) : Command

=cut

=example-1 create

  # given: synopsis

  my $create = $self->create;

=cut

=method delete

Registers a table delete and returns the Command object.

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

doodle() : Doodle

=cut

=example-1 doodle

  # given: synopsis

  my $doodle = $self->doodle;

=cut

=method index

Returns a new Index object.

=cut

=signature index

index(ArrayRef :$columns, Any %args) : Index

=cut

=example-1 index

  # given: synopsis

  my $index = $self->index(columns => ['email', 'password']);

=cut

=method relation

Returns a new Relation object.

=cut

=signature relation

relation(Str $column, Str $ftable, Str $fcolumn, Any %args) : Relation

=cut

=example-1 relation

  # given: synopsis

  my $relation = $self->relation('profile_id', 'profiles', 'id');

=cut

=method rename

Registers a table rename and returns the Command object.

=cut

=signature rename

rename(Any %args) : Command

=cut

=example-1 rename

  # given: synopsis

  my $rename = $self->rename('people');

=cut

package main;

my $test = Test::Auto->new(__FILE__);

my $subtests = $test->subtests->standard;

$subtests->synopsis(fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'column', 'method', fun($tryable) {
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

$subtests->example(-1, 'index', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'relation', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'rename', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

subtest 't/0.05/can/Doodle_Table_rename.t', fun() {
  use Doodle;

  can_ok "Doodle::Table", "rename";

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $x = $t->rename('people');

  isa_ok $x, 'Doodle::Command';

  is $x->name, 'rename_table';
  is $x->table->data->{to}, 'people';

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_create.t', fun() {
  use Doodle;

  can_ok "Doodle::Table", "create";

  my $d = Doodle->new;
  my $t = $d->table('users');

  $t->primary('id');
  $t->string('fname');
  $t->string('lname');
  $t->string('email');
  $t->create;

  my $x = $d->commands;

  is $x->count, 1;

  is $x->get(0)->name, 'create_table';
  is $x->get(0)->table, $t;
  is $x->get(0)->columns->count, 4;
  is $x->get(0)->indices->count, 0;
  is $x->get(0)->relation, undef;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_delete.t', fun() {
  use Doodle;

  can_ok "Doodle::Table", "delete";

  my $d = Doodle->new;
  my $t = $d->table('users');

  $t->delete;

  my $x = $d->commands;

  is $x->count, 1;

  is $x->get(0)->name, 'delete_table';
  is $x->get(0)->table, $t;
  is $x->get(0)->columns, undef;
  is $x->get(0)->indices, undef;
  is $x->get(0)->relation, undef;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_doodle.t', fun() {
  use Doodle;

  can_ok "Doodle::Table", "doodle";

  my $d = Doodle->new;
  my $t = $d->table('users');

  is $t->doodle, $d;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_column.t', fun() {
  use Doodle::Table;

  can_ok "Doodle::Table", "column";

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_relation.t', fun() {
  use Doodle;

  can_ok "Doodle::Table", "relation";

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $r = $t->relation('profile_id', 'profiles', 'id');

  isa_ok $r, 'Doodle::Relation';

  is $r->column, 'profile_id';
  is $r->foreign_table, 'profiles';
  is $r->foreign_column, 'id';

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_index.t', fun() {
  use Doodle;

  can_ok "Doodle::Table", "index";

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $i = $t->index(columns => ['profile_id']);

  isa_ok $i, 'Doodle::Index';

  is_deeply $i->columns, ['profile_id'];

  ok 1 and done_testing;
};

ok 1 and done_testing;
