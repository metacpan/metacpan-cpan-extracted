package Faker::Plugin::EsEs::AddressCityPrefix;

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

  return $self->faker->random->select(data_for_address_city_prefix());
}

sub data_for_address_city_prefix {
  state $address_city_prefix = [
    'San',
    'Vall',
    "L'",
    'Villa',
    'El',
    'Los',
    'La',
    'Las',
    'O',
    'A',
    'Os',
    'As',
  ]
}

1;



=head1 NAME

Faker::Plugin::EsEs::AddressCityPrefix - Address City Prefix

=cut

=head1 ABSTRACT

Address City Prefix for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EsEs::AddressCityPrefix;

  my $plugin = Faker::Plugin::EsEs::AddressCityPrefix->new;

  # bless(..., "Faker::Plugin::EsEs::AddressCityPrefix")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address city prefix.

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

The execute method returns a returns a random fake address city prefix.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EsEs::AddressCityPrefix;

  my $plugin = Faker::Plugin::EsEs::AddressCityPrefix->new;

  # bless(..., "Faker::Plugin::EsEs::AddressCityPrefix")

  # my $result = $plugin->execute;

  # 'El';

  # my $result = $plugin->execute;

  # 'Los';

  # my $result = $plugin->execute;

  # 'Os';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EsEs::AddressCityPrefix;

  my $plugin = Faker::Plugin::EsEs::AddressCityPrefix->new;

  # bless(..., "Faker::Plugin::EsEs::AddressCityPrefix")

=back

=cut