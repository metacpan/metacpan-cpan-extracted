package Faker::Plugin::EnUs::AddressCityName;

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

  return $self->process_format(
    $self->faker->random->select(data_for_address_city_name()),
  );
}

sub data_for_address_city_name {
  state $address_city_name = [
    '{{address_city_prefix}} {{person_first_name}}{{address_city_suffix}}',
    '{{address_city_prefix}} {{person_first_name}}',
    '{{person_first_name}}{{address_city_suffix}}',
    '{{person_last_name}}{{address_city_suffix}}',
  ]
}

1;



=head1 NAME

Faker::Plugin::EnUs::AddressCityName - Address City Name

=cut

=head1 ABSTRACT

Address City Name for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EnUs::AddressCityName;

  my $plugin = Faker::Plugin::EnUs::AddressCityName->new;

  # bless(..., "Faker::Plugin::EnUs::AddressCityName")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address city name.

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

The execute method returns a returns a random fake address city name.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EnUs::AddressCityName;

  my $plugin = Faker::Plugin::EnUs::AddressCityName->new;

  # bless(..., "Faker::Plugin::EnUs::AddressCityName")

  # my $result = $plugin->execute;

  # "West Jamison";

  # my $result = $plugin->execute;

  # "Mayertown";

  # my $result = $plugin->execute;

  # "Juliaborough";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EnUs::AddressCityName;

  my $plugin = Faker::Plugin::EnUs::AddressCityName->new;

  # bless(..., "Faker::Plugin::EnUs::AddressCityName")

=back

=cut