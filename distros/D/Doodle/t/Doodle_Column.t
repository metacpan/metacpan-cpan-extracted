use 5.014;

use Do;
use Test::Auto;
use Test::More;

=name

Doodle::Column

=cut

=abstract

Doodle Column Class

=cut

=includes

method: create
method: delete
method: doodle
method: rename
method: update

=cut

=synopsis

  use Doodle;
  use Doodle::Column;
  use Doodle::Table;

  my $ddl = Doodle->new;

  my $table = Doodle::Table->new(
    name => 'users',
    doodle => $ddl
  );

  my $self = Doodle::Column->new(
    name => 'id',
    table => $table,
    doodle => $ddl
  );

=cut

=attributes

name: ro, req, Str
table: ro, req, Table
type: ro, opt, Str
data: ro, opt, Data

=cut

=integrates

Doodle::Column::Helpers

=cut

=description

This package provides table column representation.

=cut

=libraries

Doodle::Library

=cut

=method create

Registers a column create and returns the Command object.

=cut

=signature create

create(Any %args) : Command

=cut

=example-1 create

  # given: synopsis

  my $create = $self->create;

=cut

=method delete

Registers a column delete and returns the Command object.

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

=method rename

Registers a column rename and returns the Command object.

=cut

=signature rename

rename(Any %args) : Command

=cut

=example-1 rename

  # given: synopsis

  my $rename = $self->rename('uuid');

=cut

=method update

Registers a column update and returns the Command object.

=cut

=signature update

update(Any %args) : Command

=cut

=example-1 update

  # given: synopsis

  my $update = $self->update;

=cut

package main;

my $test = Test::Auto->new(__FILE__);

my $subtests = $test->subtests->standard;

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

$subtests->example(-1, 'rename', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'update', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

subtest 't/0.05/can/Doodle_Column_delete.t', fun() {
  use Doodle;
  use Doodle::Column;

  can_ok "Doodle::Column", "delete";

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $c = $t->column('email');
  my $x = $c->delete;

  isa_ok $c, 'Doodle::Column';
  isa_ok $x, 'Doodle::Command';

  is $c->type, 'string';
  is $c, $x->columns->first;
  is $x->name, 'delete_column';

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_doodle.t', fun() {
  use Doodle;
  use Doodle::Column;

  can_ok "Doodle::Column", "doodle";

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $z = $t->column('avatar')->doodle;

  isa_ok $z, 'Doodle';

  is $d, $z;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_rename.t', fun() {
  use Doodle::Column;

  can_ok "Doodle::Column", "rename";

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_create.t', fun() {
  use Doodle;
  use Doodle::Column;

  can_ok "Doodle::Column", "create";

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $c = $t->column('email');
  my $x = $c->create;

  isa_ok $c, 'Doodle::Column';
  isa_ok $x, 'Doodle::Command';

  is $c->type, 'string';
  is $c, $x->columns->first;
  is $x->name, 'create_column';

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_update.t', fun() {
  use Doodle::Column;

  can_ok "Doodle::Column", "update";

  ok 1 and done_testing;
};

ok 1 and done_testing;
