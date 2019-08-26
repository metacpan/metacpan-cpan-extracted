use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

migrations

=usage

  my $migrations = $self->migrations;

=description

The migrations method finds and loads child objects under the C<namespace> and
returns an array-reference which contains class names that have subclassed the
L<Doodle::Migration> base class.

=signature

migrations() : [Str]

=type

method

=cut

# TESTING

use lib 't/lib';

use My::Migration;
use Doodle::Migration;

can_ok "Doodle::Migration", "migrations";

my $migrator = My::Migration->new;

isa_ok $migrator, 'Doodle::Migration';

my $migrations = $migrator->migrations;

is @{$migrations}, 2;

isa_ok $migrations->[0], 'My::Migration::Step1';
isa_ok $migrations->[1], 'My::Migration::Step2';

ok 1 and done_testing;
