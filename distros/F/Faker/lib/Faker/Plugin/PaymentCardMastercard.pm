package Faker::Plugin::PaymentCardMastercard;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->process_markers(
    $self->faker->random->select(data_for_payment_card_mastercard()),
    'numbers',
  );
}

sub data_for_payment_card_mastercard {
  state $payment_card_mastercard = [
    '51#############',
    '52#############',
    '53#############',
    '54#############',
    '55#############',
  ]
}

1;



=head1 NAME

Faker::Plugin::PaymentCardMastercard - Payment Card Mastercard

=cut

=head1 ABSTRACT

Payment Card Mastercard for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::PaymentCardMastercard;

  my $plugin = Faker::Plugin::PaymentCardMastercard->new;

  # bless(..., "Faker::Plugin::PaymentCardMastercard")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for payment card mastercard.

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

The execute method returns a returns a random fake payment card mastercard.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::PaymentCardMastercard;

  my $plugin = Faker::Plugin::PaymentCardMastercard->new;

  # bless(..., "Faker::Plugin::PaymentCardMastercard")

  # my $result = $plugin->execute;

  # 521408446845507;

  # my $result = $plugin->execute;

  # 554544390898220;

  # my $result = $plugin->execute;

  # 540225828820558;

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::PaymentCardMastercard;

  my $plugin = Faker::Plugin::PaymentCardMastercard->new;

  # bless(..., "Faker::Plugin::PaymentCardMastercard")

=back

=cut