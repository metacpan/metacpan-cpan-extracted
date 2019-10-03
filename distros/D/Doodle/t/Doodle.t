use 5.014;

use Do;
use Test::Auto;
use Test::More;

=name

Doodle

=cut

=abstract

Database DDL (= Data Definition Language) Statement Builder

=cut

=includes

method: build
method: grammar
method: schema
method: statements
method: table

=cut

=synopsis

  use Doodle;

  my $self = Doodle->new;
  my $table = $self->table('users');

  $table->primary('id');
  $table->uuid('arid');
  $table->column('name');
  $table->string('email');
  $table->json('metadata');

  my $command = $table->create;
  my $grammar = $self->grammar('sqlite');
  my $statement = $grammar->execute($command);

  # say $statement->sql;

  # create table "users" (
  #   "id" integer primary key,
  #   "arid" varchar,
  #   "name" varchar,
  #   "email" varchar,
  #   "metadata" text
  # )

=cut

=attributes

commands: ro, opt, Commands

=cut

=integrates

Doodle::Helpers

=cut

=description

Doodle is a database
L<DDL ("Data Definition Language" or "Data Description Language")|https://en.wikipedia.org/wiki/Data_definition_language>
statement builder and provides an object-oriented
abstraction for performing schema changes in various datastores.
This class consumes the L<Doodle::Helpers> roles.

=cut

=libraries

Doodle::Library

=cut

=method build

Execute a given callback for each generated SQL statement.

=cut

=signature build

build(Grammar $grammar, CodeRef $callback) : Any

=cut

=example-1 build

  # given: synopsis

  $self->build($grammar, sub {
    my $statement = shift;

    # e.g. $db->do($statement->sql);
  });

=cut

=method grammar

Returns a new Grammar object.

=cut

=signature grammar

grammar(Str $name) : Grammar

=cut

=example-1 grammar

  # given: synopsis

  my $type = 'sqlite';

  $grammar = $self->grammar($type);

=cut

=method schema

Returns a new Schema object.

=cut

=signature schema

schema(Str $name, Any %args) : Schema

=cut

=example-1 schema

  # given: synopsis

  my $name = 'app';

  my $schema = $self->schema($name);

=cut

=method statements

Returns a set of Statement objects for the given grammar.

=cut

=signature statements

statements(Grammar $g) : Statements

=cut

=example-1 statements

  # given: synopsis

  my $statements = $self->statements($grammar);

=cut

=method table

Return a new Table object.

=cut

=signature table

table(Str $name, Any %args) : Table

=cut

=example-1 table

  # given: synopsis

  my $name = 'users';

  $table = $self->table($name);

=cut

package main;

my $test = Test::Auto->new(__FILE__);

my $subtests = $test->subtests->standard;

$subtests->example(-1, 'build', 'method', fun($tryable) {
  ok !(my $result = $tryable->result), 'result ok';

  $result;
});

$subtests->example(-1, 'grammar', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'schema', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'statements', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'table', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

sub context {
  my ($grammar, $table, $callback) = @_;

  my $d = Doodle->new;
  my $t = $d->table($table);

  my $x = $callback->($t);
  my $g = $d->grammar($grammar);
  my $s = $g->execute($x);

  return $s;
}

subtest 'test schema create', fun() {
  my $schema_create = sub {
    my $t = shift;
    my $d = $t->doodle;
    my $s = $d->schema('app');

    return $s->create;
  };

  my $mysql_schema_create = context('mysql', 'users', $schema_create);
  is $mysql_schema_create->sql,
    qq{create database `app`};

  my $postgres_schema_create = context('postgres', 'users', $schema_create);
  is $postgres_schema_create->sql,
    qq{create database "app"};

  my $mssql_schema_create = context('mssql', 'users', $schema_create);
  is $mssql_schema_create->sql,
    qq{create database [app]};
};

subtest 'test schema delete', fun() {
  my $schema_delete = sub {
    my $t = shift;
    my $d = $t->doodle;
    my $s = $d->schema('app');

    return $s->delete;
  };

  my $mysql_schema_delete = context('mysql', 'users', $schema_delete);
  is $mysql_schema_delete->sql,
    qq{drop database `app`};

  my $postgres_schema_delete = context('postgres', 'users', $schema_delete);
  is $postgres_schema_delete->sql,
    qq{drop database "app"};

  my $mssql_schema_delete = context('mssql', 'users', $schema_delete);
  is $mssql_schema_delete->sql,
    qq{drop database [app]};
};

subtest 'test table create', fun() {
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
};

subtest 'test table create: relations', fun() {
  my $relations = sub {
    my $t = shift;

    $t->integer('profile_id')->not_null;
    $t->relation('profile_id', 'profiles', 'id');

    return $t->create;
  };

  my $sqlite_relations = context('sqlite', 'users', $relations);
  is $sqlite_relations->sql,
    qq{create table "users" ("profile_id" integer not null, foreign key ("profile_id") references "profiles" ("id"))};

  my $mysql_relations = context('mysql', 'users', $relations);
  is $mysql_relations->sql,
    qq{create table `users` (`profile_id` int not null, foreign key (`profile_id`) references `profiles` (`id`))};

  my $postgres_relations = context('postgres', 'users', $relations);
  is $postgres_relations->sql,
    qq{create table "users" ("profile_id" integer not null, foreign key ("profile_id") references "profiles" ("id"))};

  my $mssql_relations = context('mssql', 'users', $relations);
  is $mssql_relations->sql,
    qq{create table [users] ([profile_id] int not null, foreign key ([profile_id]) references [profiles] ([id]))};
};

subtest 'test table delete', fun() {
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
};

subtest 'test column nullability', fun() {
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
};

subtest 'test column update: type only', fun() {
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
};

subtest 'test column update: set null', fun() {
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
};

subtest 'test column update: set not null', fun() {
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
};

subtest 'test column update: drop null', fun() {
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
};

ok 1 and done_testing;
