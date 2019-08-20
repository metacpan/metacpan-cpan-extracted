use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

migrations

=usage

  my $migrations = $self->migrations();

=description

The migrations method find and loads child objects under the C<namespace> and
returns a set of L<Data::Object::Space> objects representing classes that have
subclassed the L<Doodle::Migration> base class.

=signature

migrations() : [Object]

=type

method

=cut

# TESTING

use lib 't/lib';

use My::Migrator;
use Doodle::Migrator;

can_ok "Doodle::Migrator", "migrations";

my $migrator = My::Migrator->new;

isa_ok $migrator, 'Doodle::Migrator';

my $migrations = $migrator->migrations;

is @{$migrations}, 2;

isa_ok $migrations->[0], 'My::Migration::Step1';
isa_ok $migrations->[1], 'My::Migration::Step2';

ok 1 and done_testing;
