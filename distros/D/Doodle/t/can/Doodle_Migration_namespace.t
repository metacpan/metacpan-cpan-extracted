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

use My::Migration;
use Doodle::Migration;

can_ok "Doodle::Migration", "namespace";

my $migrator = My::Migration->new;

isa_ok $migrator, 'Doodle::Migration';

is $migrator->namespace, 'My::Migration';

ok 1 and done_testing;
