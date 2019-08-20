use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

namespace

=usage

  my $namespace = $self->namespace();

=description

The namespace method returns the root namespace where all child
L<Doodle::Migration> classes can be found.

=signature

namespace() : Str

=type

method

=cut

# TESTING

use lib 't/lib';

use My::Migrator;
use Doodle::Migrator;

can_ok "Doodle::Migrator", "namespace";

my $migrator = My::Migrator->new;

isa_ok $migrator, 'Doodle::Migrator';

is $migrator->namespace, 'My::Migration';

ok 1 and done_testing;
