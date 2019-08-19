package Doodle::Relation::Helpers;

use 5.014;

use Data::Object 'Role', 'Doodle::Library';

our $VERSION = '0.03'; # VERSION

# METHODS

method on_delete(Str $action) {
  $self->data->{on_delete} = $action;

  return $self;
}

method on_update(Str $action) {
  $self->data->{on_update} = $action;

  return $self;
}

1;

=encoding utf8

=head1 NAME

Doodle::Relation::Helpers

=cut

=head1 ABSTRACT

Doodle Relation Helpers

=cut

=head1 SYNOPSIS

  use Doodle::Relation;

  my $self = Doodle::Relation->new(
    column => 'profile_id',
    ftable => 'profiles',
    fcolumn => 'id'
  );

=cut

=head1 DESCRIPTION

Helpers for configuring Relation classes.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 on_delete

  on_delete(Str $action) : Relation

Denote the "ON DELETE" action for a foreign key constraint and returns the Relation.

=over 4

=item on_delete example

  my $on_delete = $self->on_delete('cascade');

=back

=cut

=head2 on_update

  on_update(Str $action) : Relation

Denote the "ON UPDATE" action for a foreign key constraint and returns the Relation.

=over 4

=item on_update example

  my $on_update = $self->on_update('cascade');

=back

=cut
