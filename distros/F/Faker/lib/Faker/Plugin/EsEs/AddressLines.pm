package Faker::Plugin::EsEs::AddressLines;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::EsEs';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->process_markers(
    $self->process_format(
      $self->faker->random->select(data_for_address_lines()),
    ),
    'newlines',
  );
}

sub data_for_address_lines {
  state $address_lines = [
    '{{address_street_address}}\n{{address_city_name}}, {{address_state_name}} {{address_postal_code}}'
  ]
}

1;



=head1 NAME

Faker::Plugin::EsEs::AddressLines - Address Lines

=cut

=head1 ABSTRACT

Address Lines for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EsEs::AddressLines;

  my $plugin = Faker::Plugin::EsEs::AddressLines->new;

  # bless(..., "Faker::Plugin::EsEs::AddressLines")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address lines.

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

The execute method returns a returns a random fake address lines.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EsEs::AddressLines;

  my $plugin = Faker::Plugin::EsEs::AddressLines->new;

  # bless(..., "Faker::Plugin::EsEs::AddressLines")

  # my $result = $plugin->execute;

  # "Praza Rocío, 50, 94º A\nEl Apodaca, Zamora 22037";

  # my $result = $plugin->execute;

  # "Paseo Salas, 558, Entre suelo 5º\nLos Blanco del Barco, La Rioja 96220";

  # my $result = $plugin->execute;

  # "Praza Nevárez, 12, 8º\nLas Negrón, Valladolid 56907";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EsEs::AddressLines;

  my $plugin = Faker::Plugin::EsEs::AddressLines->new;

  # bless(..., "Faker::Plugin::EsEs::AddressLines")

=back

=cut