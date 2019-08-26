use 5.014;

use strict;
use warnings;

use Test::More;

=name

Doodle::Migration

=abstract

Database Migration Class

=synopsis

  # in lib/My/Migration.pm

  package My::Migration;

  use parent 'Doodle::Migration';

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

  # in script

  package main;

  my $migrator = My::Migration->new;

  my $results = $migrator->migrate('up', 'sqlite', sub {
    my ($sql) = @_;

    # e.g. $dbi->do($_) for @$sql;

    return 1;
  });

  1;

=description

This package provides a migrator class and migration base class in one package.
The C<migrations> method loads and collects the classes that exists as children
of the namespace returned by the C<namespace> method (which defaults to the
current class) and returns the class names as an array-reference.

=cut

use_ok "Doodle::Migration";

ok 1 and done_testing;
