package Doodle;

use 5.014;

use Data::Object 'Class', 'Doodle::Library';

with 'Doodle::Helpers';

use Data::Object::Space;

use Doodle::Command;
use Doodle::Schema;
use Doodle::Table;

our $VERSION = '0.04'; # VERSION

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
abstraction for performing schema changes in various datastores. This class
consumes the L<Doodle::Helpers> roles.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 build

  build(Grammar $grammar, CodeRef $callback) : ()

Execute a given callback for each generated SQL statement.

=over 4

=item build example

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

=item grammar example

  my $grammar = $self->grammar('sqlite');

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
