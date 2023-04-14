package Faker::Plugin::JaJp::AddressNumber;

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

  return $self->faker->random->range(101, 110);
}

1;



=head1 NAME

Faker::Plugin::JaJp::AddressNumber - Address Number

=cut

=head1 ABSTRACT

Address Number for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::AddressNumber;

  my $plugin = Faker::Plugin::JaJp::AddressNumber->new;

  # bless(..., "Faker::Plugin::JaJp::AddressNumber")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address number.

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

The execute method returns a returns a random fake address number.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::AddressNumber;

  my $plugin = Faker::Plugin::JaJp::AddressNumber->new;

  # bless(..., "Faker::Plugin::JaJp::AddressNumber")

  # my $result = $plugin->execute;

  # 104;

  # my $result = $plugin->execute;

  # 105;

  # my $result = $plugin->execute;

  # 109;

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::AddressNumber;

  my $plugin = Faker::Plugin::JaJp::AddressNumber->new;

  # bless(..., "Faker::Plugin::JaJp::AddressNumber")

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