package Faker::Plugin::UserLogin;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin';

# VERSION

our $VERSION = '1.17';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->process_markers(
    $self->process_format($self->faker->random->select(format_for_username()))
  );
}

sub format_for_username {
  state $name = [
    '{{person_last_name}}.{{person_first_name}}',
    '{{person_first_name}}.{{person_last_name}}',
    '{{person_first_name}}##',
    '{{person_first_name}}####',
    '?{{person_last_name}}',
    '?{{person_last_name}}####',
  ]
}

1;



=head1 NAME

Faker::Plugin::UserLogin - User Login

=cut

=head1 ABSTRACT

User Login for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::UserLogin;

  my $plugin = Faker::Plugin::UserLogin->new;

  # bless(..., "Faker::Plugin::UserLogin")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for user login.

=encoding utf8

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Faker::Plugin>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 execute

  execute(HashRef $data) (Str)

The execute method returns a returns a random fake user login.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::UserLogin;

  my $plugin = Faker::Plugin::UserLogin->new(
    faker => {locales => ['en-us']},
  );

  # bless(..., "Faker::Plugin::UserLogin")

  # my $result = $plugin->execute;

  # "Russel44";

  # my $result = $plugin->execute;

  # "aMayer7694";

  # my $result = $plugin->execute;

  # "Amalia89";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::UserLogin;

  my $plugin = Faker::Plugin::UserLogin->new;

  # bless(..., "Faker::Plugin::UserLogin")

=back

=cut