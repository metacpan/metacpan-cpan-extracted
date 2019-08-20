use 5.014;

use strict;
use warnings;

use Test::More;

=name

Doodle::Migration

=abstract

Database Migration Class

=synopsis

  # in lib/My/Migration/Step1.pm

  package My::Migration::Step1;

  use parent 'Doodle::Migration';

  sub up {
    my ($self, $doodle) = @_;

    my $users = $doodle->table('users');
    $users->primary('id');
    $users->string('email');
    $users->create;
    $users->index(columns => ['email'])->unique->create;

    return $doodle;
  }

  sub down {
    my ($self, $doodle) = @_;

    my $users = $doodle->table('users');
    $users->delete;

    return $doodle;
  }

  # in lib/My/Migration/Step2.pm

  package My::Migration::Step2;

  use parent 'Doodle::Migration';

  sub up {
    my ($self, $doodle) = @_;

    my $users = $doodle->table('users');
    $users->string('first_name')->create;
    $users->string('last_name')->create;

    return $doodle;
  }

  sub down {
    my ($self, $doodle) = @_;

    my $users = $doodle->table('users');
    $users->string('first_name')->delete;
    $users->string('last_name')->delete;

    return $doodle;
  }

  1;

=description

This package provides a base class for creating database migration classes
which will be handled by L<Doodle::Migrator> classes.

=cut

use_ok "Doodle::Migration";

ok 1 and done_testing;
