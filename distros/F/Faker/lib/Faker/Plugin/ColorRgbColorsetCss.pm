package Faker::Plugin::ColorRgbColorsetCss;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin';

# VERSION

our $VERSION = '1.17';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return sprintf 'rgb(%s)', join ', ', $self->faker->color_rgb_colorset;
}

1;



=head1 NAME

Faker::Plugin::ColorRgbColorsetCss - Color Rgb Colorset Css

=cut

=head1 ABSTRACT

Color Rgb Colorset Css for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::ColorRgbColorsetCss;

  my $plugin = Faker::Plugin::ColorRgbColorsetCss->new;

  # bless(..., "Faker::Plugin::ColorRgbColorsetCss")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for color rgb colorset css.

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

The execute method returns a returns a random fake color rgb colorset css.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::ColorRgbColorsetCss;

  my $plugin = Faker::Plugin::ColorRgbColorsetCss->new;

  # bless(..., "Faker::Plugin::ColorRgbColorsetCss")

  # my $result = $plugin->execute;

  # "rgb(108, 30, 104)";

  # my $result = $plugin->execute;

  # "rgb(122, 147, 147)";

  # my $result = $plugin->execute;

  # "rgb(147, 224, 22)";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::ColorRgbColorsetCss;

  my $plugin = Faker::Plugin::ColorRgbColorsetCss->new;

  # bless(..., "Faker::Plugin::ColorRgbColorsetCss")

=back

=cut