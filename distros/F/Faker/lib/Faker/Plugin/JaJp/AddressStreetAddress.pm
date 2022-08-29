package Faker::Plugin::JaJp::AddressStreetAddress;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::JaJp';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->process_format(
    $self->faker->random->select(data_for_address_street_address())
  );
}

sub data_for_address_street_address {
  state $address_street_address = [
    '{{address_street_name}}{{person_last_name}}{{address_area_number}}-{{address_area_number}}-{{address_area_number}}',
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::AddressStreetAddress - Address Street Address

=cut

=head1 ABSTRACT

Address Street Address for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::AddressStreetAddress;

  my $plugin = Faker::Plugin::JaJp::AddressStreetAddress->new;

  # bless(..., "Faker::Plugin::JaJp::AddressStreetAddress")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address street address.

=encoding utf8

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Faker::Plugin::JaJp>

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

  use Faker::Plugin::JaJp::AddressStreetAddress;

  my $plugin = Faker::Plugin::JaJp::AddressStreetAddress->new;

  # bless(..., "Faker::Plugin::JaJp::AddressStreetAddress")

  # my $result = $plugin->execute;

  # '佐藤町高橋7-5-6';

  # my $result = $plugin->execute;

  # '山本町高橋4-1-10';

  # my $result = $plugin->execute;

  # '伊藤町石田3-9-9';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::AddressStreetAddress;

  my $plugin = Faker::Plugin::JaJp::AddressStreetAddress->new;

  # bless(..., "Faker::Plugin::JaJp::AddressStreetAddress")

=back

=cut