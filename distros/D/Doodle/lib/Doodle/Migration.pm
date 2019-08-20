package Doodle::Migration;

use 5.014;

use Data::Object 'Class', 'Doodle::Library';

use Carp;

our $VERSION = '0.04'; # VERSION

# METHODS

method up(Doodle $d) {
  # this class is meant to be overwritten

  confess("This method is meant to be overwritten by the subclass");
}

method down(Doodle $d) {
  # this class is meant to be overwritten

  confess("This method is meant to be overwritten by the subclass");
}

1;

=encoding utf8

=head1 NAME

Doodle::Migration

=cut

=head1 ABSTRACT

Database Migration Class

=cut

=head1 SYNOPSIS

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

=cut

=head1 DESCRIPTION

This package provides a base class for creating database migration classes
which will be handled by L<Doodle::Migrator> classes.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 down

  down(Doodle $doodle) : Doodle

The migrate "DOWN" method is invoked automatically by the migrator
L<Doodle::Migrator>.

=over 4

=item down example

  $doodle = $self->down($doodle);

=back

=cut

=head2 up

  up(Doodle $doodle) : Doodle

The migrate "UP" method is invoked automatically by the migrator
L<Doodle::Migrator>.

=over 4

=item up example

  $doodle = $self->up($doodle);

=back

=cut
