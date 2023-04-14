package Faker::Plugin::JaJp::AddressLine1;

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
    $self->faker->random->select(data_for_address_line1())
  );
}

sub data_for_address_line1 {
  state $address_line1 = [
    '{{address_postal_code}}  {{address_prefecture}}{{address_city_name}}{{address_ward}}{{address_street_address}}',
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::AddressLine1 - Address Line1

=cut

=head1 ABSTRACT

Address Line1 for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::AddressLine1;

  my $plugin = Faker::Plugin::JaJp::AddressLine1->new;

  # bless(..., "Faker::Plugin::JaJp::AddressLine1")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address line1.

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

The execute method returns a returns a random fake address line1.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::AddressLine1;

  my $plugin = Faker::Plugin::JaJp::AddressLine1->new;

  # bless(..., "Faker::Plugin::JaJp::AddressLine1")

  # my $result = $plugin->execute;

  # '1994801  佐賀県原田市東中村町田辺5-10-9';

  # my $result = $plugin->execute;

  # '3262852  新潟県桐山市西加納町田中10-6-3';

  # my $result = $plugin->execute;

  # '2722220  京都府宮沢市北佐々木町喜嶋4-2-2';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::AddressLine1;

  my $plugin = Faker::Plugin::JaJp::AddressLine1->new;

  # bless(..., "Faker::Plugin::JaJp::AddressLine1")

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