package Faker::Plugin::PaymentCardVisa;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin';

# VERSION

our $VERSION = '1.19';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->process_markers(
    $self->faker->random->select(data_for_payment_card_visa()),
    'numbers',
  );
}

sub data_for_payment_card_visa {
  state $payment_card_visa = [
    '4539########',
    '4539###########',
    '4556########',
    '4556###########',
    '4916########',
    '4916###########',
    '4532########',
    '4532###########',
    '4929########',
    '4929###########',
    '40240071####',
    '40240071#######',
    '4485########',
    '4485###########',
    '4716########',
    '4716###########',
    '4###########',
    '4##############',
  ]
}

1;



=head1 NAME

Faker::Plugin::PaymentCardVisa - Payment Card Visa

=cut

=head1 ABSTRACT

Payment Card Visa for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::PaymentCardVisa;

  my $plugin = Faker::Plugin::PaymentCardVisa->new;

  # bless(..., "Faker::Plugin::PaymentCardVisa")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for payment card visa.

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

The execute method returns a returns a random fake payment card visa.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::PaymentCardVisa;

  my $plugin = Faker::Plugin::PaymentCardVisa->new;

  # bless(..., "Faker::Plugin::PaymentCardVisa")

  # my $result = $plugin->execute;

  # 453214084468;

  # my $result = $plugin->execute;

  # 402400715076;

  # my $result = $plugin->execute;

  # 492954439089;

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::PaymentCardVisa;

  my $plugin = Faker::Plugin::PaymentCardVisa->new;

  # bless(..., "Faker::Plugin::PaymentCardVisa")

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2000, Al Newkirk.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut