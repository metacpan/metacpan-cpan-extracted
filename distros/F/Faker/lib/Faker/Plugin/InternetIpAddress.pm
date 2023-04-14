package Faker::Plugin::InternetIpAddress;

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

  return $self->faker->random->bit
    ? $self->faker->internet_ip_address_v4
    : $self->faker->internet_ip_address_v6;
}

1;



=head1 NAME

Faker::Plugin::InternetIpAddress - Internet Ip Address

=cut

=head1 ABSTRACT

Internet Ip Address for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::InternetIpAddress;

  my $plugin = Faker::Plugin::InternetIpAddress->new;

  # bless(..., "Faker::Plugin::InternetIpAddress")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for internet ip address.

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

The execute method returns a returns a random fake internet ip address.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::InternetIpAddress;

  my $plugin = Faker::Plugin::InternetIpAddress->new;

  # bless(..., "Faker::Plugin::InternetIpAddress")

  # my $result = $plugin->execute;

  # "108.20.219.127";

  # my $result = $plugin->execute;

  # "7680:93e0:88b2:06a0:c512:99e4:e8a9:7d48";

  # my $result = $plugin->execute;

  # "89.236.15.220";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::InternetIpAddress;

  my $plugin = Faker::Plugin::InternetIpAddress->new;

  # bless(..., "Faker::Plugin::InternetIpAddress")

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