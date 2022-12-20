package Faker::Plugin::EsEs::AddressStreetPrefix;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::EsEs';

# VERSION

our $VERSION = '1.17';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->faker->random->select(data_for_address_street_prefix());
}

sub data_for_address_street_prefix {
  state $address_street_prefix = [
    'Calle',
    'Avenida',
    'Plaza',
    'Paseo',
    'Ronda',
    'Travesía',
    'Camino',
    'Carrer',
    'Avinguda',
    'Plaça',
    'Passeig',
    'Travessera',
    'Rúa',
    'Praza',
    'Ruela',
    'Camiño',
  ]
}

1;



=head1 NAME

Faker::Plugin::EsEs::AddressStreetPrefix - Address Street Prefix

=cut

=head1 ABSTRACT

Address Street Prefix for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EsEs::AddressStreetPrefix;

  my $plugin = Faker::Plugin::EsEs::AddressStreetPrefix->new;

  # bless(..., "Faker::Plugin::EsEs::AddressStreetPrefix")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address street prefix.

=encoding utf8

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Faker::Plugin::EsEs>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 execute

  execute(HashRef $data) (Str)

The execute method returns a returns a random fake address street prefix.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EsEs::AddressStreetPrefix;

  my $plugin = Faker::Plugin::EsEs::AddressStreetPrefix->new;

  # bless(..., "Faker::Plugin::EsEs::AddressStreetPrefix")

  # my $result = $plugin->execute;

  # 'Travesía';

  # my $result = $plugin->execute;

  # 'Camino';

  # my $result = $plugin->execute;

  # 'Praza';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EsEs::AddressStreetPrefix;

  my $plugin = Faker::Plugin::EsEs::AddressStreetPrefix->new;

  # bless(..., "Faker::Plugin::EsEs::AddressStreetPrefix")

=back

=cut