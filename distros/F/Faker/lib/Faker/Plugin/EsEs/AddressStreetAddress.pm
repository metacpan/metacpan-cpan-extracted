package Faker::Plugin::EsEs::AddressStreetAddress;

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

  return $self->process_format(
    $self->faker->random->select(data_for_address_street_address())
  );
}

sub data_for_address_street_address {
  state $address_street_address = [
    '{{address_street_name}}, {{address_number}}, {{address_line2}}',
  ]
}

1;



=head1 NAME

Faker::Plugin::EsEs::AddressStreetAddress - Address Street Address

=cut

=head1 ABSTRACT

Address Street Address for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EsEs::AddressStreetAddress;

  my $plugin = Faker::Plugin::EsEs::AddressStreetAddress->new;

  # bless(..., "Faker::Plugin::EsEs::AddressStreetAddress")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address street address.

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

The execute method returns a returns a random fake address street address.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EsEs::AddressStreetAddress;

  my $plugin = Faker::Plugin::EsEs::AddressStreetAddress->new;

  # bless(..., "Faker::Plugin::EsEs::AddressStreetAddress")

  # my $result = $plugin->execute;

  # 'Avenida Marc, 55, 69º D';

  # my $result = $plugin->execute;

  # 'Travesía Victoria, 203, Ático 2º';

  # my $result = $plugin->execute;

  # 'Rúa Castillo, 58, Entre suelo 5º';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EsEs::AddressStreetAddress;

  my $plugin = Faker::Plugin::EsEs::AddressStreetAddress->new;

  # bless(..., "Faker::Plugin::EsEs::AddressStreetAddress")

=back

=cut