package Faker::Plugin::ColorSafeName;

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

  return $self->faker->random->select(data_for_color_safe_name());
}

sub data_for_color_safe_name {
  state $color_safe_name = [
    'black',
    'maroon',
    'green',
    'navy',
    'olive',
    'purple',
    'teal',
    'lime',
    'blue',
    'silver',
    'gray',
    'yellow',
    'fuchsia',
    'aqua',
    'white',
  ]
}

1;



=head1 NAME

Faker::Plugin::ColorSafeName - Color Safe Name

=cut

=head1 ABSTRACT

Color Safe Name for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::ColorSafeName;

  my $plugin = Faker::Plugin::ColorSafeName->new;

  # bless(..., "Faker::Plugin::ColorSafeName")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for color safe name.

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

The execute method returns a returns a random fake color safe name.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::ColorSafeName;

  my $plugin = Faker::Plugin::ColorSafeName->new;

  # bless(..., "Faker::Plugin::ColorSafeName")

  # my $result = $plugin->execute;

  # "purple";

  # my $result = $plugin->execute;

  # "teal";

  # my $result = $plugin->execute;

  # "fuchsia";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::ColorSafeName;

  my $plugin = Faker::Plugin::ColorSafeName->new;

  # bless(..., "Faker::Plugin::ColorSafeName")

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