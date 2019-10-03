package Doodle;

use 5.014;

use Data::Object 'Class', 'Doodle::Library';

with 'Doodle::Helpers';

use Data::Object::Space;

use Doodle::Command;
use Doodle::Schema;
use Doodle::Table;

our $VERSION = '0.06'; # VERSION

has commands => (
  is => 'ro',
  isa => 'Commands',
  new => 1
);

# BUILD

fun new_commands($self) {
  return [];
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

method statements(Grammar $grammar) {
  my $statements = [];

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

Database DDL (= Data Definition Language) Statement Builder

=cut

=head1 SYNOPSIS

  use Doodle;

  my $self = Doodle->new;
  my $table = $self->table('users');

  $table->primary('id');
  $table->uuid('arid');
  $table->column('name');
  $table->string('email');
  $table->json('metadata');

  my $command = $table->create;
  my $grammar = $self->grammar('sqlite');
  my $statement = $grammar->execute($command);

  # say $statement->sql;

  # create table "users" (
  #   "id" integer primary key,
  #   "arid" varchar,
  #   "name" varchar,
  #   "email" varchar,
  #   "metadata" text
  # )

=cut

=head1 DESCRIPTION

Doodle is a database
L<DDL ("Data Definition Language" or "Data Description Language")|https://en.wikipedia.org/wiki/Data_definition_language>
statement builder and provides an object-oriented
abstraction for performing schema changes in various datastores.
This class consumes the L<Doodle::Helpers> roles.

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Doodle::Helpers>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Doodle::Library>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 commands

  commands(Commands)

This attribute is read-only, accepts C<(Commands)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 build

  build(Grammar $grammar, CodeRef $callback) : Any

Execute a given callback for each generated SQL statement.

=over 4

=item build example #1

  # given: synopsis

  $self->build($grammar, sub {
    my $statement = shift;

    # e.g. $db->do($statement->sql);
  });

=back

=cut

=head2 grammar

  grammar(Str $name) : Grammar

Returns a new Grammar object.

=over 4

=item grammar example #1

  # given: synopsis

  my $type = 'sqlite';

  $grammar = $self->grammar($type);

=back

=cut

=head2 schema

  schema(Str $name, Any %args) : Schema

Returns a new Schema object.

=over 4

=item schema example #1

  # given: synopsis

  my $name = 'app';

  my $schema = $self->schema($name);

=back

=cut

=head2 statements

  statements(Grammar $g) : Statements

Returns a set of Statement objects for the given grammar.

=over 4

=item statements example #1

  # given: synopsis

  my $statements = $self->statements($grammar);

=back

=cut

=head2 table

  table(Str $name, Any %args) : Table

Return a new Table object.

=over 4

=item table example #1

  # given: synopsis

  my $name = 'users';

  $table = $self->table($name);

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
