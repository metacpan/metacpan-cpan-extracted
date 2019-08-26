use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

migrate

=usage

  my $migrate = $self->migrate('up', 'sqlite', sub {
    my ($sql) = @_;

    # do something ...

    return 1;
  });

=description

The migrate method collects all processed statements and iterates over the "UP"
or "DOWN" SQL statements, passing the set of SQL statements to the supplied
callback with each iteration.

=signature

migrate(Str $updn, Str $grammar, CodeRef $callback) : [Any]

=type

method

=cut

# TESTING

use lib 't/lib';

use My::Migration;
use Doodle::Migration;

can_ok "Doodle::Migration", "migrate";

my $migrator = My::Migration->new;

isa_ok $migrator, 'Doodle::Migration';

my $up_results = $migrator->migrate('up', 'sqlite', sub {
  my $sql = shift;

  return (@$sql);
});

is_deeply $up_results, [
  qq{create table "users" ("id" integer primary key, "email" varchar)},
  qq{create unique index "indx_users_email" on "users" ("email")},
  qq{alter table "users" add column "first_name" varchar},
  qq{alter table "users" add column "last_name" varchar}
];

my $dn_results = $migrator->migrate('down', 'sqlite', sub {
  my $sql = shift;

  return (@$sql);
});

is_deeply $dn_results, [
  qq{alter table "users" drop column "first_name"},
  qq{alter table "users" drop column "last_name"},
  qq{drop table "users"}
];

ok 1 and done_testing;
