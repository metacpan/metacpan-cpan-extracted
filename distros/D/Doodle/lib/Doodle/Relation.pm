package Doodle::Relation;

use 5.014;

use Data::Object 'Class', 'Doodle::Library';

with 'Doodle::Relation::Helpers';

our $VERSION = '0.06'; # VERSION

has name => (
  is => 'ro',
  isa => 'Str',
  bld => 'new_name',
  lzy => 1
);

has table => (
  is => 'ro',
  isa => 'Table',
  req => 1
);

has column => (
  is => 'ro',
  isa => 'Str',
  req => 1
);

has foreign_table => (
  is => 'ro',
  isa => 'Str',
  req => 1
);

has foreign_column => (
  is => 'ro',
  isa => 'Str',
  req => 1
);

has data => (
  is => 'ro',
  isa => 'Data',
  bld => 'new_data',
  lzy => 1
);

# BUILD

fun new_data($self) {
  return {};
}

fun new_name($self) {
  my @parts;

  my $table = $self->table;
  my $column = $self->column;
  my $ftable = $self->foreign_table;
  my $fcolumn = $self->foreign_column;

  push @parts, $table->name, $column, $ftable, $fcolumn;

  return join '_', 'fkey', @parts;
}

# METHODS

method doodle() {
  my $doodle = $self->table->doodle;

  return $doodle;
}

method create(Any %args) {
  my $table = $self->table;

  $args{table} = $table;
  $args{schema} = $table->schema if $table->schema;
  $args{relation} = $self;

  my $command = $self->doodle->relation_create(%args);

  return $command;
}

method delete(Any %args) {
  my $table = $self->table;

  $args{table} = $table;
  $args{schema} = $table->schema if $table->schema;
  $args{relation} = $self;

  my $command = $self->doodle->relation_delete(%args);

  return $command;
}

1;

=encoding utf8

=head1 NAME

Doodle::Relation

=cut

=head1 ABSTRACT

Doodle Relation Class

=cut

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This package provides a representation of a table relation.

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Doodle::Relation::Helpers>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Doodle::Library>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 column

  column(Str)

This attribute is read-only, accepts C<(Str)> values, and is required.

=cut

=head2 data

  data(Data)

This attribute is read-only, accepts C<(Data)> values, and is optional.

=cut

=head2 foreign_column

  foreign_column(Str)

This attribute is read-only, accepts C<(Str)> values, and is required.

=cut

=head2 foreign_table

  foreign_table(Str)

This attribute is read-only, accepts C<(Str)> values, and is required.

=cut

=head2 name

  name(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head2 table

  table(Table)

This attribute is read-only, accepts C<(Table)> values, and is required.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 create

  create(Any %args) : Command

Registers a relation create and returns the Command object.

=over 4

=item create example #1

  # given: synopsis

  my $create = $self->create;

=back

=cut

=head2 delete

  delete(Any %args) : Command

Registers a relation update and returns the Command object.

=over 4

=item delete example #1

  # given: synopsis

  my $delete = $self->delete;

=back

=cut

=head2 doodle

  doodle(Any %args) : Doodle

Returns the associated Doodle object.

=over 4

=item doodle example #1

  # given: synopsis

  my $doodle = $self->doodle;

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
