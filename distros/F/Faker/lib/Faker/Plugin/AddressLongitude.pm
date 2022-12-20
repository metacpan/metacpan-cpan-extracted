package Faker::Plugin::AddressLongitude;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin';

# VERSION

our $VERSION = '1.17';

# METHODS

sub execute {
  my ($self, $data) = @_;

  my $random = $self->faker->random;

  my $string = $random->select(
    [int($random->pick(90000000)), int($random->pick(-90000000))]
  );

  $string =~ s/\d*(\d\d)(\d{6})$/$1.$2/;

  return $string;
}

1;



=head1 NAME

Faker::Plugin::AddressLongitude - Address Longitude

=cut

=head1 ABSTRACT

Address Longitude for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::AddressLongitude;

  my $plugin = Faker::Plugin::AddressLongitude->new;

  # bless(..., "Faker::Plugin::AddressLongitude")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address longitude.

=encoding utf8

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Faker::Plugin>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 execute

  execute(HashRef $data) (Str)

The execute method returns a returns a random fake address longitude.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::AddressLongitude;

  my $plugin = Faker::Plugin::AddressLongitude->new;

  # bless(..., "Faker::Plugin::AddressLongitude")

  # my $result = $plugin->execute;

  # 30.843133;

  # my $result = $plugin->execute;

  # 77.079663;

  # my $result = $plugin->execute;

  # -41.660985;

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::AddressLongitude;

  my $plugin = Faker::Plugin::AddressLongitude->new;

  # bless(..., "Faker::Plugin::AddressLongitude")

=back

=cut