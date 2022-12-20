package Faker::Plugin::EnUs::AddressRegionName;

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

  my $method = $self->faker->random->bit ? 'address_state_name' : 'address_state_abbr';

  return $self->faker->$method;
}

1;



=head1 NAME

Faker::Plugin::EnUs::AddressRegionName - Address Region Name

=cut

=head1 ABSTRACT

Address Region Name for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EnUs::AddressRegionName;

  my $plugin = Faker::Plugin::EnUs::AddressRegionName->new;

  # bless(..., "Faker::Plugin::EnUs::AddressRegionName")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address region name.

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

The execute method returns a returns a random fake address region name.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EnUs::AddressRegionName;

  my $plugin = Faker::Plugin::EnUs::AddressRegionName->new;

  # bless(..., "Faker::Plugin::EnUs::AddressRegionName")

  # my $result = $plugin->execute;

  # "Massachusetts";

  # my $result = $plugin->execute;

  # "MO";

  # my $result = $plugin->execute;

  # "NE";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EnUs::AddressRegionName;

  my $plugin = Faker::Plugin::EnUs::AddressRegionName->new;

  # bless(..., "Faker::Plugin::EnUs::AddressRegionName")

=back

=cut