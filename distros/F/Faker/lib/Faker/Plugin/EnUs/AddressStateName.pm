package Faker::Plugin::EnUs::AddressStateName;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::EnUs';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->faker->random->select(data_for_address_state_name());
}

sub data_for_address_state_name {
  state $address_state_name = [
    'Alabama',
    'Alaska',
    'Arizona',
    'Arkansas',
    'California',
    'Colorado',
    'Connecticut',
    'Delaware',
    'District of Columbia',
    'Florida',
    'Georgia',
    'Hawaii',
    'Idaho',
    'Illinois',
    'Indiana',
    'Iowa',
    'Kansas',
    'Kentucky',
    'Louisiana',
    'Maine',
    'Maryland',
    'Massachusetts',
    'Michigan',
    'Minnesota',
    'Mississippi',
    'Missouri',
    'Montana',
    'Nebraska',
    'Nevada',
    'New Hampshire',
    'New Jersey',
    'New Mexico',
    'New York',
    'North Carolina',
    'North Dakota',
    'Ohio',
    'Oklahoma',
    'Oregon',
    'Pennsylvania',
    'Rhode Island',
    'South Carolina',
    'South Dakota',
    'Tennessee',
    'Texas',
    'Utah',
    'Vermont',
    'Virginia',
    'Washington',
    'West Virginia',
    'Wisconsin',
    'Wyoming',
  ]
}

1;



=head1 NAME

Faker::Plugin::EnUs::AddressStateName - Address State Name

=cut

=head1 ABSTRACT

Address State Name for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EnUs::AddressStateName;

  my $plugin = Faker::Plugin::EnUs::AddressStateName->new;

  # bless(..., "Faker::Plugin::EnUs::AddressStateName")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address state name.

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

The execute method returns a returns a random fake address state name.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EnUs::AddressStateName;

  my $plugin = Faker::Plugin::EnUs::AddressStateName->new;

  # bless(..., "Faker::Plugin::EnUs::AddressStateName")

  # my $result = $plugin->execute;

  # "Kentucky";

  # my $result = $plugin->execute;

  # "Massachusetts";

  # my $result = $plugin->execute;

  # "Texas";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EnUs::AddressStateName;

  my $plugin = Faker::Plugin::EnUs::AddressStateName->new;

  # bless(..., "Faker::Plugin::EnUs::AddressStateName")

=back

=cut