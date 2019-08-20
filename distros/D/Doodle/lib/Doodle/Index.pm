package Doodle::Index;

use 5.014;

use Data::Object 'Class', 'Doodle::Library';

our $VERSION = '0.04'; # VERSION

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
  return do('hash', {});
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

method doodle() {
  my $doodle = $self->table->doodle;

  return $doodle;
}

method create(Any %args) {
  my $table = $self->table;

  $args{table} = $table;
  $args{schema} = $table->schema if $table->schema;
  $args{indices} = do('array', [$self]);

  my $command = $self->doodle->index_create(%args);

  return $command;
}

method delete(Any %args) {
  my $table = $self->table;

  $args{table} = $table;
  $args{schema} = $table->schema if $table->schema;
  $args{indices} = do('array', [$self]);

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

  use Doodle::Index;

  my $self = Doodle::Index->new(%args);

=cut

=head1 DESCRIPTION

Table index representation.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 create

  create(Any %args) : Command

Registers an index create and returns the Command object.

=over 4

=item create example

  my $create = $self->create;

=back

=cut

=head2 delete

  delete(Any %args) : Command

Registers an index delete and returns the Command object.

=over 4

=item delete example

  my $delete = $self->delete;

=back

=cut

=head2 doodle

  doodle() : Doodle

Returns the associated Doodle object.

=over 4

=item doodle example

  my $doodle = $self->doodle;

=back

=cut

=head2 unique

  unique() : Index

Denotes that the index should be created and enforced as unique and returns
itself.

=over 4

=item unique example

  my $unique = $self->unique;

=back

=cut
