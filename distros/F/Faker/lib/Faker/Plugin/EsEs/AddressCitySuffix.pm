package Faker::Plugin::EsEs::AddressCitySuffix;

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

  return $self->faker->random->select(data_for_address_city_suffix());
}

sub data_for_address_city_suffix {
  state $address_city_suffix = [
    'del Vallès',
    'del Penedès',
    'del Bages',
    'de Ulla',
    'de Lemos',
    'del Mirador',
    'de Arriba',
    'de la Sierra',
    'del Barco',
    'de San Pedro',
    'del Pozo',
    'del Puerto',
    'de las Torres',
    'Alta',
    'Baja',
    'Medio',
  ]
}

1;



=head1 NAME

Faker::Plugin::EsEs::AddressCitySuffix - Address City Suffix

=cut

=head1 ABSTRACT

Address City Suffix for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EsEs::AddressCitySuffix;

  my $plugin = Faker::Plugin::EsEs::AddressCitySuffix->new;

  # bless(..., "Faker::Plugin::EsEs::AddressCitySuffix")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address city suffix.

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

The execute method returns a returns a random fake address city suffix.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EsEs::AddressCitySuffix;

  my $plugin = Faker::Plugin::EsEs::AddressCitySuffix->new;

  # bless(..., "Faker::Plugin::EsEs::AddressCitySuffix")

  # my $result = $plugin->execute;

  # 'del Mirador';

  # my $result = $plugin->execute;

  # 'de Arriba';

  # my $result = $plugin->execute;

  # 'Alta';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EsEs::AddressCitySuffix;

  my $plugin = Faker::Plugin::EsEs::AddressCitySuffix->new;

  # bless(..., "Faker::Plugin::EsEs::AddressCitySuffix")

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