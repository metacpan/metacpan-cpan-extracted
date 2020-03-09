package Doodle::Relation::Helpers;

use 5.014;

use strict;
use warnings;

use registry 'Doodle::Library';
use routines;

use Data::Object::Role;

our $VERSION = '0.08'; # VERSION

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

  use Doodle;
  use Doodle::Relation;
  use Doodle::Table;

  my $ddl = Doodle->new;

  my $table = Doodle::Table->new(
    name => 'users',
    doodle => $ddl
  );

  my $self = Doodle::Relation->new(
    table => $table,
    column => 'person_id',
    foreign_table => 'persons',
    foreign_column => 'id'
  );

=cut

=head1 DESCRIPTION

Helpers for configuring Relation classes.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Doodle::Library>

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 on_delete

  on_delete(Str $action) : Relation

Denote the "ON DELETE" action for a foreign key constraint and returns the Relation.

=over 4

=item on_delete example #1

  # given: synopsis

  my $on_delete = $self->on_delete('cascade');

=back

=cut

=head2 on_update

  on_update(Str $action) : Relation

Denote the "ON UPDATE" action for a foreign key constraint and returns the Relation.

=over 4

=item on_update example #1

  # given: synopsis

  my $on_update = $self->on_update('cascade');

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
