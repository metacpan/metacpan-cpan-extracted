package Faker::Plugin::EsEs::AddressLine1;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::EsEs';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->process_format(
    $self->faker->random->select(data_for_address_line1())
  );
}

sub data_for_address_line1 {
  state $address_line1 = [
    '{{address_street_address}}, {{address_postal_code}}, {{address_city_name}}',
  ]
}

1;



=head1 NAME

Faker::Plugin::EsEs::AddressLine1 - Address Line1

=cut

=head1 ABSTRACT

Address Line1 for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EsEs::AddressLine1;

  my $plugin = Faker::Plugin::EsEs::AddressLine1->new;

  # bless(..., "Faker::Plugin::EsEs::AddressLine1")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address line1.

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

The execute method returns a returns a random fake address line1.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EsEs::AddressLine1;

  my $plugin = Faker::Plugin::EsEs::AddressLine1->new;

  # bless(..., "Faker::Plugin::EsEs::AddressLine1")

  # my $result = $plugin->execute;

  # 'Praza Rocío, 50, 94º A, 44390, Cornejo del Penedès';

  # my $result = $plugin->execute;

  # 'Plaça Pilar, 558, Entre suelo 5º, 23411, La Vargas';

  # my $result = $plugin->execute;

  # 'Camino Pedro, 15, 9º, 87686, As Mayorga';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EsEs::AddressLine1;

  my $plugin = Faker::Plugin::EsEs::AddressLine1->new;

  # bless(..., "Faker::Plugin::EsEs::AddressLine1")

=back

=cut