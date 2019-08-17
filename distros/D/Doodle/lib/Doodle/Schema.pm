package Doodle::Schema;

use 5.014;

use Data::Object 'Class', 'Doodle::Library';

use Doodle::Table;

our $VERSION = '0.01'; # VERSION

has charset => (
  is => 'ro',
  isa => 'Str',
);

has collation => (
  is => 'ro',
  isa => 'Str',
);

has doodle => (
  is => 'ro',
  isa => 'Doodle',
  req => 1
);

has engine => (
  is => 'ro',
  isa => 'Str',
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

  my $command = $self->doodle->schema_create(%args);

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

  use Doodle::Schema;

  my $self = Doodle::Schema->new(%args);

=cut

=head1 DESCRIPTION

Database representation.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 create

  create(Any %args) : Command

Registers a schema create and returns the Command object.

=over 4

=item create example

  my $create = $self->create;

=back

=cut

=head2 delete

  delete(Any %args) : Command

Registers a schema delete and returns the Command object.

=over 4

=item delete example

  my $delete = $self->delete;

=back

=cut

=head2 table

  table(Str $name, Any @args) : Table

Returns a new Table object.

=over 4

=item table example

  my $table = $self->table;

=back

=cut
