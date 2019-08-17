package Doodle::Grammar;

use 5.014;

use Data::Object 'Class', 'Doodle::Library';

use Carp;
use Doodle::Statement;

our $VERSION = '0.01'; # VERSION

has name => (
  is => 'ro',
  isa => 'Str',
  def => 'unknown'
);

has engine => (
  is => 'ro',
  isa => 'Str'
);

has charset => (
  is => 'ro',
  isa => 'Str'
);

has collation => (
  is => 'ro',
  isa => 'Str'
);

# METHODS

method exception(Str $msg) {
  my $engine = ucfirst $self->name;

  confess sprintf "[%s] %s", $engine, ucfirst $msg;
}

method execute(Command $cmd) {
  my $sub = $cmd->name;
  my $sql = $self->$sub($cmd);

  my $statement = Doodle::Statement->new(cmd => $cmd, sql => $sql);

  return $statement;
}

method create_schema(Command $cmd) {
  # this class is meant to be subclassed

  return $self->exception("does not support the create_schema behaviour");
}

method delete_schema(Command $cmd) {
  # this class is meant to be subclassed

  return $self->exception("does not support the delete_schema behaviour");
}

method create_table(Command $cmd) {
  # this class is meant to be subclassed

  return $self->exception("does not support the create_table behaviour");
}

method delete_table(Command $cmd) {
  # this class is meant to be subclassed

  return $self->exception("does not support the delete_table behaviour");
}

method rename_table(Command $cmd) {
  # this class is meant to be subclassed

  return $self->exception("does not support the rename_table behaviour");
}

method create_column(Command $cmd) {
  # this class is meant to be subclassed

  return $self->exception("does not support the create_column behaviour");
}

method update_column(Command $cmd) {
  # this class is meant to be subclassed

  return $self->exception("does not support the update_column behaviour");
}

method delete_column(Command $cmd) {
  # this class is meant to be subclassed

  return $self->exception("does not support the delete_column behaviour");
}

method rename_column(Command $cmd) {
  # this class is meant to be subclassed

  return $self->exception("does not support the rename_column behaviour");
}

method create_index(Command $cmd) {
  # this class is meant to be subclassed

  return $self->exception("does not support the create_index behaviour");
}

method delete_index(Command $cmd) {
  # this class is meant to be subclassed

  return $self->exception("does not support the delete_index behaviour");
}

method create_constraint(Command $cmd) {
  # this class is meant to be subclassed

  return $self->exception("does not support the create_constraint behaviour");
}

method delete_constraint(Command $cmd) {
  # this class is meant to be subclassed

  return $self->exception("does not support the delete_constraint behaviour");
}

method render(Str $str, Command $cmd) {
  my $output = $str;

  # compress multiline statements
  $output =~ s/\n+\s*/ /gm;

  # process template/data
  my @tokens = $output =~ /\{\W*(\w+)\W*\}/g;

  for my $token (@tokens) {
    my $render = "render_$token";
    next if !$self->can($render);

    my $value = $self->$render($cmd);
    next if !$value;

    $output =~ s/\{(\W*)$token(\W*)\}/$1$value$2/g;
  }

  # clean up remaining tokens
  $output =~ s/\s*\{[^\}]+\}//g;

  # return the compiled sql statement
  return $output;
}

method render_temporary(Command $cmd) {
  # render table "temporary" clause

  return $cmd->table->data->{temporary} ? 'temporary' : undef;
}

method render_if_exists(Command $cmd) {
  # render table "if exists" clause

  return $cmd->table->data->{if_exists} ? 'if exists' : undef;
}

method render_table(Command $cmd) {
  # render table expression

  return $self->wrap($cmd->table->name);
}

method render_new_table(Command $cmd) {
  # render table expression

  return $self->wrap($cmd->table->data->{to});
}

method render_new_column(Command $cmd) {
  # render alter table add column expression

  return $self->render_column($cmd->columns->first);
}

method render_new_column_name(Command $cmd) {
  # render alter table rename column to expression

  return $self->wrap($cmd->columns->first->data->{to});
}

method render_column_name(Command $cmd) {
  # render alter table alter column name

  return $self->wrap($cmd->columns->first->name);
}

method render_column_change(Command $cmd) {
  # render alter table alter column changes

  my $col = $cmd->columns->first;

  return join ' ', 'set', $col->data->{set} if $col->data->{set};
  return join ' ', 'drop', $col->data->{drop} if $col->data->{drop};
  return join ' ', 'type', $col->type;
}

method render_columns(Command $cmd) {
  # render create table column expressions

  return join ', ', map $self->render_column($_), $cmd->table->columns->list;
}

method render_constraints(Command $cmd) {
  # render create table constraints

  return join ', ', map $self->render_constraint($_), $cmd->table->relations->list;
}

method render_type(Column $col) {
  # render column data type expression

  my $name = $col->type;
  my $type = "type_$name";

  $self->exception("can not handle a $name column") if !$self->can($type);

  return $self->$type($col);
}

method render_column(Column $col) {
  # render column spec expression

  my @renders = (
    'render_type',
    'render_nullable',
    'render_increments',
    'render_primary'
  );

  return join ' ', $self->wrap($col->name), map $self->$_($col), @renders;
}

method render_constraint(Relation $rel) {
  # render create table constraint expression

  my $column = $self->wrap($rel->column);
  my $ftable = $self->wrap($rel->foreign_table);
  my $fcolumn = $self->wrap($rel->foreign_column);

  return "foreign key ($column) references $ftable($fcolumn)";
}

method render_nullable(Column $col) {
  # render column null/not-null expression

  my $data = $col->data;

  return () if !exists $data->{nullable};

  return $data->{nullable} ? 'null' : 'not null';
}

method render_increments(Column $col) {
  # render column auto-increment expression

  my $data = $col->data;

  return $data->{increments} ? 'auto_increment' : ();
}

method render_primary(Column $col) {
  # render column primary key expression

  my $data = $col->data;

  return $data->{primary} ? 'primary key' : ();
}

method render_index_name(Command $cmd) {
  # render table create index expression

  return $self->wrap($cmd->indices->first->name);
}

method render_index_columns(Command $cmd) {
  # render table create index columns expression

  return join ', ', map $self->wrap($_), @{$cmd->indices->first->columns};
}

method render_relation(Command $cmd) {
  # render table create foreign constraint expression

  my $relation = $cmd->relation;

  my $name = $relation->name;
  my $column = $relation->column;
  my $ftable = $relation->foreign_table;
  my $fcolumn = $relation->foreign_column;

  my @args = ($name, $column, $ftable, $fcolumn);

  return sprintf '%s foreign key (%s) references %s (%s)', @args;
}

method render_relation_name(Command $cmd) {
  # render table create foreign key name

  return $self->wrap($cmd->relation->name);
}

1;

=encoding utf8

=head1 NAME

Doodle::Grammar

=cut

=head1 ABSTRACT

Doodle Grammar Base Class

=cut

=head1 SYNOPSIS

  use Doodle::Grammar;

  my $self = Doodle::Grammar->new(%args);

=cut

=head1 DESCRIPTION

Doodle::Grammar determines how Command classes should be interpreted to produce the correct DDL
statements.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 create_column

  create_column(Command $command) : Str

Generate SQL statement for column-create Command.

=over 4

=item create_column example

  my $create_column = $self->create_column;

=back

=cut

=head2 create_constraint

  create_constraint(Column $column) : Str

Returns the SQL statement for the create constraint command.

=over 4

=item create_constraint example

  $self->create_constraint($column);

  # 

=back

=cut

=head2 create_index

  create_index(Command $command) : Str

Generate SQL statement for index-create Command.

=over 4

=item create_index example

  my $create_index = $self->create_index;

=back

=cut

=head2 create_schema

  create_schema(Command $command) : Str

Generate SQL statement for schema-create Command.

=over 4

=item create_schema example

  my $create_schema = $self->create_schema;

=back

=cut

=head2 create_table

  create_table(Command $command) : Str

Generate SQL statement for table-create Command.

=over 4

=item create_table example

  my $create_table = $self->create_table;

=back

=cut

=head2 delete_column

  delete_column(Command $command) : Str

Generate SQL statement for column-delete Command.

=over 4

=item delete_column example

  my $delete_column = $self->delete_column;

=back

=cut

=head2 delete_constraint

  delete_constraint(Column $column) : Str

Returns the SQL statement for the delete constraint command.

=over 4

=item delete_constraint example

  $self->delete_constraint($column);

  # 

=back

=cut

=head2 delete_index

  delete_index(Command $command) : Str

Generate SQL statement for index-delete Command.

=over 4

=item delete_index example

  my $delete_index = $self->delete_index;

=back

=cut

=head2 delete_schema

  delete_schema(Command $command) : Str

Generate SQL statement for schema-delete Command.

=over 4

=item delete_schema example

  my $delete_schema = $self->delete_schema;

=back

=cut

=head2 delete_table

  delete_table(Command $command) : Str

Generate SQL statement for table-delete Command.

=over 4

=item delete_table example

  my $delete_table = $self->delete_table;

=back

=cut

=head2 exception

  exception(Str $message) : ()

Throws an exception using L<Carp> confess.

=over 4

=item exception example

  $self->exception($message);

=back

=cut

=head2 execute

  execute(Command $command) : Statement

Processed the Command and returns a Statement object.

=over 4

=item execute example

  my $statement = $self->execute($command);

=back

=cut

=head2 rename_column

  rename_column(Command $command) : Str

Generate SQL statement for column-rename Command.

=over 4

=item rename_column example

  my $rename_column = $self->rename_column;

=back

=cut

=head2 rename_table

  rename_table(Command $command) : Str

Generate SQL statement for table-rename Command.

=over 4

=item rename_table example

  my $rename_table = $self->rename_table;

=back

=cut

=head2 render

  render(Command $command) : Str

Returns the SQL statement for the given Command.

=over 4

=item render example

  my $sql = $self->render($command);

=back

=cut

=head2 update_column

  update_column(Any @args) : Object

Generate SQL statement for column-update Command.

=over 4

=item update_column example

  my $update_column = $self->update_column;

=back

=cut
