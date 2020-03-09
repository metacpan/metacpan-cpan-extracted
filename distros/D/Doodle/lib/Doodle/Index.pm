package Doodle::Index;

use 5.014;

use strict;
use warnings;

use registry 'Doodle::Library';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

our $VERSION = '0.08'; # VERSION

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

has columns => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
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
  my $columns = $self->columns;

  push @parts, $table->name;
  push @parts, @{$columns};

  return join '_', 'indx', @parts;
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
  $args{indices} = [$self];

  my $command = $self->doodle->index_create(%args);

  return $command;
}

method delete(Any %args) {
  my $table = $self->table;

  $args{table} = $table;
  $args{schema} = $table->schema if $table->schema;
  $args{indices} = [$self];

  my $command = $self->doodle->index_delete(%args);

  return $command;
}

method unique() {
  $self->data->{unique} = 1;

  return $self;
}

1;

=encoding utf8

=head1 NAME

Doodle::Index

=cut

=head1 ABSTRACT

Doodle Index Class

=cut

=head1 SYNOPSIS

  use Doodle;
  use Doodle::Index;
  use Doodle::Table;

  my $ddl = Doodle->new;

  my $table = Doodle::Table->new(
    name => 'users',
    doodle => $ddl
  );

  my $self = Doodle::Index->new(
    table => $table,
    columns => ['email', 'access_token']
  );

=cut

=head1 DESCRIPTION

This package provides table index representation.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Doodle::Library>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 columns

  columns(ArrayRef[Str])

This attribute is read-only, accepts C<(ArrayRef[Str])> values, and is optional.

=cut

=head2 data

  data(Data)

This attribute is read-only, accepts C<(Data)> values, and is optional.

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

Registers an index create and returns the Command object.

=over 4

=item create example #1

  # given: synopsis

  my $create = $self->create;

=back

=cut

=head2 delete

  delete(Any %args) : Command

Registers an index delete and returns the Command object.

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

=head2 unique

  unique() : Index

Denotes that the index should be created and enforced as unique and returns
itself.

=over 4

=item unique example #1

  # given: synopsis

  my $unique = $self->unique;

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
