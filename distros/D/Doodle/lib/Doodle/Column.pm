package Doodle::Column;

use 5.014;

use strict;
use warnings;

use registry 'Doodle::Library';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

with 'Doodle::Column::Helpers';

our $VERSION = '0.08'; # VERSION

has name => (
  is => 'ro',
  isa => 'Str',
  req => 1
);

has table => (
  is => 'ro',
  isa => 'Table',
  req => 1
);

has type => (
  is => 'rw',
  isa => 'Str',
  def => 'string'
);

has data => (
  is => 'ro',
  isa => 'Data',
  new => 1
);

# BUILD

fun new_data($self) {
  return {};
}

method BUILD($args) {
  for my $key (keys %$args) {
    $self->{data}{$key} = $args->{$key} if !$self->can($key);
  }

  return $self;
}

# METHODS

method stash(%args) {
  my $data = $self->data;

  while (my($key, $value) = each(%args)) {
    $data->{$key} = $value;
  }

  return $self;
}

method doodle() {
  my $doodle = $self->table->doodle;

  return $doodle;
}

method create(Any %args) {
  my $table = $self->table;

  $args{table} = $table;
  $args{schema} = $table->schema if $table->schema;
  $args{columns} = [$self];

  my $command = $self->doodle->column_create(%args);

  return $command;
}

method update(Any %args) {
  my $table = $self->table;

  $args{table} = $table;
  $args{schema} = $table->schema if $table->schema;
  $args{columns} = [$self];

  $self->stash(drop => delete $args{drop}) if $args{drop};
  $self->stash(set => delete $args{set}) if $args{set};

  my $command = $self->doodle->column_update(%args);

  return $command;
}

method delete(Any %args) {
  my $table = $self->table;

  $args{table} = $table;
  $args{schema} = $table->schema if $table->schema;
  $args{columns} = [$self];

  my $command = $self->doodle->column_delete(%args);

  return $command;
}

method rename(Str $name, Any %args) {
  my $table = $self->table;

  $args{table} = $table;
  $args{schema} = $table->schema if $table->schema;
  $args{columns} = [$self];

  $self->data->{to} = $name;

  my $command = $self->doodle->column_rename(%args);

  return $command;
}

1;

=encoding utf8

=head1 NAME

Doodle::Column

=cut

=head1 ABSTRACT

Doodle Column Class

=cut

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This package provides table column representation.

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Doodle::Column::Helpers>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Doodle::Library>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 data

  data(Data)

This attribute is read-only, accepts C<(Data)> values, and is optional.

=cut

=head2 name

  name(Str)

This attribute is read-only, accepts C<(Str)> values, and is required.

=cut

=head2 table

  table(Table)

This attribute is read-only, accepts C<(Table)> values, and is required.

=cut

=head2 type

  type(Str)

This attribute is read-only, accepts C<(Str)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 create

  create(Any %args) : Command

Registers a column create and returns the Command object.

=over 4

=item create example #1

  # given: synopsis

  my $create = $self->create;

=back

=cut

=head2 delete

  delete(Any %args) : Command

Registers a column delete and returns the Command object.

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

=head2 rename

  rename(Any %args) : Command

Registers a column rename and returns the Command object.

=over 4

=item rename example #1

  # given: synopsis

  my $rename = $self->rename('uuid');

=back

=cut

=head2 update

  update(Any %args) : Command

Registers a column update and returns the Command object.

=over 4

=item update example #1

  # given: synopsis

  my $update = $self->update;

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
