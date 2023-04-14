package Faker::Plugin::EsEs::TelephoneNumber;

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

  my $method = $self->faker->random->select(
    [
      'data_for_telephone_number',
      'data_for_telephone_number_mobile',
      'data_for_telephone_number_tollfree'
    ]
  );

  return $self->process_markers(
    $self->faker->random->select($self->$method),
    'numbers'
  );
}

sub data_for_telephone_number {
  state $telephone_number = [
    '+34 9## ## ####',
    '+34 9## ######',
    '+34 9########',
    '+34 9##-##-####',
    '+34 9##-######',
    '9## ## ####',
    '9## ######',
    '9########',
    '9##-##-####',
    '9##-######',
  ]
}

sub data_for_telephone_number_mobile {
  state $telephone_number = [
    '+34 6## ## ####',
    '+34 6## ######',
    '+34 6########',
    '+34 6##-##-####',
    '+34 6##-######',
    '6## ## ####',
    '6## ######',
    '6########',
    '6##-##-####',
    '6##-######',
  ]
}

sub data_for_telephone_number_tollfree {
  state $telephone_number = [
    '900 ### ###',
    '800 ### ###',
  ]
}

1;



=head1 NAME

Faker::Plugin::EsEs::TelephoneNumber - Telephone Number

=cut

=head1 ABSTRACT

Telephone Number for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EsEs::TelephoneNumber;

  my $plugin = Faker::Plugin::EsEs::TelephoneNumber->new;

  # bless(..., "Faker::Plugin::EsEs::TelephoneNumber")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for telephone number.

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

The execute method returns a returns a random fake telephone number.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EsEs::TelephoneNumber;

  my $plugin = Faker::Plugin::EsEs::TelephoneNumber->new;

  # bless(..., "Faker::Plugin::EsEs::TelephoneNumber")

  # my $result = $plugin->execute;

  # '+34 640 844684';

  # my $result = $plugin->execute;

  # '+34 676 94 5443';

  # my $result = $plugin->execute;

  # '998-22-0370';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EsEs::TelephoneNumber;

  my $plugin = Faker::Plugin::EsEs::TelephoneNumber->new;

  # bless(..., "Faker::Plugin::EsEs::TelephoneNumber")

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