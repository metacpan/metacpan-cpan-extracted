use 5.014;

use strict;
use warnings;

use Test::More;

=name

Doodle::Migrator

=abstract

Database Migrator Class

=synopsis

  # in lib/My/Migrator.pm

  package My::Migrator;

  use parent 'Doodle::Migrator';

  sub namespace {
    return 'My::Migration';
  }

  # in lib/My/Migration/Step1.pm

  package My::Migration::Step1;

  use parent 'Doodle::Migration';

  sub up {
    my ($self, $doodle) = @_;

    # add something ...

    return $doodle;
  }

  sub down {
    my ($self, $doodle) = @_;

    # subtract something ...

    return $doodle;
  }

  # in script

  package main;

  my $migrator = My::Migrator->new;

  my $results = $migrator->migrate('up', 'sqlite', sub {
    my ($sql) = @_;

    # e.g. $dbi->do($_) for @$sql;

    return 1;
  });

  1;

=description

This package provides a migrator class which collects the specified
L<Doodle::Migration> classes and processes them.

=cut

use_ok "Doodle::Migrator";

ok 1 and done_testing;
