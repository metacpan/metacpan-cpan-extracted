package Faker::Plugin::JaJp::AddressStreetName;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::JaJp';

# VERSION

our $VERSION = '1.19';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->process_format(
    $self->faker->random->select(data_for_address_street_name())
  );
}

sub data_for_address_street_name {
  state $address_street_name = [
    '{{person_last_name}}{{address_street_suffix}}',
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::AddressStreetName - Address Street Name

=cut

=head1 ABSTRACT

Address Street Name for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::AddressStreetName;

  my $plugin = Faker::Plugin::JaJp::AddressStreetName->new;

  # bless(..., "Faker::Plugin::JaJp::AddressStreetName")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address street name.

=encoding utf8

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Faker::Plugin::JaJp>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 execute

  execute(HashRef $data) (Str)

The execute method returns a returns a random fake address street name.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::AddressStreetName;

  my $plugin = Faker::Plugin::JaJp::AddressStreetName->new;

  # bless(..., "Faker::Plugin::JaJp::AddressStreetName")

  # my $result = $plugin->execute;

  # '井上町';

  # my $result = $plugin->execute;

  # '高橋町';

  # my $result = $plugin->execute;

  # '鈴木町';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::AddressStreetName;

  my $plugin = Faker::Plugin::JaJp::AddressStreetName->new;

  # bless(..., "Faker::Plugin::JaJp::AddressStreetName")

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