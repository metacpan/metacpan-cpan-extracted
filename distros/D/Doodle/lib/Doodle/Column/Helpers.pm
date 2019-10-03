package Doodle::Column::Helpers;

use 5.014;

use Data::Object 'Role', 'Doodle::Library';

our $VERSION = '0.06'; # VERSION

# BUILD
# METHODS

method binary(Any %args) {
  $self->type('binary');

  $self->data->set(%args) if %args;

  return $self;
}

method boolean(Any %args) {
  $self->type('boolean');

  $self->data->set(%args) if %args;

  return $self;
}

method char(Any %args) {
  $self->type('char');

  $self->data->set(%args) if %args;

  return $self;
}

method date(Any %args) {
  $self->type('date');

  $self->data->set(%args) if %args;

  return $self;
}

method datetime(Any %args) {
  $self->type('datetime');

  $self->data->set(%args) if %args;

  return $self;
}

method datetime_tz(Any %args) {
  $self->type('datetime_tz');

  $self->data->set(%args) if %args;

  return $self;
}

method decimal(Any %args) {
  $self->type('decimal');

  $self->data->set(%args) if %args;

  return $self;
}

method double(Any %args) {
  $self->type('double');

  $self->data->set(%args) if %args;

  return $self;
}

method enum(Any %args) {
  $self->type('enum');

  $self->data->set(%args) if %args;

  return $self;
}

method float(Any %args) {
  $self->type('float');

  $self->data->set(%args) if %args;

  return $self;
}

method primary() {
  $self->data->set(primary => 1);

  return $self;
}

method increments() {
  $self->data->set(increments => 1);

  $self->integer if $self->type !~ /integer/;

  return $self;
}

method increments_big(Any %args) {
  $self->integer_big(%args);
  $self->increments;

  return $self;
}

method increments_medium(Any %args) {
  $self->integer_medium(%args);
  $self->increments;

  return $self;
}

method increments_small(Any %args) {
  $self->integer_small(%args);
  $self->increments;

  return $self;
}

method integer(Any %args) {
  $self->type('integer');

  $self->data->set(%args) if %args;

  return $self;
}

method integer_big(Any %args) {
  $self->type('integer_big');

  $self->data->set(%args) if %args;

  return $self;
}

method integer_big_unsigned(Any %args) {
  $self->type('integer_big_unsigned');

  $self->data->set(%args) if %args;

  return $self;
}

method integer_medium(Any %args) {
  $self->type('integer_medium');

  $self->data->set(%args) if %args;

  return $self;
}

method integer_medium_unsigned(Any %args) {
  $self->type('integer_medium_unsigned');

  $self->data->set(%args) if %args;

  return $self;
}

method integer_small(Any %args) {
  $self->type('integer_small');

  $self->data->set(%args) if %args;

  return $self;
}

method integer_small_unsigned(Any %args) {
  $self->type('integer_small_unsigned');

  $self->data->set(%args) if %args;

  return $self;
}

method integer_tiny(Any %args) {
  $self->type('integer_tiny');

  $self->data->set(%args) if %args;

  return $self;
}

method integer_tiny_unsigned(Any %args) {
  $self->type('integer_tiny_unsigned');

  $self->data->set(%args) if %args;

  return $self;
}

method integer_unsigned(Any %args) {
  $self->type('integer_unsigned');

  $self->data->set(%args) if %args;

  return $self;
}

method json(Any %args) {
  $self->type('json');

  $self->data->set(%args) if %args;

  return $self;
}

method null(Any %args) {
  $self->data->set(%args, nullable => 1);

  return $self;
}

method not_null(Any %args) {
  $self->data->set(%args, nullable => 0);

  return $self;
}

method references(Str $ftable, Str @args) {
  my $table = $self->table;

  return $table->relation($self->name, $ftable, @args);
}

method string(Any %args) {
  $self->type('string');

  $self->data->set(%args) if %args;

  return $self;
}

method text(Any %args) {
  $self->type('text');

  $self->data->set(%args) if %args;

  return $self;
}

method text_long(Any %args) {
  $self->type('text_long');

  $self->data->set(%args) if %args;

  return $self;
}

method text_medium(Any %args) {
  $self->type('text_medium');

  $self->data->set(%args) if %args;

  return $self;
}

method time(Any %args) {
  $self->type('time');

  $self->data->set(%args) if %args;

  return $self;
}

method time_tz(Any %args) {
  $self->type('time_tz');

  $self->data->set(%args) if %args;

  return $self;
}

method timestamp(Any %args) {
  $self->type('timestamp');

  $self->data->set(%args) if %args;

  return $self;
}

method timestamp_tz(Any %args) {
  $self->type('timestamp_tz');

  $self->data->set(%args) if %args;

  return $self;
}

method uuid(Any %args) {
  $self->type('uuid');

  $self->data->set(%args) if %args;

  return $self;
}

1;

=encoding utf8

=head1 NAME

Doodle::Column::Helpers

=cut

=head1 ABSTRACT

Doodle Column Helpers

=cut

=head1 SYNOPSIS

  use Doodle::Column;

  use Doodle;
  use Doodle::Column;
  use Doodle::Table;

  my $ddl = Doodle->new;

  my $table = Doodle::Table->new(
    name => 'users',
    doodle => $ddl
  );

  my $self = Doodle::Column->new(
    name => 'id',
    table => $table,
    doodle => $ddl
  );

=cut

=head1 DESCRIPTION

Helpers for configuring Column classes.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Doodle::Library>

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 binary

  binary(Any %args) : Column

Configures a binary column and returns itself.

=over 4

=item binary example #1

  # given: synopsis

  my $binary = $self->binary;

=back

=cut

=head2 boolean

  boolean(Any %args) : Column

Configures a boolean column and returns itself.

=over 4

=item boolean example #1

  # given: synopsis

  my $boolean = $self->boolean;

=back

=cut

=head2 char

  char(Any %args) : Column

Configures a char column and returns itself.

=over 4

=item char example #1

  # given: synopsis

  my $char = $self->char;

=back

=cut

=head2 date

  date(Any %args) : Column

Configures a date column and returns itself.

=over 4

=item date example #1

  # given: synopsis

  my $date = $self->date;

=back

=cut

=head2 datetime

  datetime(Any %args) : Column

Configures a datetime column and returns itself.

=over 4

=item datetime example #1

  # given: synopsis

  my $datetime = $self->datetime;

=back

=cut

=head2 datetime_tz

  datetime_tz(Any %args) : Column

Configures a datetime column with timezone and returns itself.

=over 4

=item datetime_tz example #1

  # given: synopsis

  my $datetime_tz = $self->datetime_tz;

=back

=cut

=head2 decimal

  decimal(Any %args) : Column

Configures a decimal column and returns itself.

=over 4

=item decimal example #1

  # given: synopsis

  my $decimal = $self->decimal;

=back

=cut

=head2 double

  double(Any %args) : Column

Configures a double column and returns itself.

=over 4

=item double example #1

  # given: synopsis

  my $double = $self->double;

=back

=cut

=head2 enum

  enum(Any %args) : Column

Configures an enum column and returns itself.

=over 4

=item enum example #1

  # given: synopsis

  my $enum = $self->enum(options => [
    'red', 'blue', 'green'
  ]);

=back

=cut

=head2 float

  float(Any %args) : Column

Configures a float column and returns itself.

=over 4

=item float example #1

  # given: synopsis

  my $float = $self->float;

=back

=cut

=head2 increments

  increments() : Column

Denotes that the column auto-increments and returns the Column object.

=over 4

=item increments example #1

  # given: synopsis

  my $increments = $self->increments;

=back

=cut

=head2 increments_big

  increments_big(Any %args) : Column

Configures an auto-incrementing big integer (8-byte) column and returns itself.

=over 4

=item increments_big example #1

  # given: synopsis

  my $increments_big = $self->increments_big;

=back

=cut

=head2 increments_medium

  increments_medium(Any %args) : Column

Configures an auto-incrementing medium integer (3-byte) column and returns itself.

=over 4

=item increments_medium example #1

  # given: synopsis

  my $increments_medium = $self->increments_medium;

=back

=cut

=head2 increments_small

  increments_small(Any %args) : Column

Configures an auto-incrementing small integer (2-byte) column and returns itself.

=over 4

=item increments_small example #1

  # given: synopsis

  my $increments_small = $self->increments_small;

=back

=cut

=head2 integer

  integer(Any %args) : Column

Configures an integer (4-byte) column and returns itself.

=over 4

=item integer example #1

  # given: synopsis

  my $integer = $self->integer;

=back

=cut

=head2 integer_big

  integer_big(Any %args) : Column

Configures a big integer (8-byte) column and returns itself.

=over 4

=item integer_big example #1

  # given: synopsis

  my $integer_big = $self->integer_big;

=back

=cut

=head2 integer_big_unsigned

  integer_big_unsigned(Any %args) : Column

Configures an unsigned big integer (8-byte) column and returns itself.

=over 4

=item integer_big_unsigned example #1

  # given: synopsis

  my $integer_big_unsigned = $self->integer_big_unsigned;

=back

=cut

=head2 integer_medium

  integer_medium(Any %args) : Column

Configures a medium integer (3-byte) column and returns itself.

=over 4

=item integer_medium example #1

  # given: synopsis

  my $integer_medium = $self->integer_medium;

=back

=cut

=head2 integer_medium_unsigned

  integer_medium_unsigned(Any %args) : Column

Configures an unsigned medium integer (3-byte) column and returns itself.

=over 4

=item integer_medium_unsigned example #1

  # given: synopsis

  my $integer_medium_unsigned = $self->integer_medium_unsigned;

=back

=cut

=head2 integer_small

  integer_small(Any %args) : Column

Configures a small integer (2-byte) column and returns itself.

=over 4

=item integer_small example #1

  # given: synopsis

  my $integer_small = $self->integer_small;

=back

=cut

=head2 integer_small_unsigned

  integer_small_unsigned(Any %args) : Column

Configures an unsigned small integer (2-byte) column and returns itself.

=over 4

=item integer_small_unsigned example #1

  # given: synopsis

  my $integer_small_unsigned = $self->integer_small_unsigned;

=back

=cut

=head2 integer_tiny

  integer_tiny(Any %args) : Column

Configures a tiny integer (1-byte) column and returns itself.

=over 4

=item integer_tiny example #1

  # given: synopsis

  my $integer_tiny = $self->integer_tiny;

=back

=cut

=head2 integer_tiny_unsigned

  integer_tiny_unsigned(Any %args) : Column

Configures an unsigned tiny integer (1-byte) column and returns itself.

=over 4

=item integer_tiny_unsigned example #1

  # given: synopsis

  my $integer_tiny_unsigned = $self->integer_tiny_unsigned;

=back

=cut

=head2 integer_unsigned

  integer_unsigned(Any %args) : Column

Configures an unsigned integer (4-byte) column and returns itself.

=over 4

=item integer_unsigned example #1

  # given: synopsis

  my $integer_unsigned = $self->integer_unsigned;

=back

=cut

=head2 json

  json(Any %args) : Column

Configures a JSON column and returns itself.

=over 4

=item json example #1

  # given: synopsis

  my $json = $self->json;

=back

=cut

=head2 not_null

  not_null(Any %args) : Column

Denotes that the Column is not nullable and returns itself.

=over 4

=item not_null example #1

  # given: synopsis

  my $not_null = $self->not_null;

=back

=cut

=head2 null

  null(Any %args) : Column

Denotes that the Column is nullable and returns itself.

=over 4

=item null example #1

  # given: synopsis

  my $null = $self->null;

=back

=cut

=head2 primary

  primary(Any %args) : Column

Denotes that the column is the primary key and returns the Column object.

=over 4

=item primary example #1

  # given: synopsis

  my $primary = $self->primary('id');

=back

=cut

=head2 references

  references(Str $table, Str $column) : Relation

Configures a relation and returns the Relation object.

=over 4

=item references example #1

  # given: synopsis

  my $references = $self->references('entities');

=back

=over 4

=item references example #2

  # given: synopsis

  my $references = $self->references('entities', 'uuid');

=back

=cut

=head2 string

  string(Any %args) : Column

Configures a string column and returns itself.

=over 4

=item string example #1

  # given: synopsis

  my $string = $self->string;

=back

=cut

=head2 text

  text(Any %args) : Column

Configures a text column and returns itself.

=over 4

=item text example #1

  # given: synopsis

  my $text = $self->text;

=back

=cut

=head2 text_long

  text_long(Any %args) : Column

Configures a long text column and returns itself.

=over 4

=item text_long example #1

  # given: synopsis

  my $text_long = $self->text_long;

=back

=cut

=head2 text_medium

  text_medium(Any %args) : Column

Configures a medium text column and returns itself.

=over 4

=item text_medium example #1

  # given: synopsis

  my $text_medium = $self->text_medium;

=back

=cut

=head2 time

  time(Any %args) : Column

Configures a time column and returns itself.

=over 4

=item time example #1

  # given: synopsis

  my $time = $self->time;

=back

=cut

=head2 time_tz

  time_tz(Any %args) : Column

Configures a time column with timezone and returns itself.

=over 4

=item time_tz example #1

  # given: synopsis

  my $time_tz = $self->time_tz;

=back

=cut

=head2 timestamp

  timestamp(Any %args) : Column

Configures a timestamp column and returns itself.

=over 4

=item timestamp example #1

  # given: synopsis

  my $timestamp = $self->timestamp;

=back

=cut

=head2 timestamp_tz

  timestamp_tz(Any %args) : Column

Configures a timestamp_tz column and returns itself.

=over 4

=item timestamp_tz example #1

  # given: synopsis

  my $timestamp_tz = $self->timestamp_tz;

=back

=cut

=head2 uuid

  uuid(Any %args) : Column

Configures a uuid column and returns itself.

=over 4

=item uuid example #1

  # given: synopsis

  my $uuid = $self->uuid;

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
