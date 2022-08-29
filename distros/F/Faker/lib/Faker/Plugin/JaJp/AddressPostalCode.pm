package Faker::Plugin::JaJp::AddressPostalCode;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::JaJp';

# METHODS

sub execute {
  my ($self, $data) = @_;

  my $random = $self->faker->random;

  return $random->range(100, 999) . $random->range(1000, 9999);
}

1;



=head1 NAME

Faker::Plugin::JaJp::AddressPostalCode - Address Postal Code

=cut

=head1 ABSTRACT

Address Postal Code for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::AddressPostalCode;

  my $plugin = Faker::Plugin::JaJp::AddressPostalCode->new;

  # bless(..., "Faker::Plugin::JaJp::AddressPostalCode")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address postal code.

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

The execute method returns a returns a random fake address postal code.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::AddressPostalCode;

  my $plugin = Faker::Plugin::JaJp::AddressPostalCode->new;

  # bless(..., "Faker::Plugin::JaJp::AddressPostalCode")

  # my $result = $plugin->execute;

  # '4081999';

  # my $result = $plugin->execute;

  # '1738707';

  # my $result = $plugin->execute;

  # '5307217';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::AddressPostalCode;

  my $plugin = Faker::Plugin::JaJp::AddressPostalCode->new;

  # bless(..., "Faker::Plugin::JaJp::AddressPostalCode")

=back

=cut