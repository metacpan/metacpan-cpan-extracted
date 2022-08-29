package Faker::Plugin::PaymentCardDiscover;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->process_markers(
    $self->faker->random->select(data_for_payment_card_discover()),
    'numbers',
  );
}

sub data_for_payment_card_discover {
  state $payment_card_discover = [
    '6011###########',
  ]
}

1;



=head1 NAME

Faker::Plugin::PaymentCardDiscover - Payment Card Discover

=cut

=head1 ABSTRACT

Payment Card Discover for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::PaymentCardDiscover;

  my $plugin = Faker::Plugin::PaymentCardDiscover->new;

  # bless(..., "Faker::Plugin::PaymentCardDiscover")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for payment card discover.

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

The execute method returns a returns a random fake payment card discover.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::PaymentCardDiscover;

  my $plugin = Faker::Plugin::PaymentCardDiscover->new;

  # bless(..., "Faker::Plugin::PaymentCardDiscover")

  # my $result = $plugin->execute;

  # 601131408446845;

  # my $result = $plugin->execute;

  # 601107694544390;

  # my $result = $plugin->execute;

  # 601198220370225;

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::PaymentCardDiscover;

  my $plugin = Faker::Plugin::PaymentCardDiscover->new;

  # bless(..., "Faker::Plugin::PaymentCardDiscover")

=back

=cut