package Faker::Plugin::EnUs::AddressCitySuffix;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::EnUs';

# VERSION

our $VERSION = '1.17';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->faker->random->select(data_for_address_city_suffix());
}

sub data_for_address_city_suffix {
  state $address_city_suffix = [
    'town',
    'ton',
    'land',
    'ville',
    'berg',
    'burgh',
    'borough',
    'bury',
    'view',
    'port',
    'mouth',
    'stad',
    'furt',
    'chester',
    'mouth',
    'fort',
    'haven',
    'side',
    'shire',
  ]
}

1;



=head1 NAME

Faker::Plugin::EnUs::AddressCitySuffix - Address City Suffix

=cut

=head1 ABSTRACT

Address City Suffix for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EnUs::AddressCitySuffix;

  my $plugin = Faker::Plugin::EnUs::AddressCitySuffix->new;

  # bless(..., "Faker::Plugin::EnUs::AddressCitySuffix")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address city suffix.

=encoding utf8

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Faker::Plugin::EnUs>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 execute

  execute(HashRef $data) (Str)

The execute method returns a returns a random fake address city suffix.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EnUs::AddressCitySuffix;

  my $plugin = Faker::Plugin::EnUs::AddressCitySuffix->new;

  # bless(..., "Faker::Plugin::EnUs::AddressCitySuffix")

  # my $result = $plugin->execute;

  # "borough";

  # my $result = $plugin->execute;

  # "view";

  # my $result = $plugin->execute;

  # "haven";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EnUs::AddressCitySuffix;

  my $plugin = Faker::Plugin::EnUs::AddressCitySuffix->new;

  # bless(..., "Faker::Plugin::EnUs::AddressCitySuffix")

=back

=cut