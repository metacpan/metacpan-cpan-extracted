package Faker::Plugin::PaymentVendor;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->faker->random->select(data_for_payment_vendor());
}

sub data_for_payment_vendor {
  state $payment_vendor = [
    'Visa',
    'Visa',
    'Visa',
    'Visa',
    'Visa',
    'MasterCard',
    'MasterCard',
    'MasterCard',
    'MasterCard',
    'MasterCard',
    'American Express',
    'Discover Card',
  ]
}

1;



=head1 NAME

Faker::Plugin::PaymentVendor - Payment Vendor

=cut

=head1 ABSTRACT

Payment Vendor for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::PaymentVendor;

  my $plugin = Faker::Plugin::PaymentVendor->new;

  # bless(..., "Faker::Plugin::PaymentVendor")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for payment vendor.

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

The execute method returns a returns a random fake payment vendor.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::PaymentVendor;

  my $plugin = Faker::Plugin::PaymentVendor->new;

  # bless(..., "Faker::Plugin::PaymentVendor")

  # my $result = $plugin->execute;

  # "Visa";

  # my $result = $plugin->execute;

  # "MasterCard";

  # my $result = $plugin->execute;

  # "American Express";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::PaymentVendor;

  my $plugin = Faker::Plugin::PaymentVendor->new;

  # bless(..., "Faker::Plugin::PaymentVendor")

=back

=cut