package Doodle::Column;

use 5.014;

use Data::Object 'Class', 'Doodle::Library';

with 'Doodle::Column::Helpers';

our $VERSION = '0.01'; # VERSION

has name => (
  is => 'ro',
  isa => 'Any',
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
  bld => 'new_data',
  lzy => 1
);

# BUILD

fun new_data($self) {
  return do('hash', {});
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
  $args{columns} = do('array', [$self]);

  my $command = $self->doodle->column_create(%args);

  return $command;
}

method update(Any %args) {
  my $table = $self->table;

  $args{table} = $table;
  $args{schema} = $table->schema if $table->schema;
  $args{columns} = do('array', [$self]);

  $self->data->set(drop => delete $args{drop}) if $args{drop};
  $self->data->set(set => delete $args{set}) if $args{set};

  my $command = $self->doodle->column_update(%args);

  return $command;
}

method delete(Any %args) {
  my $table = $self->table;

  $args{table} = $table;
  $args{schema} = $table->schema if $table->schema;
  $args{columns} = do('array', [$self]);

  my $command = $self->doodle->column_delete(%args);

  return $command;
}

method rename(Str $name, Any %args) {
  my $table = $self->table;

  $args{table} = $table;
  $args{schema} = $table->schema if $table->schema;
  $args{columns} = do('array', [$self]);

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

  use Doodle::Column;

  my $self = Doodle::Column->new(%args);

=cut

=head1 DESCRIPTION

Table column representation.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 create

  create(Any %args) : Column

Registers a column create and returns the Command object.

=over 4

=item create example

  my $create = $self->create;

=back

=cut

=head2 delete

  delete(Any %args) : Column

Registers a column delete and returns the Command object.

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

=head2 rename

  rename(Any %args) : Command

Registers a column rename and returns the Command object.

=over 4

=item rename example

  my $rename = $self->rename;

=back

=cut

=head2 update

  update(Any %args) : Command

Registers a column update and returns the Command object.

=over 4

=item update example

  my $update = $self->update;

=back

=cut
