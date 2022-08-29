package Faker::Plugin::InternetIpAddressV4;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin';

# METHODS

sub execute {
  my ($self, $data) = @_;

  my $random = $self->faker->random;

  return join '.',
    $random->range(0, 255),
    $random->range(0, 255),
    $random->range(0, 255),
    $random->range(0, 255);
}

1;



=head1 NAME

Faker::Plugin::InternetIpAddressV4 - Internet Ip Address V4

=cut

=head1 ABSTRACT

Internet Ip Address V4 for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::InternetIpAddressV4;

  my $plugin = Faker::Plugin::InternetIpAddressV4->new;

  # bless(..., "Faker::Plugin::InternetIpAddressV4")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for internet ip address v4.

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

The execute method returns a returns a random fake internet ip address v4.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::InternetIpAddressV4;

  my $plugin = Faker::Plugin::InternetIpAddressV4->new;

  # bless(..., "Faker::Plugin::InternetIpAddressV4")

  # my $result = $plugin->execute;

  # "87.28.108.20";

  # my $result = $plugin->execute;

  # "127.122.176.213";

  # my $result = $plugin->execute;

  # "147.136.6.197";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::InternetIpAddressV4;

  my $plugin = Faker::Plugin::InternetIpAddressV4->new;

  # bless(..., "Faker::Plugin::InternetIpAddressV4")

=back

=cut