package Doodle::Relation;

use 5.014;

use Data::Object 'Class', 'Doodle::Library';

our $VERSION = '0.01'; # VERSION

has name => (
  is => 'ro',
  isa => 'Any',
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
  return do('hash', {});
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

  use Doodle::Relation;

  my $self = Doodle::Relation->new(%args);

=cut

=head1 DESCRIPTION

Table relation representation.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 create

  create(Any %args) : Command

Registers a relation create and returns the Command object.

=over 4

=item create example

  my $create = $self->create;

=back

=cut

=head2 delete

  delete(Any %args) : Command

Registers a relation update and returns the Command object.

=over 4

=item delete example

  my $delete = $self->delete;

=back

=cut

=head2 doodle

  doodle(Any %args) : Doodle

Returns the associated Doodle object.

=over 4

=item doodle example

  my $doodle = $self->doodle;

=back

=cut
