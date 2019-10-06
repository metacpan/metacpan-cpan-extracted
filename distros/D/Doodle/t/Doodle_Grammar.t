use 5.014;

use Do;
use Test::Auto;
use Test::More;

=name

Doodle::Grammar

=cut

=abstract

Doodle Grammar Base Class

=cut

=includes

method: create_column
method: create_constraint
method: create_index
method: create_schema
method: create_table
method: delete_column
method: delete_constraint
method: delete_index
method: delete_schema
method: delete_table
method: exception
method: execute
method: rename_column
method: rename_table
method: render
method: update_column

=cut

=synopsis

  use Doodle::Grammar;

  my $self = Doodle::Grammar->new;

=cut

=attributes

name: ro, opt, Str

=cut

=description

This package determines how command objects should be interpreted to produce
the correct DDL statements.

=cut

=libraries

Doodle::Library

=cut

=method create_column

Generate SQL statement for column-create Command.

=cut

=signature create_column

create_column(Command $command) : Str

=cut

=example-1 create_column

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('id');
  my $command = $column->create;

  my $create_column = $self->create_column($command);

=cut

=method create_constraint

Returns the SQL statement for the create constraint command.

=cut

=signature create_constraint

create_constraint(Column $column) : Str

=cut

=example-1 create_constraint

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $relation = $ddl->table('emails')->relation('user_id', 'users', 'id');
  my $command = $relation->create;

  $self->create_constraint($command);

=cut

=method create_index

Generate SQL statement for index-create Command.

=cut

=signature create_index

create_index(Command $command) : Str

=cut

=example-1 create_index

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $index = $ddl->table('users')->index(columns => ['is_admin']);
  my $command = $index->create;

  my $create_index = $self->create_index($command);

=cut

=method create_schema

Generate SQL statement for schema-create Command.

=cut

=signature create_schema

create_schema(Command $command) : Str

=cut

=example-1 create_schema

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $schema = $ddl->schema('app');
  my $command = $schema->create;

  my $create_schema = $self->create_schema($command);

=cut

=method create_table

Generate SQL statement for table-create Command.

=cut

=signature create_table

create_table(Command $command) : Str

=cut

=example-1 create_table

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $table = $ddl->table('users');
  my $command = $table->create;

  my $create_table = $self->create_table($command);

=cut

=method delete_column

Generate SQL statement for column-delete Command.

=cut

=signature delete_column

delete_column(Command $command) : Str

=cut

=example-1 delete_column

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('id');
  my $command = $column->delete;

  my $delete_column = $self->delete_column($command);

=cut

=method delete_constraint

Returns the SQL statement for the delete constraint command.

=cut

=signature delete_constraint

delete_constraint(Column $column) : Str

=cut

=example-1 delete_constraint

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $relation = $ddl->table('emails')->relation('user_id', 'users', 'id');
  my $command = $relation->delete;

  $self->delete_constraint($command);

=cut

=method delete_index

Generate SQL statement for index-delete Command.

=cut

=signature delete_index

delete_index(Command $command) : Str

=cut

=example-1 delete_index

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $index = $ddl->table('users')->index(columns => ['is_admin']);
  my $command = $index->delete;

  my $delete_index = $self->delete_index($command);

=cut

=method delete_schema

Generate SQL statement for schema-delete Command.

=cut

=signature delete_schema

delete_schema(Command $command) : Str

=cut

=example-1 delete_schema

  # given: synopsis

  my $ddl = Doodle->new;
  my $schema = $ddl->schema('app');
  my $command = $schema->delete;

  my $delete_schema = $self->delete_schema($command);

=cut

=method delete_table

Generate SQL statement for table-delete Command.

=cut

=signature delete_table

delete_table(Command $command) : Str

=cut

=example-1 delete_table

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $table = $ddl->table('users');
  my $command = $table->delete;

  my $delete_table = $self->delete_table($command);

=cut

=method exception

Throws an exception using L<Carp> confess.

=cut

=signature exception

exception(Str $message) : Any

=cut

=example-1 exception

  # given: synopsis

  $self->exception('Oops');

=cut

=method execute

Processed the Command and returns a Statement object.

=cut

=signature execute

execute(Command $command) : Statement

=cut

=example-1 execute

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('id');
  my $command = $column->create;

  my $statement = $self->execute($command);

=cut

=method rename_column

Generate SQL statement for column-rename Command.

=cut

=signature rename_column

rename_column(Command $command) : Str

=cut

=example-1 rename_column

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('id');
  my $command = $column->rename('uuid');

  my $rename_column = $self->rename_column($command);

=cut

=method rename_table

Generate SQL statement for table-rename Command.

=cut

=signature rename_table

rename_table(Command $command) : Str

=cut

=example-1 rename_table

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $table = $ddl->table('users');
  my $command = $table->rename('people');

  my $rename_table = $self->rename_table($command);

=cut

=method render

Returns the SQL statement for the given Command.

=cut

=signature render

render(Command $command) : Str

=cut

=example-1 render

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $schema = $ddl->schema('app');
  my $command = $schema->create;
  my $template = 'create schema {schema_name}';

  my $sql = $self->render($template, $command);

=cut

=method update_column

Generate SQL statement for column-update Command.

=cut

=signature update_column

update_column(Any @args) : Str

=cut

=example-1 update_column

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('id')->integer_small;
  my $command = $column->update;

  my $update_column = $self->update_column($command);

=cut

package main;

my $test = Test::Auto->new(__FILE__);

my $subtests = $test->subtests->standard;

$subtests->example(-1, 'create_column', 'method', fun($tryable) {
  $tryable->default(fun($exception) {
    return $exception;
  });
  ok my $result = $tryable->result, 'result ok';
  like $result, qr/not support the create_column behaviour/,
    'create_column not supported';

  "$result";
});

$subtests->example(-1, 'create_constraint', 'method', fun($tryable) {
  $tryable->default(fun($exception) {
    return $exception;
  });
  ok my $result = $tryable->result, 'result ok';
  like $result, qr/not support the create_constraint behaviour/,
    'create_constraint not supported';

  "$result";
});

$subtests->example(-1, 'create_index', 'method', fun($tryable) {
  $tryable->default(fun($exception) {
    return $exception;
  });
  ok my $result = $tryable->result, 'result ok';
  like $result, qr/not support the create_index behaviour/,
    'create_index not supported';

  "$result";
});

$subtests->example(-1, 'create_schema', 'method', fun($tryable) {
  $tryable->default(fun($exception) {
    return $exception;
  });
  ok my $result = $tryable->result, 'result ok';
  like $result, qr/not support the create_schema behaviour/,
    'create_schema not supported';

  "$result";
});

$subtests->example(-1, 'create_table', 'method', fun($tryable) {
  $tryable->default(fun($exception) {
    return $exception;
  });
  ok my $result = $tryable->result, 'result ok';
  like $result, qr/not support the create_table behaviour/,
    'create_table not supported';

  "$result";
});

$subtests->example(-1, 'delete_column', 'method', fun($tryable) {
  $tryable->default(fun($exception) {
    return $exception;
  });
  ok my $result = $tryable->result, 'result ok';
  like $result, qr/not support the delete_column behaviour/,
    'delete_column not supported';

  "$result";
});

$subtests->example(-1, 'delete_constraint', 'method', fun($tryable) {
  $tryable->default(fun($exception) {
    return $exception;
  });
  ok my $result = $tryable->result, 'result ok';
  like $result, qr/not support the delete_constraint behaviour/,
    'delete_constraint not supported';

  "$result";
});

$subtests->example(-1, 'delete_index', 'method', fun($tryable) {
  $tryable->default(fun($exception) {
    return $exception;
  });
  ok my $result = $tryable->result, 'result ok';
  like $result, qr/not support the delete_index behaviour/,
    'delete_index not supported';

  "$result";
});

$subtests->example(-1, 'delete_schema', 'method', fun($tryable) {
  $tryable->default(fun($exception) {
    return $exception;
  });
  ok my $result = $tryable->result, 'result ok';
  like $result, qr/not support the delete_schema behaviour/,
    'delete_schema not supported';

  "$result";
});

$subtests->example(-1, 'delete_table', 'method', fun($tryable) {
  $tryable->default(fun($exception) {
    return $exception;
  });
  ok my $result = $tryable->result, 'result ok';
  like $result, qr/not support the delete_table behaviour/,
    'delete_table not supported';

  "$result";
});

$subtests->example(-1, 'exception', 'method', fun($tryable) {
  $tryable->default(fun($exception) {
    return $exception;
  });
  ok my $result = $tryable->result, 'result ok';
  like $result, qr/Oops/, 'exception thrown';

  "$result";
});

$subtests->example(-1, 'execute', 'method', fun($tryable) {
  $tryable->default(fun($exception) {
    return $exception;
  });
  ok my $result = $tryable->result, 'result ok';
  like $result, qr/not support the create_column behaviour/,
    'execute throw exception';

  # force return a statement

  require Doodle;
  require Doodle::Command;
  require Doodle::Statement;

  Doodle::Statement->new(
    sql => '...',
    cmd => Doodle::Command->new(
      name => 'create_schema',
      doodle => Doodle->new
    )
  );
});

$subtests->example(-1, 'rename_column', 'method', fun($tryable) {
  $tryable->default(fun($exception) {
    return $exception;
  });
  ok my $result = $tryable->result, 'result ok';
  like $result, qr/not support the rename_column behaviour/,
    'rename_column not supported';

  "$result";
});

$subtests->example(-1, 'rename_table', 'method', fun($tryable) {
  $tryable->default(fun($exception) {
    return $exception;
  });
  ok my $result = $tryable->result, 'result ok';
  like $result, qr/not support the rename_table behaviour/,
    'rename_table not supported';

  "$result";
});

$subtests->example(-1, 'render', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  like $result, qr/create schema app/, 'rendered ok';

  "$result";
});

$subtests->example(-1, 'update_column', 'method', fun($tryable) {
  $tryable->default(fun($exception) {
    return $exception;
  });
  ok my $result = $tryable->result, 'result ok';
  like $result, qr/not support the update_column behaviour/,
    'update_column not supported';

  "$result";
});

ok 1 and done_testing;
