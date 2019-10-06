package Doodle::Table::Helpers;

use 5.014;

use Data::Object 'Role', 'Doodle::Library';

our $VERSION = '0.07'; # VERSION

# METHODS

method binary(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->binary(%args);

  return $column;
}

method boolean(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->boolean(%args);

  return $column;
}

method char(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->char(%args);

  return $column;
}

method date(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->date(%args);

  return $column;
}

method datetime(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->datetime(%args);

  return $column;
}

method datetime_tz(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->datetime_tz(%args);

  return $column;
}

method decimal(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->decimal(%args);

  return $column;
}

method double(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->double(%args);

  return $column;
}

method enum(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->enum(%args);

  return $column;
}

method float(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->float(%args);

  return $column;
}

method increments_big(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->increments_big(%args);

  return $column;
}

method increments_medium(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->increments_medium(%args);

  return $column;
}

method increments_small(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->increments_small(%args);

  return $column;
}

method integer(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->integer(%args);

  return $column;
}

method integer_big(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->integer_big(%args);

  return $column;
}

method integer_big_unsigned(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->integer_big_unsigned(%args);

  return $column;
}

method integer_medium(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->integer_medium(%args);

  return $column;
}

method integer_medium_unsigned(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->integer_medium_unsigned(%args);

  return $column;
}

method integer_small(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->integer_small(%args);

  return $column;
}

method integer_small_unsigned(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->integer_small_unsigned(%args);

  return $column;
}

method integer_tiny(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->integer_tiny(%args);

  return $column;
}

method integer_tiny_unsigned(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->integer_tiny_unsigned(%args);

  return $column;
}

method integer_unsigned(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->integer_unsigned(%args);

  return $column;
}

method json(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->json(%args);

  return $column;
}

method morphs(Str $name) {
  my $type = "${name}_type";
  my $fkey = "${name}_fkey";

  my $type_column = $self->string($type);
  my $fkey_column = $self->integer($fkey);

  return [$type_column, $fkey_column];
}

method primary(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->increments->primary;

  return $column;
}

method string(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->string(%args);

  return $column;
}

method temporary() {
  $self->data->{temporary} = 1;

  return $self;
}

method if_exists() {
  $self->data->{if_exists} = 1;

  return $self;
}

method if_not_exists() {
  $self->data->{if_not_exists} = 1;

  return $self;
}

method text(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->text(%args);

  return $column;
}

method text_long(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->text_long(%args);

  return $column;
}

method text_medium(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->text_medium(%args);

  return $column;
}

method time(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->time(%args);

  return $column;
}

method time_tz(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->time_tz(%args);

  return $column;
}

method timestamp(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->timestamp(%args);

  return $column;
}

method timestamp_tz(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->timestamp_tz(%args);

  return $column;
}

method timestamps() {
  my $created_at = $self->datetime('created_at')->null;
  my $updated_at = $self->datetime('updated_at')->null;
  my $deleted_at = $self->datetime('deleted_at')->null;

  return [$created_at, $updated_at, $deleted_at];
}

method timestamps_tz() {
  my $created_at = $self->datetime_tz('created_at')->null;
  my $updated_at = $self->datetime_tz('updated_at')->null;
  my $deleted_at = $self->datetime_tz('deleted_at')->null;

  return [$created_at, $updated_at, $deleted_at];
}

method no_morphs(Str $name) {
  my $type = "${name}_type";
  my $fkey = "${name}_fkey";

  my $type_column = $self->string($type)->delete;
  my $fkey_column = $self->integer($fkey)->delete;

  return [$type_column, $fkey_column];
}

method no_timestamps() {
  my $created_at = $self->column('created_at')->delete;
  my $updated_at = $self->column('updated_at')->delete;
  my $deleted_at = $self->column('deleted_at')->delete;

  return [$created_at, $updated_at, $deleted_at];
}

method uuid(Str $name, Any %args) {
  my $column = $self->column($name);

  $column->uuid(%args);

  return $column;
}

1;

=encoding utf8

=head1 NAME

Doodle::Table::Helpers

=cut

=head1 ABSTRACT

Doodle Table Helpers

=cut

=head1 SYNOPSIS

  use Doodle;
  use Doodle::Table;

  my $ddl = Doodle->new;

  my $self = Doodle::Table->new(
    name => 'users',
    doodle => $ddl
  );

=cut

=head1 DESCRIPTION

Helpers for configuring Table classes.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Doodle::Library>

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 binary

  binary(Str $name, Any %args) : Column

Registers a binary column and returns the Command object set.

=over 4

=item binary example #1

  # given: synopsis

  my $binary = $self->binary('resume');

=back

=cut

=head2 boolean

  boolean(Str $name, Any %args) : Column

Registers a boolean column and returns the Command object set.

=over 4

=item boolean example #1

  # given: synopsis

  my $boolean = $self->boolean('verified');

=back

=cut

=head2 char

  char(Str $name, Any %args) : Column

Registers a char column and returns the Command object set.

=over 4

=item char example #1

  # given: synopsis

  my $char = $self->char('level', size => 2);

=back

=cut

=head2 date

  date(Str $name, Any %args) : Column

Registers a date column and returns the Command object set.

=over 4

=item date example #1

  # given: synopsis

  my $date = $self->date('start_date');

=back

=cut

=head2 datetime

  datetime(Str $name, Any %args) : Column

Registers a datetime column and returns the Command object set.

=over 4

=item datetime example #1

  # given: synopsis

  my $datetime = $self->datetime('published_at');

=back

=cut

=head2 datetime_tz

  datetime_tz(Str $name, Any %args) : Column

Registers a datetime column with timezone and returns the Command object set.

=over 4

=item datetime_tz example #1

  # given: synopsis

  my $datetime_tz = $self->datetime_tz('published_at');

=back

=cut

=head2 decimal

  decimal(Str $name, Any %args) : Column

Registers a decimal column and returns the Command object set.

=over 4

=item decimal example #1

  # given: synopsis

  my $decimal = $self->decimal('point');

=back

=cut

=head2 double

  double(Str $name, Any %args) : Column

Registers a double column and returns the Command object set.

=over 4

=item double example #1

  # given: synopsis

  my $double = $self->double('amount');

=back

=cut

=head2 enum

  enum(Str $name, Any %args) : Column

Registers an enum column and returns the Command object set.

=over 4

=item enum example #1

  # given: synopsis

  my $enum = $self->enum('colors', options => [
    'red', 'blue', 'green'
  ]);

=back

=cut

=head2 float

  float(Str $name, Any %args) : Column

Registers a float column and returns the Command object set.

=over 4

=item float example #1

  # given: synopsis

  my $float = $self->float('amount');

=back

=cut

=head2 if_exists

  if_exists() : Table

Used with the C<delete> method to denote that the table should be deleted only
if it already exists.

=over 4

=item if_exists example #1

  # given: synopsis

  $self->if_exists;

=back

=cut

=head2 if_not_exists

  if_not_exists() : Table

Used with the C<create> method to denote that the table should be created only
if it doesn't already exist.

=over 4

=item if_not_exists example #1

  # given: synopsis

  $self->if_not_exists;

=back

=cut

=head2 increments_big

  increments_big(Str $name, Any %args) : Column

Registers an auto-incrementing big integer (8-byte) column and returns the Command object set.

=over 4

=item increments_big example #1

  # given: synopsis

  my $increments_big = $self->increments_big('number');

=back

=cut

=head2 increments_medium

  increments_medium(Str $name, Any %args) : Column

Registers an auto-incrementing medium integer (3-byte) column and returns the Command object set.

=over 4

=item increments_medium example #1

  # given: synopsis

  my $increments_medium = $self->increments_medium('number');

=back

=cut

=head2 increments_small

  increments_small(Str $name, Any %args) : Column

Registers an auto-incrementing small integer (2-byte) column and returns the Command object set.

=over 4

=item increments_small example #1

  # given: synopsis

  my $increments_small = $self->increments_small('number');

=back

=cut

=head2 integer

  integer(Str $name, Any %args) : Column

Registers an integer (4-byte) column and returns the Command object set.

=over 4

=item integer example #1

  # given: synopsis

  my $integer = $self->integer('number');

=back

=cut

=head2 integer_big

  integer_big(Str $name, Any %args) : Column

Registers a big integer (8-byte) column and returns the Command object set.

=over 4

=item integer_big example #1

  # given: synopsis

  my $integer_big = $self->integer_big('number');

=back

=cut

=head2 integer_big_unsigned

  integer_big_unsigned(Str $name, Any %args) : Column

Registers an unsigned big integer (8-byte) column and returns the Command object set.

=over 4

=item integer_big_unsigned example #1

  # given: synopsis

  my $integer_big_unsigned = $self->integer_big_unsigned('number');

=back

=cut

=head2 integer_medium

  integer_medium(Str $name, Any %args) : Column

Registers a medium integer (3-byte) column and returns the Command object set.

=over 4

=item integer_medium example #1

  # given: synopsis

  my $integer_medium = $self->integer_medium('number');

=back

=cut

=head2 integer_medium_unsigned

  integer_medium_unsigned(Str $name, Any %args) : Column

Registers an unsigned medium integer (3-byte) column and returns the Command object set.

=over 4

=item integer_medium_unsigned example #1

  # given: synopsis

  my $integer_medium_unsigned = $self->integer_medium_unsigned('number');

=back

=cut

=head2 integer_small

  integer_small(Str $name, Any %args) : Column

Registers a small integer (2-byte) column and returns the Command object set.

=over 4

=item integer_small example #1

  # given: synopsis

  my $integer_small = $self->integer_small('number');

=back

=cut

=head2 integer_small_unsigned

  integer_small_unsigned(Str $name, Any %args) : Column

Registers an unsigned small integer (2-byte) column and returns the Command object set.

=over 4

=item integer_small_unsigned example #1

  # given: synopsis

  my $integer_small_unsigned = $self->integer_small_unsigned('number');

=back

=cut

=head2 integer_tiny

  integer_tiny(Str $name, Any %args) : Column

Registers a tiny integer (1-byte) column and returns the Command object set.

=over 4

=item integer_tiny example #1

  # given: synopsis

  my $integer_tiny = $self->integer_tiny('number');

=back

=cut

=head2 integer_tiny_unsigned

  integer_tiny_unsigned(Str $name, Any %args) : Column

Registers an unsigned tiny integer (1-byte) column and returns the Command object set.

=over 4

=item integer_tiny_unsigned example #1

  # given: synopsis

  my $integer_tiny_unsigned = $self->integer_tiny_unsigned('number');

=back

=cut

=head2 integer_unsigned

  integer_unsigned(Str $name, Any %args) : Column

Registers an unsigned integer (4-byte) column and returns the Command object set.

=over 4

=item integer_unsigned example #1

  # given: synopsis

  my $integer_unsigned = $self->integer_unsigned('number');

=back

=cut

=head2 json

  json(Str $name, Any %args) : Column

Registers a JSON column and returns the Command object set.

=over 4

=item json example #1

  # given: synopsis

  my $json = $self->json('metadata');

=back

=cut

=head2 morphs

  morphs(Str $name) : ArrayRef[Column]

Registers columns neccessary for polymorphism and returns the Column object set.

=over 4

=item morphs example #1

  # given: synopsis

  my $morphs = $self->morphs('parent');

=back

=cut

=head2 no_morphs

  no_morphs(Str $name) : ArrayRef[Command]

Registers a drop for C<{name}_fkey> and C<{name}_type> polymorphic columns and
returns the Command object set.

=over 4

=item no_morphs example #1

  # given: synopsis

  my $no_morphs = $self->no_morphs('profile');

=back

=cut

=head2 no_timestamps

  no_timestamps() : ArrayRef[Command]

Registers a drop for C<created_at>, C<updated_at> and C<deleted_at> columns and
returns the Command object set.

=over 4

=item no_timestamps example #1

  # given: synopsis

  my $no_timestamps = $self->no_timestamps;

=back

=cut

=head2 primary

  primary(Str $name, Any %args) : Column

Registers primary key(s) and returns the Command object set.

=over 4

=item primary example #1

  # given: synopsis

  my $primary = $self->primary('id');

=back

=cut

=head2 string

  string(Str $name, Any %args) : Column

Registers a string column and returns the Command object set.

=over 4

=item string example #1

  # given: synopsis

  my $string = $self->string('fname');

=back

=cut

=head2 temporary

  temporary() : Table

Denotes that the table created should be a temporary one.

=over 4

=item temporary example #1

  # given: synopsis

  my $temporary = $self->temporary;

=back

=cut

=head2 text

  text(Str $name, Any %args) : Column

Registers a text column and returns the Command object set.

=over 4

=item text example #1

  # given: synopsis

  my $text = $self->text('biography');

=back

=cut

=head2 text_long

  text_long(Str $name, Any %args) : Column

Registers a long text column and returns the Command object set.

=over 4

=item text_long example #1

  # given: synopsis

  my $text_long = $self->text_long('biography');

=back

=cut

=head2 text_medium

  text_medium(Str $name, Any %args) : Column

Registers a medium text column and returns the Command object set.

=over 4

=item text_medium example #1

  # given: synopsis

  my $text_medium = $self->text_medium('biography');

=back

=cut

=head2 time

  time(Str $name, Any %args) : Column

Registers a time column and returns the Command object set.

=over 4

=item time example #1

  # given: synopsis

  my $time = $self->time('clock_in');

=back

=cut

=head2 time_tz

  time_tz(Str $name, Any %args) : Column

Registers a time column with timezone and returns the Command object set.

=over 4

=item time_tz example #1

  # given: synopsis

  my $time_tz = $self->time_tz('clock_in');

=back

=cut

=head2 timestamp

  timestamp(Str $name, Any %args) : Column

Registers a timestamp column and returns the Command object set.

=over 4

=item timestamp example #1

  # given: synopsis

  my $timestamp = $self->timestamp('verified');

=back

=cut

=head2 timestamp_tz

  timestamp_tz(Str $name, Any %args) : Column

Registers a timestamp_tz column and returns the Command object set.

=over 4

=item timestamp_tz example #1

  # given: synopsis

  my $timestamp_tz = $self->timestamp_tz('verified');

=back

=cut

=head2 timestamps

  timestamps() : ArrayRef[Column]

Registers C<created_at>, C<updated_at> and C<deleted_at> columns and returns
the Command object set.

=over 4

=item timestamps example #1

  # given: synopsis

  my $timestamps = $self->timestamps;

=back

=cut

=head2 timestamps_tz

  timestamps_tz() : ArrayRef[Column]

Registers C<created_at>, C<updated_at> and C<deleted_at> columns with timezone
and returns the Command object set.

=over 4

=item timestamps_tz example #1

  # given: synopsis

  my $timestamps_tz = $self->timestamps_tz;

=back

=cut

=head2 uuid

  uuid(Str $name, Any %args) : Column

Registers a uuid column and returns the Command object set.

=over 4

=item uuid example #1

  # given: synopsis

  my $uuid = $self->uuid('reference');

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
