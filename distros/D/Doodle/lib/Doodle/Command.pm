package Doodle::Command;

use 5.014;

use Data::Object 'Class', 'Doodle::Library';

our $VERSION = '0.07'; # VERSION

has name => (
  is => 'ro',
  isa => 'Str',
  req => 1
);

has doodle => (
  is => 'ro',
  isa => 'Doodle',
  req => 1
);

has schema => (
  is => 'ro',
  isa => 'Maybe[Schema]'
);

has table => (
  is => 'ro',
  isa => 'Table'
);

has columns => (
  is => 'ro',
  isa => 'Columns',
);

has indices => (
  is => 'ro',
  isa => 'Indices',
);

has relation => (
  is => 'ro',
  isa => 'Relation',
);

has data => (
  is => 'ro',
  isa => 'Data'
);

# BUILD

method BUILDARGS(%args) {
  my $data = {};

  my @names = qw(
    name
    doodle
    schema
    table
    columns
    indices
    relation
  );

  for my $name (@names) {
    $data->{$name} = delete $args{$name} if exists $args{$name};
  }

  $data->{columns} = $data->{columns} if $data->{columns};
  $data->{indices} = $data->{indices} if $data->{indices};

  $data->{data} = {%args} if !$data->{data};

  return $data;
}

1;

=encoding utf8

=head1 NAME

Doodle::Command

=cut

=head1 ABSTRACT

Doodle Command Class

=cut

=head1 SYNOPSIS

  use Doodle;
  use Doodle::Command;
  use Doodle::Table;

  my $ddl = Doodle->new;

  my $table = Doodle::Table->new(
    name => 'users',
    doodle => $ddl
  );

  my $self = Doodle::Command->new(
    name => 'create_table',
    table => $table,
    doodle => $ddl
  );

=cut

=head1 DESCRIPTION

This package provides a description of a DDL statement to build.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Doodle::Library>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 columns

  columns(Columns)

This attribute is read-only, accepts C<(Columns)> values, and is optional.

=cut

=head2 data

  data(Data)

This attribute is read-only, accepts C<(Data)> values, and is optional.

=cut

=head2 doodle

  doodle(Doodle)

This attribute is read-only, accepts C<(Doodle)> values, and is required.

=cut

=head2 indices

  indices(Indices)

This attribute is read-only, accepts C<(Indices)> values, and is optional.

=cut

=head2 name

  name(Any)

This attribute is read-only, accepts C<(Any)> values, and is optional.

=cut

=head2 relation

  relation(Relation)

This attribute is read-only, accepts C<(Relation)> values, and is optional.

=cut

=head2 schema

  schema(Maybe[Schema])

This attribute is read-only, accepts C<(Maybe[Schema])> values, and is optional.

=cut

=head2 table

  table(Table)

This attribute is read-only, accepts C<(Table)> values, and is optional.

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
