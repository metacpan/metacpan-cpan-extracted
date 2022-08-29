package Faker::Plugin::SoftwareVersion;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->process_markers(
    $self->faker->random->select(data_for_software_version()),
    'numbers',
  );
}

sub data_for_software_version {
  state $software_version = [
    '#.##',
    '#.#',
    '#.#.#',
    '0.##',
    '0.#.#',
  ]
}

1;



=head1 NAME

Faker::Plugin::SoftwareVersion - Software Version

=cut

=head1 ABSTRACT

Software Version for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::SoftwareVersion;

  my $plugin = Faker::Plugin::SoftwareVersion->new;

  # bless(..., "Faker::Plugin::SoftwareVersion")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for software version.

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

The execute method returns a returns a random fake software version.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::SoftwareVersion;

  my $plugin = Faker::Plugin::SoftwareVersion->new;

  # bless(..., "Faker::Plugin::SoftwareVersion")

  # my $result = $plugin->execute;

  # 1.4;

  # my $result = $plugin->execute;

  # "0.4.4";

  # my $result = $plugin->execute;

  # "0.4.5";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::SoftwareVersion;

  my $plugin = Faker::Plugin::SoftwareVersion->new;

  # bless(..., "Faker::Plugin::SoftwareVersion")

=back

=cut