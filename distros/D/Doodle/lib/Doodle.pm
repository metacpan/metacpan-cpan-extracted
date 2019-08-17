package Doodle;

use 5.014;

use Data::Object 'Class', 'Doodle::Library';

use Doodle::Command;
use Doodle::Schema;
use Doodle::Table;

use Data::Object::Space;

our $VERSION = '0.01'; # VERSION

has commands => (
  is => 'ro',
  isa => 'Commands',
  bld => 'new_commands',
  lzy => 1
);

# BUILD

fun new_commands($self) {
  return do('array', []);
}

# METHODS

method table(Str $name, Any %args) {
  $args{doodle} = $self;

  my $table = Doodle::Table->new(%args, name => $name);

  return $table;
}

method schema(Str $name, Any %args) {
  $args{doodle} = $self;

  my $schema = Doodle::Schema->new(%args, name => $name);

  return $schema;
}

method schema_create(Any %args) {
  $args{doodle} = $self;

  my $command = Doodle::Command->new(%args, name => 'create_schema');

  $self->commands->push($command);

  return $command;
}

method schema_delete(Any %args) {
  $args{doodle} = $self;

  my $command = Doodle::Command->new(%args, name => 'delete_schema');

  $self->commands->push($command);

  return $command;
}

method table_create(Any %args) {
  $args{doodle} = $self;

  my $command = Doodle::Command->new(%args, name => 'create_table');

  $self->commands->push($command);

  return $command;
}

method table_delete(Any %args) {
  $args{doodle} = $self;

  my $command = Doodle::Command->new(%args, name => 'delete_table');

  $self->commands->push($command);

  return $command;
}

method table_rename(Any %args) {
  $args{doodle} = $self;

  my $command = Doodle::Command->new(%args, name => 'rename_table');

  $self->commands->push($command);

  return $command;
}

method column_create(Any %args) {
  $args{doodle} = $self;

  my $command = Doodle::Command->new(%args, name => 'create_column');

  $self->commands->push($command);

  return $command;
}

method column_update(Any %args) {
  $args{doodle} = $self;

  my $command = Doodle::Command->new(%args, name => 'update_column');

  $self->commands->push($command);

  return $command;
}

method column_rename(Any %args) {
  $args{doodle} = $self;

  my $command = Doodle::Command->new(%args, name => 'rename_column');

  $self->commands->push($command);

  return $command;
}

method column_delete(Any %args) {
  $args{doodle} = $self;

  my $command = Doodle::Command->new(%args, name => 'delete_column');

  $self->commands->push($command);

  return $command;
}

method index_create(Any %args) {
  $args{doodle} = $self;

  my $command = Doodle::Command->new(%args, name => 'create_index');

  $self->commands->push($command);

  return $command;
}

method index_delete(Any %args) {
  $args{doodle} = $self;

  my $command = Doodle::Command->new(%args, name => 'delete_index');

  $self->commands->push($command);

  return $command;
}

method relation_create(Any %args) {
  $args{doodle} = $self;

  my $command = Doodle::Command->new(%args, name => 'create_relation');

  $self->commands->push($command);

  return $command;
}

method relation_delete(Any %args) {
  $args{doodle} = $self;

  my $command = Doodle::Command->new(%args, name => 'delete_relation');

  $self->commands->push($command);

  return $command;
}

method statements(Grammar $grammar) {
  my $statements = do('array', []);

  for my $command ($self->commands->list) {
    $statements->push($grammar->execute($command));
  }

  return $statements;
}

method build(Grammar $grammar, CodeRef $callback) {
  my $statements = $self->statements($grammar);

  for my $statement ($statements->list) {
    $callback->($statement);
  }

  return;
}

method grammar(Str $type) {
  my $class = join '::', __PACKAGE__, 'Grammar', ucfirst $type;

  my $space = Data::Object::Space->new($class);

  my $grammar = $space->build;

  return $grammar;
}

1;

=encoding utf8

=head1 NAME

Doodle

=cut

=head1 ABSTRACT

Database DDL Statement Builder

=cut

=head1 SYNOPSIS

  use Doodle;

  my $d = Doodle->new;
  my $t = $d->table('users');

  $t->primary('id');
  $t->uuid('arid');
  $t->column('name');
  $t->string('email');
  $t->json('metadata');

  my $x = $t->create;
  my $g = $d->grammar('sqlite');
  my $s = $g->execute($x);

  say $s->sql;

  # create table "users" (
  #   "id" integer primary key,
  #   "arid" varchar,
  #   "name" varchar,
  #   "email" varchar,
  #   "metadata" text
  # )

=cut

=head1 DESCRIPTION

Doodle is a database DDL statement builder and provides an object-oriented
abstraction for performing schema changes in various datastores.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 build

  build(Grammar $g, CodeRef $callback) : ()

Execute a given callback for each generated SQL statement.

=over 4

=item build example

  $self->build($grammar, sub {
    my $statement = shift;

    # e.g. $db->do($statement->sql);
  });

=back

=cut

=head2 column_create

  column_create(Any %args) : Command

Registers a column create and returns the Command object.

=over 4

=item column_create example

  my $command = $self->column_create(%args);

=back

=cut

=head2 column_delete

  column_delete(Any %args) : Command

Registers a column delete and returns the Command object.

=over 4

=item column_delete example

  my $command = $self->column_delete(%args);

=back

=cut

=head2 column_rename

  column_rename(Any %args) : Command

Registers a column rename and returns the Command object.

=over 4

=item column_rename example

  my $command = $self->column_rename(%args);

=back

=cut

=head2 column_update

  column_update(Any %args) : Command

Registers a column update and returns the Command object.

=over 4

=item column_update example

  my $command = $self->column_update(%args);

=back

=cut

=head2 grammar

  grammar(Str $name) : Grammar

Returns a new Grammar object.

=over 4

=item grammar example

  my $grammar = $self->grammar('sqlite');

=back

=cut

=head2 index_create

  index_create(Any %args) : Command

Registers a index create and returns the Command object.

=over 4

=item index_create example

  my $command = $self->index_create(%args);

=back

=cut

=head2 index_delete

  index_delete(Any %args) : Command

Register and return an index_delete command.

=over 4

=item index_delete example

  my $command = $self->index_delete(%args);

=back

=cut

=head2 relation_create

  relation_create(Any %args) : Command

Registers a relation create and returns the Command object.

=over 4

=item relation_create example

  my $command = $self->relation_create(%args);

=back

=cut

=head2 relation_delete

  relation_delete(Any %args) : Command

Registers a relation delete and returns the Command object.

=over 4

=item relation_delete example

  my $command = $self->relation_delete(%args);

=back

=cut

=head2 schema

  schema(Str $name, Any %args) : Schema

Returns a new Schema object.

=over 4

=item schema example

  my $schema = $self->schema($name);

=back

=cut

=head2 schema_create

  schema_create(Any %args) : Command

Registers a schema create and returns the Command object.

=over 4

=item schema_create example

  my $command = $self->schema_create(%args);

=back

=cut

=head2 schema_delete

  schema_delete(Any %args) : Command

Registers a schema delete and returns the Command object.

=over 4

=item schema_delete example

  my $command = $self->schema_delete(%args);

=back

=cut

=head2 statements

  statements(Grammar $g) : [Statement]

Returns a set of Statement objects for the given grammar.

=over 4

=item statements example

  my $statements = $self->statements($grammar);

=back

=cut

=head2 table

  table(Str $name, Any %args) : Table

Return a new Table object.

=over 4

=item table example

  my $table = $self->table('users');

=back

=cut

=head2 table_create

  table_create(Any %args) : Command

Registers a table create and returns the Command object.

=over 4

=item table_create example

  my $command = $self->table_create(%args);

=back

=cut

=head2 table_delete

  table_delete(Any %args) : Command

Registers a table delete and returns the Command object.

=over 4

=item table_delete example

  my $command = $self->table_delete(%args);

=back

=cut

=head2 table_rename

  table_rename(Any %args) : Command

Registers a table rename and returns the Command object.

=over 4

=item table_rename example

  my $command = $self->table_rename(%args);

=back

=cut
