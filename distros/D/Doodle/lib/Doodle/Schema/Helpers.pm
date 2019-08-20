package Doodle::Schema::Helpers;

use 5.014;

use Data::Object 'Role', 'Doodle::Library';

our $VERSION = '0.04'; # VERSION

# METHODS

method if_exists() {
  $self->data->{if_exists} = 1;

  return $self;
}

method if_not_exists() {
  $self->data->{if_not_exists} = 1;

  return $self;
}

1;

=encoding utf8

=head1 NAME

Doodle::Schema::Helpers

=cut

=head1 ABSTRACT

Doodle Schema Helpers

=cut

=head1 SYNOPSIS

  use Doodle::Schema;

  my $self = Doodle::Schema->new(
    name => 'app'
  );

=cut

=head1 DESCRIPTION

Helpers for configuring Schema classes.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 if_exists

  if_exists() : Schema

Used with the C<delete> method to denote that the table should be deleted only
if it already exists.

=over 4

=item if_exists example

  $self->if_exists;

=back

=cut

=head2 if_not_exists

  if_not_exists() : Schema

Used with the C<delete> method to denote that the table should be deleted only
if it already exists.

=over 4

=item if_not_exists example

  $self->if_not_exists;

=back

=cut
