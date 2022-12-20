package Faker::Plugin::EnUs::AddressStateAbbr;

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

  return $self->faker->random->select(data_for_address_state_abbr());
}

sub data_for_address_state_abbr {
  state $address_state_abbr = [
    'AK',
    'AL',
    'AR',
    'AZ',
    'CA',
    'CO',
    'CT',
    'DC',
    'DE',
    'FL',
    'GA',
    'HI',
    'IA',
    'ID',
    'IL',
    'IN',
    'KS',
    'KY',
    'LA',
    'MA',
    'MD',
    'ME',
    'MI',
    'MN',
    'MO',
    'MS',
    'MT',
    'NC',
    'ND',
    'NE',
    'NH',
    'NJ',
    'NM',
    'NV',
    'NY',
    'OH',
    'OK',
    'OR',
    'PA',
    'RI',
    'SC',
    'SD',
    'TN',
    'TX',
    'UT',
    'VA',
    'VT',
    'WA',
    'WI',
    'WV',
    'WY',
  ]
}

1;



=head1 NAME

Faker::Plugin::EnUs::AddressStateAbbr - Address State Abbr

=cut

=head1 ABSTRACT

Address State Abbr for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EnUs::AddressStateAbbr;

  my $plugin = Faker::Plugin::EnUs::AddressStateAbbr->new;

  # bless(..., "Faker::Plugin::EnUs::AddressStateAbbr")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address state abbr.

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

The execute method returns a returns a random fake address state abbr.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EnUs::AddressStateAbbr;

  my $plugin = Faker::Plugin::EnUs::AddressStateAbbr->new;

  # bless(..., "Faker::Plugin::EnUs::AddressStateAbbr")

  # my $result = $plugin->execute;

  # "KY";

  # my $result = $plugin->execute;

  # "ME";

  # my $result = $plugin->execute;

  # "TX";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EnUs::AddressStateAbbr;

  my $plugin = Faker::Plugin::EnUs::AddressStateAbbr->new;

  # bless(..., "Faker::Plugin::EnUs::AddressStateAbbr")

=back

=cut