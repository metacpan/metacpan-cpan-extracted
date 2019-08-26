package Doodle::Table;

use 5.014;

use Data::Object 'Class', 'Doodle::Library';

with 'Doodle::Table::Helpers';

use Doodle::Column;
use Doodle::Index;
use Doodle::Relation;

our $VERSION = '0.05'; # VERSION

has name => (
  is => 'ro',
  isa => 'Str',
  req => 1
);

has doodle => (
  is => 'ro',
  isa => 'Doodle',
  req => 1
);

has schema => (
  is => 'ro',
  isa => 'Schema',
  opt => 1
);

has columns => (
  is => 'ro',
  isa => 'Columns',
  bld => 'new_columns',
  lzy => 1
);

has indices => (
  is => 'ro',
  isa => 'Indices',
  bld => 'new_indices',
  lzy => 1
);

has relations => (
  is => 'ro',
  isa => 'Relations',
  bld => 'new_relations',
  lzy => 1
);

has data => (
  is => 'ro',
  isa => 'Data',
  bld => 'new_data',
  lzy => 1
);

has engine => (
  is => 'rw',
  isa => 'Str'
);

has charset => (
  is => 'rw',
  isa => 'Str'
);

has collation => (
  is => 'rw',
  isa => 'Str'
);

# BUILD

fun new_data($self) {
  return do('hash', {});
}

fun new_columns($self) {
  return do('array', []);
}

fun new_indices($self) {
  return do('array', []);
}

fun new_relations($self) {
  return do('array', []);
}

# METHODS

method column(Str $name, Any %args) {
  $args{table} = $self;

  my $column = Doodle::Column->new(%args, name => $name);

  $self->columns->push($column);

  return $column;
}

method index(ArrayRef :$columns, Any %args) {
  $args{table} = $self;

  my $index = Doodle::Index->new(%args);

  $self->indices->push($index);

  return $index;
}

method relation(Str $column, Str $ftable, Str $fcolumn = 'id', Any %args) {
  $args{table} = $self;

  $args{column} = $column;
  $args{foreign_table} = $ftable;
  $args{foreign_column} =  $fcolumn;

  my $relation = Doodle::Relation->new(%args);

  $self->relations->push($relation);

  return $relation;
}

method create(Any %args) {
  $args{schema} = $self->schema if $self->schema;

  my $command = $self->doodle->table_create(
    %args,
    table => $self,
    columns => $self->columns,
    indices => $self->indices,
    relations => $self->relations
  );

  return $command;
}

method delete(Any %args) {
  my $schema = $self->schema;

  $args{table} = $self;
  $args{schema} = $schema if $schema;

  my $command = $self->doodle->table_delete(%args);

  return $command;
}

method rename(Str $name, Any %args) {
  my $schema = $self->schema;

  $args{table} = $self;
  $args{schema} = $schema if $schema;

  $self->data->{to} = $name;

  my $command = $self->doodle->table_rename(%args);

  return $command;
}

1;

=encoding utf8

=head1 NAME

Doodle::Table

=cut

=head1 ABSTRACT

Doodle Table Class

=cut

=head1 SYNOPSIS

  use Doodle::Table;

  my $self = Doodle::Table->new(
    name => 'users'
  );

=cut

=head1 DESCRIPTION

Database table representation. This class consumes the
L<Doodle::Table::Helpers> role.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 column

  column(Str $name, Any @args) : Column

Returns a new Column object.

=over 4

=item column example

  my $column = $self->column;

=back

=cut

=head2 create

  create(Any %args) : Command

Registers a table create and returns the Command object.

=over 4

=item create example

  my $create = $self->create;

=back

=cut

=head2 delete

  delete(Any %args) : Command

Registers a table delete and returns the Command object.

=over 4

=item delete example

  my $delete = $self->delete;

=back

=cut

=head2 index

  index(ArrayRef :$columns, Any %args) : Index

Returns a new Index object.

=over 4

=item index example

  my $index = $self->index(columns => ['email', 'password']);

=back

=cut

=head2 relation

  relation(Str $column, Str $ftable, Str $fcolumn, Any %args) : Relation

Returns a new Relation object.

=over 4

=item relation example

  my $relation = $self->relation('profile_id', 'profiles', 'id');

=back

=cut

=head2 rename

  rename(Any %args) : Command

Registers a table rename and returns the Command object.

=over 4

=item rename example

  my $rename = $self->rename;

=back

=cut
