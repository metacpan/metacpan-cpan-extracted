package Faker::Plugin::EnUs::AddressLines;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::EnUs';

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
    '{{address_street_address}}\n{{address_city_name}}, {{address_state_abbr}} {{address_postal_code}}',
    '{{address_street_address}}\n{{address_city_name}}, {{address_state_name}} {{address_postal_code}}'
  ]
}

1;



=head1 NAME

Faker::Plugin::EnUs::AddressLines - Address Lines

=cut

=head1 ABSTRACT

Address Lines for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EnUs::AddressLines;

  my $plugin = Faker::Plugin::EnUs::AddressLines->new;

  # bless(..., "Faker::Plugin::EnUs::AddressLines")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address lines.

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

The execute method returns a returns a random fake address lines.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EnUs::AddressLines;

  my $plugin = Faker::Plugin::EnUs::AddressLines->new;

  # bless(..., "Faker::Plugin::EnUs::AddressLines")

  # my $result = $plugin->execute;

  # "4 Koelpin Plaza Unit 694\nWest Viviane, IA 37022";

  # my $result = $plugin->execute;

  # "90558 Greenholt Orchard\nApt. 250\nPfannerstillberg, New Mexico 52836";

  # my $result = $plugin->execute;

  # "68768 Weissnat Point\nRitchieburgh, New Mexico 53892";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EnUs::AddressLines;

  my $plugin = Faker::Plugin::EnUs::AddressLines->new;

  # bless(..., "Faker::Plugin::EnUs::AddressLines")

=back

=cut