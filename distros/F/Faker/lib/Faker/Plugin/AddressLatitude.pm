package Faker::Plugin::AddressLatitude;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin';

# METHODS

sub execute {
  my ($self, $data) = @_;

  my $random = $self->faker->random;

  my $string = $random->select(
    [int($random->make(90000000)), int($random->make(-90000000))]
  );

  $string =~ s/\d*(\d\d)(\d{6})$/$1.$2/;

  return $string;
}

1;



=head1 NAME

Faker::Plugin::AddressLatitude - Address Latitude

=cut

=head1 ABSTRACT

Address Latitude for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::AddressLatitude;

  my $plugin = Faker::Plugin::AddressLatitude->new;

  # bless(..., "Faker::Plugin::AddressLatitude")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address latitude.

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

The execute method returns a returns a random fake address latitude.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::AddressLatitude;

  my $plugin = Faker::Plugin::AddressLatitude->new;

  # bless(..., "Faker::Plugin::AddressLatitude")

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

  use Faker::Plugin::AddressLatitude;

  my $plugin = Faker::Plugin::AddressLatitude->new;

  # bless(..., "Faker::Plugin::AddressLatitude")

=back

=cut