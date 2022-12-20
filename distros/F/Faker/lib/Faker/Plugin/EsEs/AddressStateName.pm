package Faker::Plugin::EsEs::AddressStateName;

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

  return $self->faker->random->select(data_for_address_state_name());
}

sub data_for_address_state_name {
  state $address_state_name = [
    'A Coruña',
    'Álava',
    'Albacete',
    'Alicante',
    'Almería',
    'Asturias',
    'Ávila',
    'Badajoz',
    'Barcelona',
    'Burgos',
    'Cáceres',
    'Cádiz',
    'Cantabria',
    'Castellón',
    'Ceuta',
    'Ciudad Real',
    'Cuenca',
    'Córdoba',
    'Girona',
    'Granada',
    'Guadalajara',
    'Guipuzkoa',
    'Huelva',
    'Huesca',
    'Illes Balears',
    'Jaén',
    'La Rioja',
    'Las Palmas',
    'León',
    'Lleida',
    'Lugo',
    'Málaga',
    'Madrid',
    'Melilla',
    'Murcia',
    'Navarra',
    'Ourense',
    'Palencia',
    'Pontevedra',
    'Salamanca',
    'Segovia',
    'Sevilla',
    'Soria',
    'Santa Cruz de Tenerife',
    'Tarragona',
    'Teruel',
    'Toledo',
    'Valencia',
    'Valladolid',
    'Vizcaya',
    'Zamora',
    'Zaragoza',
  ]
}

1;



=head1 NAME

Faker::Plugin::EsEs::AddressStateName - Address State Name

=cut

=head1 ABSTRACT

Address State Name for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EsEs::AddressStateName;

  my $plugin = Faker::Plugin::EsEs::AddressStateName->new;

  # bless(..., "Faker::Plugin::EsEs::AddressStateName")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address state name.

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

The execute method returns a returns a random fake address state name.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EsEs::AddressStateName;

  my $plugin = Faker::Plugin::EsEs::AddressStateName->new;

  # bless(..., "Faker::Plugin::EsEs::AddressStateName")

  # my $result = $plugin->execute;

  # 'Córdoba';

  # my $result = $plugin->execute;

  # 'Guipuzkoa';

  # my $result = $plugin->execute;

  # 'Tarragona';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EsEs::AddressStateName;

  my $plugin = Faker::Plugin::EsEs::AddressStateName->new;

  # bless(..., "Faker::Plugin::EsEs::AddressStateName")

=back

=cut