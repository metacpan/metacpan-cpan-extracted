package Doodle::Table;

use 5.014;

use Data::Object 'Class', 'Doodle::Library';

with 'Doodle::Table::Helpers';

use Doodle::Column;
use Doodle::Index;
use Doodle::Relation;

our $VERSION = '0.06'; # VERSION

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
  new => 1
);

has indices => (
  is => 'ro',
  isa => 'Indices',
  new => 1
);

has relations => (
  is => 'ro',
  isa => 'Relations',
  new => 1
);

has data => (
  is => 'ro',
  isa => 'Data',
  new => 1
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
  return {};
}

fun new_columns($self) {
  return [];
}

fun new_indices($self) {
  return [];
}

fun new_relations($self) {
  return [];
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

  use Doodle;
  use Doodle::Table;

  my $ddl = Doodle->new;

  my $self = Doodle::Table->new(
    name => 'users',
    doodle => $ddl
  );

=cut

=head1 DESCRIPTION

This package provides database table representation.

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Doodle::Table::Helpers>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Doodle::Library>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 charset

  charset(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 collation

  collation(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 columns

  columns(Columns)

This attribute is read-only, accepts C<(Columns)> values, and is optional.

=cut

=head2 data

  data(Data)

This attribute is read-only, accepts C<(Data)> values, and is optional.

=cut

=head2 doodle

  doodle(Doodle)

This attribute is read-only, accepts C<(Doodle)> values, and is required.

=cut

=head2 engine

  engine(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 indices

  indices(Indices)

This attribute is read-only, accepts C<(Indices)> values, and is optional.

=cut

=head2 name

  name(Str)

This attribute is read-only, accepts C<(Str)> values, and is required.

=cut

=head2 relations

  relations(Relations)

This attribute is read-only, accepts C<(Relations)> values, and is optional.

=cut

=head2 schema

  schema(Schema)

This attribute is read-only, accepts C<(Schema)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 column

  column(Str $name, Any @args) : Column

Returns a new Column object.

=over 4

=item column example #1

  # given: synopsis

  my $column = $self->column('id');

=back

=cut

=head2 create

  create(Any %args) : Command

Registers a table create and returns the Command object.

=over 4

=item create example #1

  # given: synopsis

  my $create = $self->create;

=back

=cut

=head2 delete

  delete(Any %args) : Command

Registers a table delete and returns the Command object.

=over 4

=item delete example #1

  # given: synopsis

  my $delete = $self->delete;

=back

=cut

=head2 doodle

  doodle() : Doodle

Returns the associated Doodle object.

=over 4

=item doodle example #1

  # given: synopsis

  my $doodle = $self->doodle;

=back

=cut

=head2 index

  index(ArrayRef :$columns, Any %args) : Index

Returns a new Index object.

=over 4

=item index example #1

  # given: synopsis

  my $index = $self->index(columns => ['email', 'password']);

=back

=cut

=head2 relation

  relation(Str $column, Str $ftable, Str $fcolumn, Any %args) : Relation

Returns a new Relation object.

=over 4

=item relation example #1

  # given: synopsis

  my $relation = $self->relation('profile_id', 'profiles', 'id');

=back

=cut

=head2 rename

  rename(Any %args) : Command

Registers a table rename and returns the Command object.

=over 4

=item rename example #1

  # given: synopsis

  my $rename = $self->rename('people');

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/doodle/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/doodle/wiki>

L<Project|https://github.com/iamalnewkirk/doodle>

L<Initiatives|https://github.com/iamalnewkirk/doodle/projects>

L<Milestones|https://github.com/iamalnewkirk/doodle/milestones>

L<Contributing|https://github.com/iamalnewkirk/doodle/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/doodle/issues>

=cut
