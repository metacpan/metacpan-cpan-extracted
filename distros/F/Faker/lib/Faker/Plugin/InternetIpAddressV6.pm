package Faker::Plugin::InternetIpAddressV6;

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

  my $random = $self->faker->random;

  return join ':',
    sprintf('%04s', sprintf("%02x", $random->range(0, 65535))),
    sprintf('%04s', sprintf("%02x", $random->range(0, 65535))),
    sprintf('%04s', sprintf("%02x", $random->range(0, 65535))),
    sprintf('%04s', sprintf("%02x", $random->range(0, 65535))),
    sprintf('%04s', sprintf("%02x", $random->range(0, 65535))),
    sprintf('%04s', sprintf("%02x", $random->range(0, 65535))),
    sprintf('%04s', sprintf("%02x", $random->range(0, 65535))),
    sprintf('%04s', sprintf("%02x", $random->range(0, 65535)));
}

1;



=head1 NAME

Faker::Plugin::InternetIpAddressV6 - Internet Ip Address V6

=cut

=head1 ABSTRACT

Internet Ip Address V6 for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::InternetIpAddressV6;

  my $plugin = Faker::Plugin::InternetIpAddressV6->new;

  # bless(..., "Faker::Plugin::InternetIpAddressV6")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for internet ip address v6.

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

The execute method returns a returns a random fake internet ip address v6.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::InternetIpAddressV6;

  my $plugin = Faker::Plugin::InternetIpAddressV6->new;

  # bless(..., "Faker::Plugin::InternetIpAddressV6")

  # my $result = $plugin->execute;

  # "57bb:1c70:6c1e:14c3:db3f:7fb1:7a93:b0d9";

  # my $result = $plugin->execute;

  # "7680:93e0:88b2:06a0:c512:99e4:e8a9:7d48";

  # my $result = $plugin->execute;

  # "7f27:7009:5984:ec03:0f75:dc22:f8d4:d951";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::InternetIpAddressV6;

  my $plugin = Faker::Plugin::InternetIpAddressV6->new;

  # bless(..., "Faker::Plugin::InternetIpAddressV6")

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