package Doodle::Schema;

use 5.014;

use Data::Object 'Class', 'Doodle::Library';

with 'Doodle::Schema::Helpers';

use Doodle::Table;

our $VERSION = '0.06'; # VERSION

has doodle => (
  is => 'ro',
  isa => 'Doodle',
  req => 1
);

has name => (
  is => 'ro',
  isa => 'Str',
  req => 1
);

has temporary => (
  is => 'ro',
  isa => 'Bool',
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

# METHODS

method table(Str $name, Any %args) {
  $args{doodle} = $self->doodle;

  my $table = Doodle::Table->new(%args, name => $name);

  return $table;
}

method create(Any %args) {
  $args{schema} = $self;

  my $command = $self->doodle->schema_create(%args);

  return $command;
}

method delete(Any %args) {
  $args{schema} = $self;

  my $command = $self->doodle->schema_delete(%args);

  return $command;
}

1;

=encoding utf8

=head1 NAME

Doodle::Schema

=cut

=head1 ABSTRACT

Doodle Schema Class

=cut

=head1 SYNOPSIS

  use Doodle;
  use Doodle::Schema;

  my $ddl = Doodle->new;

  my $self = Doodle::Schema->new(
    name => 'app',
    doodle => $ddl
  );

=cut

=head1 DESCRIPTION

This package provides a representation of a database.

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Doodle::Schema::Helpers>

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

=head2 doodle

  doodle(Doodle)

This attribute is read-only, accepts C<(Doodle)> values, and is required.

=cut

=head2 name

  name(Str)

This attribute is read-only, accepts C<(Str)> values, and is required.

=cut

=head2 temporary

  temporary(Bool)

This attribute is read-only, accepts C<(Bool)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 create

  create(Any %args) : Command

Registers a schema create and returns the Command object.

=over 4

=item create example #1

  # given: synopsis

  my $create = $self->create;

=back

=cut

=head2 delete

  delete(Any %args) : Command

Registers a schema delete and returns the Command object.

=over 4

=item delete example #1

  # given: synopsis

  my $delete = $self->delete;

=back

=cut

=head2 table

  table(Str $name, Any @args) : Table

Returns a new Table object.

=over 4

=item table example #1

  # given: synopsis

  my $table = $self->table('users');

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
