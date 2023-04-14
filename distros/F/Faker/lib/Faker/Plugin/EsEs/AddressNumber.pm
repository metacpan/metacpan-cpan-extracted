package Faker::Plugin::EsEs::AddressNumber;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::EsEs';

# VERSION

our $VERSION = '1.19';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->process_markers(
    $self->faker->random->select(data_for_address_number()),
    'numbers',
  );
}

sub data_for_address_number {
  state $address_number = [
    '###',
    '##',
    '#',
  ]
}

1;



=head1 NAME

Faker::Plugin::EsEs::AddressNumber - Address Number

=cut

=head1 ABSTRACT

Address Number for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EsEs::AddressNumber;

  my $plugin = Faker::Plugin::EsEs::AddressNumber->new;

  # bless(..., "Faker::Plugin::EsEs::AddressNumber")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address number.

=encoding utf8

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Faker::Plugin::EsEs>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 execute

  execute(HashRef $data) (Str)

The execute method returns a returns a random fake address number.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EsEs::AddressNumber;

  my $plugin = Faker::Plugin::EsEs::AddressNumber->new;

  # bless(..., "Faker::Plugin::EsEs::AddressNumber")

  # my $result = $plugin->execute;

  # '14';

  # my $result = $plugin->execute;

  # '4';

  # my $result = $plugin->execute;

  # '8';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EsEs::AddressNumber;

  my $plugin = Faker::Plugin::EsEs::AddressNumber->new;

  # bless(..., "Faker::Plugin::EsEs::AddressNumber")

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