package Faker::Plugin::EnUs::AddressLine2;

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
    $self->faker->random->select(data_for_address_line2()),
    'letters',
    'numbers',
  );
}

sub data_for_address_line2 {
  state $address_line2 = [
    'Apt. ###',
    'Apt. ###',
    'Apt. ##',
    'Apt. #',
    'Mailbox ####',
    'Mailbox ###',
    'Suite ###',
    'Suite ##',
    'Suite #',
    'Unit ###',
    'Unit ##',
    'Unit #',
  ]
}

1;



=head1 NAME

Faker::Plugin::EnUs::AddressLine2 - Address Line2

=cut

=head1 ABSTRACT

Address Line2 for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EnUs::AddressLine2;

  my $plugin = Faker::Plugin::EnUs::AddressLine2->new;

  # bless(..., "Faker::Plugin::EnUs::AddressLine2")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address line2.

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

The execute method returns a returns a random fake address line2.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EnUs::AddressLine2;

  my $plugin = Faker::Plugin::EnUs::AddressLine2->new;

  # bless(..., "Faker::Plugin::EnUs::AddressLine2")

  # my $result = $plugin->execute;

  # "Mailbox 1408";

  # my $result = $plugin->execute;

  # "Mailbox 684";

  # my $result = $plugin->execute;

  # "Suite 076";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EnUs::AddressLine2;

  my $plugin = Faker::Plugin::EnUs::AddressLine2->new;

  # bless(..., "Faker::Plugin::EnUs::AddressLine2")

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