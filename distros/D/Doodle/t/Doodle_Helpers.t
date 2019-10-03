use 5.014;

use Do;
use Test::Auto;
use Test::More;

=name

Doodle::Helpers

=cut

=abstract

Doodle Command Helpers

=cut

=includes

method: column_create
method: column_delete
method: column_rename
method: column_update
method: index_create
method: index_delete
method: relation_create
method: relation_delete
method: schema_create
method: schema_delete
method: table_create
method: table_delete
method: table_rename

=cut

=synopsis

  use Doodle;

  # consumes Doodle::Helpers

  my $self = Doodle->new;

  my $command = $self->schema_create;

=cut

=description

Helpers for configuring Commands.

=cut

=libraries

Doodle::Library

=cut

=method column_create

Registers a column create and returns the Command object.

=cut

=signature column_create

column_create(Any %args) : Command

=cut

=example-1 column_create

  # given: synopsis

  my %args; # (..., column => $column)

  $command = $self->column_create(%args);

=cut

=method column_delete

Registers a column delete and returns the Command object.

=cut

=signature column_delete

column_delete(Any %args) : Command

=cut

=example-1 column_delete

  # given: synopsis

  my %args; # (..., column => $column)

  $command = $self->column_delete(%args);

=cut

=method column_rename

Registers a column rename and returns the Command object.

=cut

=signature column_rename

column_rename(Any %args) : Command

=cut

=example-1 column_rename

  # given: synopsis

  my %args; # (..., column => $column)

  $command = $self->column_rename(%args);

=cut

=method column_update

Registers a column update and returns the Command object.

=cut

=signature column_update

column_update(Any %args) : Command

=cut

=example-1 column_update

  # given: synopsis

  my %args; # (..., column => $column)

  $command = $self->column_update(%args);

=cut

=method index_create

Registers a index create and returns the Command object.

=cut

=signature index_create

index_create(Any %args) : Command

=cut

=example-1 index_create

  # given: synopsis

  my %args; # (..., index => $index)

  $command = $self->index_create(%args);

=cut

=method index_delete

Register and return an index_delete command.

=cut

=signature index_delete

index_delete(Any %args) : Command

=cut

=example-1 index_delete

  # given: synopsis

  my %args; # (..., index => $index)

  $command = $self->index_delete(%args);

=cut

=method relation_create

Registers a relation create and returns the Command object.

=cut

=signature relation_create

relation_create(Any %args) : Command

=cut

=example-1 relation_create

  # given: synopsis

  my %args; # (..., relation => $relation)

  $command = $self->relation_create(%args);

=cut

=method relation_delete

Registers a relation delete and returns the Command object.

=cut

=signature relation_delete

relation_delete(Any %args) : Command

=cut

=example-1 relation_delete

  # given: synopsis

  my %args; # (..., relation => $relation)

  $command = $self->relation_delete(%args);

=cut

=method schema_create

Registers a schema create and returns the Command object.

=cut

=signature schema_create

schema_create(Any %args) : Command

=cut

=example-1 schema_create

  # given: synopsis

  my %args; # (..., schema => $schema)

  $command = $self->schema_create(%args);

=cut

=method schema_delete

Registers a schema delete and returns the Command object.

=cut

=signature schema_delete

schema_delete(Any %args) : Command

=cut

=example-1 schema_delete

  # given: synopsis

  my %args; # (..., schema => $schema)

  $command = $self->schema_delete(%args);

=cut

=method table_create

Registers a table create and returns the Command object.

=cut

=signature table_create

table_create(Any %args) : Command

=cut

=example-1 table_create

  # given: synopsis

  my %args; # (..., table => $table)

  $command = $self->table_create(%args);

=cut

=method table_delete

Registers a table delete and returns the Command object.

=cut

=signature table_delete

table_delete(Any %args) : Command

=cut

=example-1 table_delete

  # given: synopsis

  my %args; # (..., table => $table)

  $command = $self->table_delete(%args);

=cut

=method table_rename

Registers a table rename and returns the Command object.

=cut

=signature table_rename

table_rename(Any %args) : Command

=cut

=example-1 table_rename

  # given: synopsis

  my %args; # (..., table => $table)

  $command = $self->table_rename(%args);

=cut

package main;

my $test = Test::Auto->new(__FILE__);

my $subtests = $test->subtests->standard;

$subtests->synopsis(fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  ok $result->isa('Doodle::Command'), 'command ok';
  is $result->name, 'create_schema', 'got create_schema cmd';

  $result;
});

$subtests->example(-1, 'column_create', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  is $result->name, 'create_column', 'name ok';

  $result;
});

$subtests->example(-1, 'column_delete', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  is $result->name, 'delete_column', 'name ok';

  $result;
});

$subtests->example(-1, 'column_rename', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  is $result->name, 'rename_column', 'name ok';

  $result;
});

$subtests->example(-1, 'column_update', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  is $result->name, 'update_column', 'name ok';

  $result;
});

$subtests->example(-1, 'index_create', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  is $result->name, 'create_index', 'name ok';

  $result;
});

$subtests->example(-1, 'index_delete', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  is $result->name, 'delete_index', 'name ok';

  $result;
});

$subtests->example(-1, 'relation_create', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  is $result->name, 'create_relation', 'name ok';

  $result;
});

$subtests->example(-1, 'relation_delete', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  is $result->name, 'delete_relation', 'name ok';

  $result;
});

$subtests->example(-1, 'schema_create', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  is $result->name, 'create_schema', 'name ok';

  $result;
});

$subtests->example(-1, 'schema_delete', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  is $result->name, 'delete_schema', 'name ok';

  $result;
});

$subtests->example(-1, 'table_create', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  is $result->name, 'create_table', 'name ok';

  $result;
});

$subtests->example(-1, 'table_delete', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  is $result->name, 'delete_table', 'name ok';

  $result;
});

$subtests->example(-1, 'table_rename', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  is $result->name, 'rename_table', 'name ok';

  $result;
});

ok 1 and done_testing;
