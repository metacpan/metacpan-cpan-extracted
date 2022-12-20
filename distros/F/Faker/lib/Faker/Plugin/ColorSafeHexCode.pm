package Faker::Plugin::ColorSafeHexCode;

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

  my $number = $self->faker->random->range(0, 255);

  return '#' . sprintf("ff00%02x", $number);
}

1;



=head1 NAME

Faker::Plugin::ColorSafeHexCode - Color Safe Hex Code

=cut

=head1 ABSTRACT

Color Safe Hex Code for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::ColorSafeHexCode;

  my $plugin = Faker::Plugin::ColorSafeHexCode->new;

  # bless(..., "Faker::Plugin::ColorSafeHexCode")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for color safe hex code.

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

The execute method returns a returns a random fake color safe hex code.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::ColorSafeHexCode;

  my $plugin = Faker::Plugin::ColorSafeHexCode->new;

  # bless(..., "Faker::Plugin::ColorSafeHexCode")

  # my $result = $plugin->execute;

  # "#ff0057";

  # my $result = $plugin->execute;

  # "#ff006c";

  # my $result = $plugin->execute;

  # "#ff00db";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::ColorSafeHexCode;

  my $plugin = Faker::Plugin::ColorSafeHexCode->new;

  # bless(..., "Faker::Plugin::ColorSafeHexCode")

=back

=cut