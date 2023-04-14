package Faker::Plugin::ColorRgbColorset;

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

  my $color = $self->faker->color_hex_code;

  my $colorset = [
    hex(substr($color, 1, 2)),
    hex(substr($color, 3, 2)),
    hex(substr($color, 5, 2)),
  ];

  return wantarray ? (@$colorset) : $colorset;
}

1;



=head1 NAME

Faker::Plugin::ColorRgbColorset - Color Rgb Colorset

=cut

=head1 ABSTRACT

Color Rgb Colorset for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::ColorRgbColorset;

  my $plugin = Faker::Plugin::ColorRgbColorset->new;

  # bless(..., "Faker::Plugin::ColorRgbColorset")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for color rgb colorset.

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

The execute method returns a returns a random fake color rgb colorset.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::ColorRgbColorset;

  my $plugin = Faker::Plugin::ColorRgbColorset->new;

  # bless(..., "Faker::Plugin::ColorRgbColorset")

  # my $result = $plugin->execute;

  # [28, 112, 22];

  # my $result = $plugin->execute;

  # [219, 63, 178];

  # my $result = $plugin->execute;

  # [176, 217, 21];

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::ColorRgbColorset;

  my $plugin = Faker::Plugin::ColorRgbColorset->new;

  # bless(..., "Faker::Plugin::ColorRgbColorset")

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