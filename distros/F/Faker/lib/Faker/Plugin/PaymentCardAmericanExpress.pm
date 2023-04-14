package Faker::Plugin::PaymentCardAmericanExpress;

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
    $self->faker->random->select(data_for_payment_card_american_express()),
    'numbers',
  );
}

sub data_for_payment_card_american_express {
  state $payment_card_american_express = [
    '34############',
    '37############',
  ]
}

1;



=head1 NAME

Faker::Plugin::PaymentCardAmericanExpress - Payment Card American Express

=cut

=head1 ABSTRACT

Payment Card American Express for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::PaymentCardAmericanExpress;

  my $plugin = Faker::Plugin::PaymentCardAmericanExpress->new;

  # bless(..., "Faker::Plugin::PaymentCardAmericanExpress")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for payment card american express.

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

The execute method returns a returns a random fake payment card american express.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::PaymentCardAmericanExpress;

  my $plugin = Faker::Plugin::PaymentCardAmericanExpress->new;

  # bless(..., "Faker::Plugin::PaymentCardAmericanExpress")

  # my $result = $plugin->execute;

  # 34140844684550;

  # my $result = $plugin->execute;

  # 37945443908982;

  # my $result = $plugin->execute;

  # 34370225828820;

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::PaymentCardAmericanExpress;

  my $plugin = Faker::Plugin::PaymentCardAmericanExpress->new;

  # bless(..., "Faker::Plugin::PaymentCardAmericanExpress")

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