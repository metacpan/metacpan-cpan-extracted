use 5.014;

use strict;
use warnings;

use Test::More;

=name

Doodle

=abstract

Database DDL Statement Builder

=synopsis

  use Doodle;

  my $d = Doodle->new;
  my $t = $d->table('users');

  $t->primary('id');
  $t->uuid('arid');
  $t->column('name');
  $t->string('email');
  $t->json('metadata');

  my $x = $t->create;
  my $g = $d->grammar('sqlite');
  my $s = $g->execute($x);

  say $s->sql;

  # create table "users" (
  #   "id" integer primary key,
  #   "arid" varchar,
  #   "name" varchar,
  #   "email" varchar,
  #   "metadata" text
  # )

=description

Doodle is a database DDL statement builder and provides an object-oriented
abstraction for performing schema changes in various datastores.

=cut

use_ok "Doodle";

sub context {
  my ($grammar, $table, $callback) = @_;

  my $d = Doodle->new;
  my $t = $d->table($table);

  my $x = $callback->($t);
  my $g = $d->grammar($grammar);
  my $s = $g->execute($x);

  return $s;
}

my $schema_create = sub {
  my $t = shift;
  my $d = $t->doodle;
  my $s = $d->schema('app');

  return $s->create;
};

# my $mysql_schema_create = context('mysql', 'users', $schema_create);
# is $mysql_schema_create->sql,
#   qq{create database `app`};

# my $postgres_schema_create = context('postgres', 'users', $schema_create);
# is $postgres_schema_create->sql,
#   qq{create database "app"};

# my $mssql_schema_create = context('mssql', 'users', $schema_create);
# is $mssql_schema_create->sql,
#   qq{create database [app]};

my $create = sub {
  my $t = shift;

  $t->primary('id');
  $t->uuid('arid');

  return $t->create;
};

my $sqlite_create = context('sqlite', 'users', $create);
is $sqlite_create->sql,
  qq{create table "users" ("id" integer primary key, "arid" varchar)};

my $mysql_create = context('mysql', 'users', $create);
is $mysql_create->sql,
  qq{create table `users` (`id` int auto_increment primary key, `arid` char(36))};

my $postgres_create = context('postgres', 'users', $create);
is $postgres_create->sql,
  qq{create table "users" ("id" serial primary key, "arid" uuid)};

my $mssql_create = context('mssql', 'users', $create);
is $mssql_create->sql,
  qq{create table [users] ([id] int identity(1,1) primary key, [arid] uniqueidentifier)};


my $null = sub {
  my $t = shift;

  $t->string('data')->null;

  return $t->create;
};

my $sqlite_null = context('sqlite', 'users', $null);
is $sqlite_null->sql,
  qq{create table "users" ("data" varchar null)};

my $mysql_null = context('mysql', 'users', $null);
is $mysql_null->sql,
  qq{create table `users` (`data` varchar(255) null)};

my $postgres_null = context('postgres', 'users', $null);
is $postgres_null->sql,
  qq{create table "users" ("data" varchar(255) null)};

my $mssql_null = context('mssql', 'users', $null);
is $mssql_null->sql,
  qq{create table [users] ([data] nvarchar(255) null)};

my $notnull = sub {
  my $t = shift;

  $t->string('data')->not_null;

  return $t->create;
};

my $sqlite_notnull = context('sqlite', 'users', $notnull);
is $sqlite_notnull->sql,
  qq{create table "users" ("data" varchar not null)};

my $mysql_notnull = context('mysql', 'users', $notnull);
is $mysql_notnull->sql,
  qq{create table `users` (`data` varchar(255) not null)};

my $postgres_notnull = context('postgres', 'users', $notnull);
is $postgres_notnull->sql,
  qq{create table "users" ("data" varchar(255) not null)};

my $mssql_notnull = context('mssql', 'users', $notnull);
is $mssql_notnull->sql,
  qq{create table [users] ([data] nvarchar(255) not null)};

my $update = sub {
  my $t = shift;

  return $t->text('data')->update;
};

my $sqlite_update = context('sqlite', 'users', $update);
is $sqlite_update->sql,
  qq{alter table "users" alter column "data" type text};

my $mysql_update = context('mysql', 'users', $update);
is $mysql_update->sql,
  qq{alter table `users` alter column `data` type text};

my $postgres_update = context('postgres', 'users', $update);
is $postgres_update->sql,
  qq{alter table "users" alter column "data" type text};

my $mssql_update = context('mssql', 'users', $update);
is $mssql_update->sql,
  qq{alter table [users] alter column [data] type text};

my $update_null = sub {
  my $t = shift;

  return $t->text('data')->update(set => 'null');
};

my $sqlite_update_null = context('sqlite', 'users', $update_null);
is $sqlite_update_null->sql,
  qq{alter table "users" alter column "data" set null};

my $mysql_update_null = context('mysql', 'users', $update_null);
is $mysql_update_null->sql,
  qq{alter table `users` alter column `data` set null};

my $postgres_update_null = context('postgres', 'users', $update_null);
is $postgres_update_null->sql,
  qq{alter table "users" alter column "data" set null};

my $mssql_update_null = context('mssql', 'users', $update_null);
is $mssql_update_null->sql,
  qq{alter table [users] alter column [data] set null};

my $update_notnull = sub {
  my $t = shift;

  return $t->text('data')->update(set => 'not null');
};

my $sqlite_update_notnull = context('sqlite', 'users', $update_notnull);
is $sqlite_update_notnull->sql,
  qq{alter table "users" alter column "data" set not null};

my $mysql_update_notnull = context('mysql', 'users', $update_notnull);
is $mysql_update_notnull->sql,
  qq{alter table `users` alter column `data` set not null};

my $postgres_update_notnull = context('postgres', 'users', $update_notnull);
is $postgres_update_notnull->sql,
  qq{alter table "users" alter column "data" set not null};

my $mssql_update_notnull = context('mssql', 'users', $update_notnull);
is $mssql_update_notnull->sql,
  qq{alter table [users] alter column [data] set not null};

my $update_dropnull = sub {
  my $t = shift;

  return $t->text('data')->update(drop => 'null');
};

my $sqlite_update_dropnull = context('sqlite', 'users', $update_dropnull);
is $sqlite_update_dropnull->sql,
  qq{alter table "users" alter column "data" drop null};

my $mysql_update_dropnull = context('mysql', 'users', $update_dropnull);
is $mysql_update_dropnull->sql,
  qq{alter table `users` alter column `data` drop null};

my $postgres_update_dropnull = context('postgres', 'users', $update_dropnull);
is $postgres_update_dropnull->sql,
  qq{alter table "users" alter column "data" drop null};

my $mssql_update_dropnull = context('mssql', 'users', $update_dropnull);
is $mssql_update_dropnull->sql,
  qq{alter table [users] alter column [data] drop null};

my $delete = sub {
  my $t = shift;

  return $t->delete;
};

my $sqlite_delete = context('sqlite', 'users', $delete);
is $sqlite_delete->sql,
  qq{drop table "users"};

my $mysql_delete = context('mysql', 'users', $delete);
is $mysql_delete->sql,
  qq{drop table `users`};

my $postgres_delete = context('postgres', 'users', $delete);
is $postgres_delete->sql,
  qq{drop table "users"};

my $mssql_delete = context('mssql', 'users', $delete);
is $mssql_delete->sql,
  qq{drop table [users]};

ok 1 and done_testing;
