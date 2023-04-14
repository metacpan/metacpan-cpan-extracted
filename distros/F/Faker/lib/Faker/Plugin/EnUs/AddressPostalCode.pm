package Faker::Plugin::EnUs::AddressPostalCode;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::EnUs';

# VERSION

our $VERSION = '1.19';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->process_markers(
    $self->faker->random->select(data_for_address_postal_code()),
    'numbers',
  );
}

sub data_for_address_postal_code {
  state $address_postal_code = [
    '#####',
    '#####-####',
  ]
}

1;



=head1 NAME

Faker::Plugin::EnUs::AddressPostalCode - Address Postal Code

=cut

=head1 ABSTRACT

Address Postal Code for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EnUs::AddressPostalCode;

  my $plugin = Faker::Plugin::EnUs::AddressPostalCode->new;

  # bless(..., "Faker::Plugin::EnUs::AddressPostalCode")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address postal code.

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

The execute method returns a returns a random fake address postal code.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EnUs::AddressPostalCode;

  my $plugin = Faker::Plugin::EnUs::AddressPostalCode->new;

  # bless(..., "Faker::Plugin::EnUs::AddressPostalCode")

  # my $result = $plugin->execute;

  # 14084;

  # my $result = $plugin->execute;

  # "84550-7694";

  # my $result = $plugin->execute;

  # 43908;

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EnUs::AddressPostalCode;

  my $plugin = Faker::Plugin::EnUs::AddressPostalCode->new;

  # bless(..., "Faker::Plugin::EnUs::AddressPostalCode")

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