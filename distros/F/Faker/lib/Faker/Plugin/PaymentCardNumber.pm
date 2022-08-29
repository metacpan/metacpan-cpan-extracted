package Faker::Plugin::PaymentCardNumber;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin';

# METHODS

sub execute {
  my ($self, $data) = @_;

  my $method = $data->{method} ||= $self->faker->random->select(
    data_for_payment_card_number()
  );

  return $self->faker->$method;
}

sub data_for_payment_card_number {
  state $payment_card_number = [
    map('payment_card_visa', 1..6),
    map('payment_card_mastercard', 1..3),
    map('payment_card_american_express', 1..2),
    'payment_card_discover',
  ]
}

1;



=head1 NAME

Faker::Plugin::PaymentCardNumber - Payment Card Number

=cut

=head1 ABSTRACT

Payment Card Number for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::PaymentCardNumber;

  my $plugin = Faker::Plugin::PaymentCardNumber->new;

  # bless(..., "Faker::Plugin::PaymentCardNumber")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for payment card number.

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

The execute method returns a returns a random fake payment card number.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::PaymentCardNumber;

  my $plugin = Faker::Plugin::PaymentCardNumber->new;

  # bless(..., "Faker::Plugin::PaymentCardNumber")

  # my $result = $plugin->execute;

  # 453208446845507;

  # my $result = $plugin->execute;

  # 37443908982203;

  # my $result = $plugin->execute;

  # 491658288205589;

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::PaymentCardNumber;

  my $plugin = Faker::Plugin::PaymentCardNumber->new;

  # bless(..., "Faker::Plugin::PaymentCardNumber")

=back

=cut