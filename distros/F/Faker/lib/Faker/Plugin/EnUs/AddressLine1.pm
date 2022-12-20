package Faker::Plugin::EnUs::AddressLine1;

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
    $self->faker->random->select(data_for_address_line1())
  );
}

sub data_for_address_line1 {
  state $address_line1 = [
    '{{address_number}} {{address_street_name}}'
  ]
}

1;



=head1 NAME

Faker::Plugin::EnUs::AddressLine1 - Address Line1

=cut

=head1 ABSTRACT

Address Line1 for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EnUs::AddressLine1;

  my $plugin = Faker::Plugin::EnUs::AddressLine1->new;

  # bless(..., "Faker::Plugin::EnUs::AddressLine1")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address line1.

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

The execute method returns a returns a random fake address line1.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EnUs::AddressLine1;

  my $plugin = Faker::Plugin::EnUs::AddressLine1->new;

  # bless(..., "Faker::Plugin::EnUs::AddressLine1")

  # my $result = $plugin->execute;

  # "44084 Mayer Brook";

  # my $result = $plugin->execute;

  # "4 Amalia Terrace";

  # my $result = $plugin->execute;

  # "20370 Emard Street";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EnUs::AddressLine1;

  my $plugin = Faker::Plugin::EnUs::AddressLine1->new;

  # bless(..., "Faker::Plugin::EnUs::AddressLine1")

=back

=cut