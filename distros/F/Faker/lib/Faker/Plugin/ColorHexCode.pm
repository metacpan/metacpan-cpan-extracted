package Faker::Plugin::ColorHexCode;

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

  my $number = $self->faker->random->range(1, 16777215);

  return '#' . sprintf('%06s', sprintf('%02x', $number));
}

1;



=head1 NAME

Faker::Plugin::ColorHexCode - Color Hex Code

=cut

=head1 ABSTRACT

Color Hex Code for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::ColorHexCode;

  my $plugin = Faker::Plugin::ColorHexCode->new;

  # bless(..., "Faker::Plugin::ColorHexCode")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for color hex code.

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

The execute method returns a returns a random fake color hex code.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::ColorHexCode;

  my $plugin = Faker::Plugin::ColorHexCode->new;

  # bless(..., "Faker::Plugin::ColorHexCode")

  # my $result = $plugin->execute;

  # "#57bb49";

  # my $result = $plugin->execute;

  # "#6c1e68";

  # my $result = $plugin->execute;

  # "#db3fb2";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::ColorHexCode;

  my $plugin = Faker::Plugin::ColorHexCode->new;

  # bless(..., "Faker::Plugin::ColorHexCode")

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