package Faker::Plugin::PaymentCardExpiration;

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

  my $pad = $self->faker->random->range(1,3);
  my $month = sprintf('%02d', $self->faker->random->range(1,12));
  my $year = sprintf('%02d', ((localtime)[5] % 100) + $pad);

  return "$month/$year";
}

1;



=head1 NAME

Faker::Plugin::PaymentCardExpiration - Payment Card Expiration

=cut

=head1 ABSTRACT

Payment Card Expiration for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::PaymentCardExpiration;

  my $plugin = Faker::Plugin::PaymentCardExpiration->new;

  # bless(..., "Faker::Plugin::PaymentCardExpiration")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for payment card expiration.

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

The execute method returns a returns a random fake payment card expiration.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::PaymentCardExpiration;

  my $plugin = Faker::Plugin::PaymentCardExpiration->new;

  # bless(..., "Faker::Plugin::PaymentCardExpiration")

  # my $result = $plugin->execute;

  # "02/24";

  # my $result = $plugin->execute;

  # "11/23";

  # my $result = $plugin->execute;

  # "09/24";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::PaymentCardExpiration;

  my $plugin = Faker::Plugin::PaymentCardExpiration->new;

  # bless(..., "Faker::Plugin::PaymentCardExpiration")

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