use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

statements

=usage

  my $statements = $self->statements('sqlite');

=description

The statements method loads and processes the migrations using the grammar
specified. This method returns a set of migrations, each containing a set of
"UP" and "DOWN" sets of SQL statements.

=signature

statements(Str $grammar) : [[[Str],[Str]]]

=type

method

=cut

# TESTING

use lib 't/lib';

use My::Migrator;
use Doodle::Migrator;

can_ok "Doodle::Migrator", "statements";

my $migrator = My::Migrator->new;

isa_ok $migrator, 'Doodle::Migrator';

my $statements = $migrator->statements('sqlite');

# migration #1 up-statement #1
is $statements->[0][0][0], qq{create table "users" ("id" integer primary key, "email" varchar)};
is $statements->[0][0][1], qq{create unique index "indx_users_email" on "users" ("email")};
# migration #1 dn-statement #1
is $statements->[0][1][0], qq{drop table "users"};

# migration #1 up-statement #1
is $statements->[1][0][0], qq{alter table "users" add column "first_name" varchar};
is $statements->[1][0][1], qq{alter table "users" add column "last_name" varchar};
# migration #1 dn-statement #1
is $statements->[1][1][0], qq{alter table "users" drop column "first_name"};
is $statements->[1][1][1], qq{alter table "users" drop column "last_name"};

ok 1 and done_testing;
