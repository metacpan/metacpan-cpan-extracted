package Doodle::Grammar::Mssql;

use 5.014;

use strict;
use warnings;

use registry 'Doodle::Library';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Doodle::Grammar';

our $VERSION = '0.08'; # VERSION

has name => (
  def => 'mssql',
  mod => 1
);

# BUILD
# METHODS

method wrap(Str $arg) {
  return '['. $arg .']';
}

method type_binary(Column $col) {
  # return column type string

  return 'varbinary(max)';
}

method type_boolean(Column $col) {
  # return column type string

  return 'bit';
}

method type_char(Column $col) {
  # return column type string

  my $size = $col->data->{size} || 1;

  return "nchar($size)";
}

method type_date(Column $col) {
  # return column type string

  return 'date';
}

method type_datetime(Column $col) {
  # return column type string

  return 'datetime';
}

method type_datetime_tz(Column $col) {
  # return column type string

  return 'datetimeoffset(0)';
}

method type_decimal(Column $col) {
  # return column type string

  my $total = $col->data->{total} || 5;
  my $scale = $col->data->{places} || 2;

  return "decimal($total, $scale)";
}

method type_double(Column $col) {
  # return column type string

  return 'float';
}

method type_enum(Column $col) {
  # return column type string

  return 'nvarchar(255)';
}

method type_float(Column $col) {
  # return column type string

  return 'float';
}

method type_integer(Column $col) {
  # return column type string

  return 'int';
}

method type_integer_big(Column $col) {
  # return column type string

  return 'bigint';
}

method type_integer_big_unsigned(Column $col) {
  # return column type string

  return $self->type_integer_big($col);
}

method type_integer_medium(Column $col) {
  # return column type string

  return 'int';
}

method type_integer_medium_unsigned(Column $col) {
  # return column type string

  return $self->type_integer_medium($col);
}

method type_integer_small(Column $col) {
  # return column type string

  return 'smallint';
}

method type_integer_small_unsigned(Column $col) {
  # return column type string

  return $self->type_integer_small($col);
}

method type_integer_tiny(Column $col) {
  # return column type string

  return 'tinyint';
}

method type_integer_tiny_unsigned(Column $col) {
  # return column type string

  return $self->type_integer_tiny($col);
}

method type_integer_unsigned(Column $col) {
  # return column type string

  return $self->type_integer($col);
}

method type_json(Column $col) {
  # return column type string

  return 'nvarchar(max)';
}

method type_string(Column $col) {
  # return column type string

  my $size = $col->data->{size} || 255;

  return "nvarchar($size)";
}

method type_text(Column $col) {
  # return column type string

  return 'nvarchar(max)';
}

method type_text_long(Column $col) {
  # return column type string

  return 'nvarchar(max)';
}

method type_text_medium(Column $col) {
  # return column type string

  return 'nvarchar(max)';
}

method type_time(Column $col) {
  # return column type string

  return 'time';
}

method type_time_tz(Column $col) {
  # return column type string

  return 'time';
}

method type_timestamp(Column $col) {
  # return column type string

  my $default = 'default CURRENT_TIMESTAMP';

  $default = "" if !$col->data->{use_current};

  return 'datetime' . ($default ? " $default" : '');
}

method type_timestamp_tz(Column $col) {
  # return column type string

  my $default = 'default CURRENT_TIMESTAMP';

  $default = "" if !$col->data->{use_current};

  return 'datetimeoffset(0)' . ($default ? " $default" : '');
}

method type_uuid(Column $col) {
  # return column type string

  return 'uniqueidentifier';
}

method create_table(Command $cmd) {
  my $s = 'create {temporary} table {if_not_exists} {table} ({columns}{, constraints})';

  return $self->render($s, $cmd);
}

method delete_table(Command $cmd) {
  my $s = 'drop table {if_exists} {table}';

  return $self->render($s, $cmd);
}

method rename_table(Command $cmd) {
  my $s = 'rename table {table} to {new_table}';

  return $self->render($s, $cmd);
}

method create_column(Command $cmd) {
  my $s = 'alter table {table} add column {new_column}';

  return $self->render($s, $cmd);
}

method update_column(Command $cmd) {
  my $s = 'alter table {table} alter column {column_name} {column_change}';

  return $self->render($s, $cmd);
}

method delete_column(Command $cmd) {
  my $s = 'alter table {table} drop column {column_name}';

  return $self->render($s, $cmd);
}

method create_index(Command $cmd) {
  my $s ='create {unique} index {index_name} on {table} ({index_columns})';

  return $self->render($s, $cmd);
}

method delete_index(Command $cmd) {
  my $s = 'drop index {index_name}';

  return $self->render($s, $cmd);
}

method create_relation(Command $cmd) {
  my $s ='alter table {table} add constraint {relation}';

  return $self->render($s, $cmd);
}

method delete_relation(Command $cmd) {
  my $s ='alter table {table} drop constraint {relation_name}';

  return $self->render($s, $cmd);
}

method create_schema(Command $cmd) {
  my $s ='create database {schema_name}';

  return $self->render($s, $cmd);
}

method delete_schema(Command $cmd) {
  my $s ='drop database {schema_name}';

  return $self->render($s, $cmd);
}

method render_increments(Column $col) {
  # render column auto-increment expression

  my $data = $col->data;

  return $data->{increments} ? 'identity(1,1)' : ();
}

1;

=encoding utf8

=head1 NAME

Doodle::Grammar::Mssql

=cut

=head1 ABSTRACT

Doodle Grammar For MSSQL

=cut

=head1 SYNOPSIS

  use Doodle::Grammar::Mssql;

  my $self = Doodle::Grammar::Mssql->new;

=cut

=head1 DESCRIPTION

This provide determines how command classes should be interpreted to produce
the correct DDL statements for Mssql.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Doodle::Grammar>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Doodle::Library>

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 create_column

  create_column(Command $command) : Str

Returns the SQL statement for the create column command.

=over 4

=item create_column example #1

  # given: synopsis

  use Doodle;

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $c = $t->primary('id');

  my $command = $c->create;

  $self->create_column($command);

  # alter table [users] add column [id] int identity(1,1) primary key

=back

=cut

=head2 create_index

  create_index(Command $command) : Str

Returns the SQL statement for the create index command.

=over 4

=item create_index example #1

  # given: synopsis

  use Doodle;

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $i = $t->index(columns => ['id']);

  my $command = $i->create;

  $self->create_index($command);

  # create index [indx_users_id] on [users] ([id])

=back

=cut

=head2 create_relation

  create_relation(Command $command) : Str

Returns the SQL statement for the create relation command.

=over 4

=item create_relation example #1

  # given: synopsis

  use Doodle;

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $r = $t->relation('profile_id', 'profiles', 'id');

  my $command = $r->create;

  $self->create_relation($command);

  # alter table [users] add constraint [fkey_users_profile_id_profiles_id]
  # foreign key ([profile_id]) references profiles ([id])

=back

=cut

=head2 create_schema

  create_schema(Command $command) : Str

Returns the SQL statement for the create schema command.

=over 4

=item create_schema example #1

  # given: synopsis

  use Doodle;

  my $d = Doodle->new;
  my $s = $d->schema('app');

  my $command = $s->create;

  $self->create_schema($command);

  # create database [app]

=back

=cut

=head2 create_table

  create_table(Command $command) : Str

Returns the SQL statement for the create table command.

=over 4

=item create_table example #1

  # given: synopsis

  use Doodle;

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $c = $t->column('data');

  my $command = $t->create;

  $self->create_table($command);

  # create table [users] ([data] nvarchar(255))

=back

=cut

=head2 delete_column

  delete_column(Command $command) : Str

Returns the SQL statement for the delete column command.

=over 4

=item delete_column example #1

  # given: synopsis

  use Doodle;

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $c = $t->primary('id');

  my $command = $c->delete;

  $self->delete_column($command);

  # alter table [users] drop column [id]

=back

=cut

=head2 delete_index

  delete_index(Command $command) : Str

Returns the SQL statement for the delete index command.

=over 4

=item delete_index example #1

  # given: synopsis

  use Doodle;

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $i = $t->index(columns => ['id']);

  my $command = $i->delete;

  $self->delete_index($command);

  # drop index [indx_users_id]

=back

=cut

=head2 delete_relation

  delete_relation(Command $command) : Str

Returns the SQL statement for the delete relation command.

=over 4

=item delete_relation example #1

  # given: synopsis

  use Doodle;

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $r = $t->relation('profile_id', 'profiles', 'id');

  my $command = $r->delete;

  $self->delete_relation($command);

  # alter table [users] drop constraint [fkey_users_profile_id_profiles_id]

=back

=cut

=head2 delete_schema

  delete_schema(Command $command) : Str

Returns the SQL statement for the create schema command.

=over 4

=item delete_schema example #1

  # given: synopsis

  use Doodle;

  my $d = Doodle->new;
  my $s = $d->schema('app');

  my $command = $s->create;

  $self->delete_schema($command);

  # drop database [app]

=back

=cut

=head2 delete_table

  delete_table(Command $command) : Str

Returns the SQL statement for the delete table command.

=over 4

=item delete_table example #1

  # given: synopsis

  use Doodle;

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $c = $t->column('data');

  my $command = $t->delete;

  $self->delete_table($command);

  # drop table [users]

=back

=cut

=head2 rename_table

  rename_table(Command $command) : Str

Returns the SQL statement for the rename table command.

=over 4

=item rename_table example #1

  # given: synopsis

  use Doodle;

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $c = $t->column('data');

  my $command = $t->rename('people');

  $self->rename_table($command);

  # rename table [users] to [people]

=back

=cut

=head2 type_binary

  type_binary(Column $column) : Str

Returns the type expression for a binary column.

=over 4

=item type_binary example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('binary');

  $self->type_binary($column);

  # varbinary(max)

=back

=cut

=head2 type_boolean

  type_boolean(Column $column) : Str

Returns the type expression for a boolean column.

=over 4

=item type_boolean example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('boolean');

  $self->type_boolean($column);

  # bit

=back

=cut

=head2 type_char

  type_char(Column $column) : Str

Returns the type expression for a char column.

=over 4

=item type_char example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('char');

  $self->type_char($column);

  # nchar(1)

=back

=over 4

=item type_char example #2

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('char', size => 10);

  $self->type_char($column);

  # nchar(10)

=back

=cut

=head2 type_date

  type_date(Column $column) : Str

Returns the type expression for a date column.

=over 4

=item type_date example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('date');

  $self->type_date($column);

  # date

=back

=cut

=head2 type_datetime

  type_datetime(Column $column) : Str

Returns the type expression for a datetime column.

=over 4

=item type_datetime example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('datetime');

  $self->type_datetime($column);

  # datetime

=back

=cut

=head2 type_datetime_tz

  type_datetime_tz(Column $column) : Str

Returns the type expression for a datetime_tz column.

=over 4

=item type_datetime_tz example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('datetime_tz');

  $self->type_datetime_tz($column);

  # datetimeoffset(0)

=back

=cut

=head2 type_decimal

  type_decimal(Column $column) : Str

Returns the type expression for a decimal column.

=over 4

=item type_decimal example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('decimal');

  $self->type_decimal($column);

  # decimal(5, 2)

=back

=cut

=head2 type_double

  type_double(Column $column) : Str

Returns the type expression for a double column.

=over 4

=item type_double example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('double');

  $self->type_double($column);

  # float

=back

=cut

=head2 type_enum

  type_enum(Column $column) : Str

Returns the type expression for a enum column.

=over 4

=item type_enum example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('enum');

  $self->type_enum($column);

  # nvarchar(255)

=back

=cut

=head2 type_float

  type_float(Column $column) : Str

Returns the type expression for a float column.

=over 4

=item type_float example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('float');

  $self->type_float($column);

  # float

=back

=cut

=head2 type_integer

  type_integer(Column $column) : Str

Returns the type expression for a integer column.

=over 4

=item type_integer example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('integer');

  $self->type_integer($column);

  # int

=back

=cut

=head2 type_integer_big

  type_integer_big(Column $column) : Str

Returns the type expression for a integer_big column.

=over 4

=item type_integer_big example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('integer_big');

  $self->type_integer_big($column);

  # bigint

=back

=cut

=head2 type_integer_big_unsigned

  type_integer_big_unsigned(Column $column) : Str

Returns the type expression for a integer_big_unsigned column.

=over 4

=item type_integer_big_unsigned example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('integer_big_unsigned');

  $self->type_integer_big_unsigned($column);

  # bigint

=back

=cut

=head2 type_integer_medium

  type_integer_medium(Column $column) : Str

Returns the type expression for a integer_medium column.

=over 4

=item type_integer_medium example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('integer_medium');

  $self->type_integer_medium($column);

  # int

=back

=cut

=head2 type_integer_medium_unsigned

  type_integer_medium_unsigned(Column $column) : Str

Returns the type expression for a integer_medium_unsigned column.

=over 4

=item type_integer_medium_unsigned example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('integer_medium_unsigned');

  $self->type_integer_medium_unsigned($column);

  # int

=back

=cut

=head2 type_integer_small

  type_integer_small(Column $column) : Str

Returns the type expression for a integer_small column.

=over 4

=item type_integer_small example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('integer_small');

  $self->type_integer_small($column);

  # smallint

=back

=cut

=head2 type_integer_small_unsigned

  type_integer_small_unsigned(Column $column) : Str

Returns the type expression for a integer_small_unsigned column.

=over 4

=item type_integer_small_unsigned example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('integer_small_unsigned');

  $self->type_integer_small_unsigned($column);

  # smallint

=back

=cut

=head2 type_integer_tiny

  type_integer_tiny(Column $column) : Str

Returns the type expression for a integer_tiny column.

=over 4

=item type_integer_tiny example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('integer_tiny');

  $self->type_integer_tiny($column);

  # tinyint

=back

=cut

=head2 type_integer_tiny_unsigned

  type_integer_tiny_unsigned(Column $column) : Str

Returns the type expression for a integer_tiny_unsigned column.

=over 4

=item type_integer_tiny_unsigned example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('integer_tiny_unsigned');

  $self->type_integer_tiny_unsigned($column);

  # tinyint

=back

=cut

=head2 type_integer_unsigned

  type_integer_unsigned(Column $column) : Str

Returns the type expression for a integer_unsigned column.

=over 4

=item type_integer_unsigned example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('integer_unsigned');

  $self->type_integer_unsigned($column);

  # int

=back

=cut

=head2 type_json

  type_json(Column $column) : Str

Returns the type expression for a json column.

=over 4

=item type_json example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('json');

  $self->type_json($column);

  # nvarchar(max)

=back

=cut

=head2 type_string

  type_string(Column $column) : Str

Returns the type expression for a string column.

=over 4

=item type_string example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('string');

  $self->type_string($column);

  # nvarchar(255)

=back

=cut

=head2 type_text

  type_text(Column $column) : Str

Returns the type expression for a text column.

=over 4

=item type_text example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('text');

  $self->type_text($column);

  # nvarchar(max)

=back

=cut

=head2 type_text_long

  type_text_long(Column $column) : Str

Returns the type expression for a text_long column.

=over 4

=item type_text_long example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('text_long');

  $self->type_text_long($column);

  # nvarchar(max)

=back

=cut

=head2 type_text_medium

  type_text_medium(Column $column) : Str

Returns the type expression for a text_medium column.

=over 4

=item type_text_medium example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('text_medium');

  $self->type_text_medium($column);

  # nvarchar(max)

=back

=cut

=head2 type_time

  type_time(Column $column) : Str

Returns the type expression for a time column.

=over 4

=item type_time example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('time');

  $self->type_time($column);

  # time

=back

=cut

=head2 type_time_tz

  type_time_tz(Column $column) : Str

Returns the type expression for a time_tz column.

=over 4

=item type_time_tz example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('time_tz');

  $self->type_time_tz($column);

  # time

=back

=cut

=head2 type_timestamp

  type_timestamp(Column $column) : Str

Returns the type expression for a timestamp column.

=over 4

=item type_timestamp example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('timestamp');

  $self->type_timestamp($column);

  # datetime

=back

=cut

=head2 type_timestamp_tz

  type_timestamp_tz(Column $column) : Str

Returns the type expression for a timestamp_tz column.

=over 4

=item type_timestamp_tz example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('timestamp_tz');

  $self->type_timestamp_tz($column);

  # datetimeoffset(0)

=back

=cut

=head2 type_uuid

  type_uuid(Column $column) : Str

Returns the type expression for a uuid column.

=over 4

=item type_uuid example #1

  # given: synopsis

  use Doodle;

  my $ddl = Doodle->new;
  my $column = $ddl->table('users')->column('uuid');

  $self->type_uuid($column);

  # uniqueidentifier

=back

=cut

=head2 update_column

  update_column(Command $command) : Str

Returns the SQL statement for the update column command.

=over 4

=item update_column example #1

  # given: synopsis

  use Doodle;

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $c = $t->primary('id');

  my $command = $c->update;

  $self->update_column($command);

  # alter table [users] alter column [id] type integer

  $command = $c->update(set => 'not null');

  $self->update_column($command);

  # alter table [users] alter column [id] set not null

=back

=cut

=head2 wrap

  wrap(Str $arg) : Str

Returns a wrapped SQL identifier.

=over 4

=item wrap example #1

  # given: synopsis

  my $wrapped = $self->wrap('data');

  # [data]

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
