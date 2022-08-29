package Faker::Plugin::EnUs::JargonAdjective;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::EnUs';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->faker->random->select(data_for_jargon_adjective());
}

sub data_for_jargon_adjective {
  state $jargon_adjective = [
    'clicks-and-mortar',
    'value-added',
    'vertical',
    'proactive',
    'robust',
    'revolutionary',
    'scalable',
    'leading-edge',
    'innovative',
    'intuitive',
    'strategic',
    'e-business',
    'mission-critical',
    'sticky',
    'one-to-one',
    '24/7',
    'end-to-end',
    'global',
    'B2B',
    'B2C',
    'granular',
    'frictionless',
    'virtual',
    'viral',
    'dynamic',
    '24/365',
    'best-of-breed',
    'killer',
    'magnetic',
    'bleeding-edge',
    'web-enabled',
    'interactive',
    'dot-com',
    'sexy',
    'back-end',
    'real-time',
    'efficient',
    'front-end',
    'distributed',
    'seamless',
    'extensible',
    'turn-key',
    'world-class',
    'open-source',
    'cross-platform',
    'cross-media',
    'synergistic',
    'bricks-and-clicks',
    'out-of-the-box',
    'enterprise',
    'integrated',
    'impactful',
    'wireless',
    'transparent',
    'next-generation',
    'cutting-edge',
    'user-centric',
    'visionary',
    'customized',
    'ubiquitous',
    'plug-and-play',
    'collaborative',
    'compelling',
    'holistic',
    'rich',
  ]
}

1;



=head1 NAME

Faker::Plugin::EnUs::JargonAdjective - Jargon Adjective

=cut

=head1 ABSTRACT

Jargon Adjective for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EnUs::JargonAdjective;

  my $plugin = Faker::Plugin::EnUs::JargonAdjective->new;

  # bless(..., "Faker::Plugin::EnUs::JargonAdjective")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for jargon adjective.

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

The execute method returns a returns a random fake jargon adjective.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EnUs::JargonAdjective;

  my $plugin = Faker::Plugin::EnUs::JargonAdjective->new;

  # bless(..., "Faker::Plugin::EnUs::JargonAdjective")

  # my $result = $plugin->execute;

  # "virtual";

  # my $result = $plugin->execute;

  # "killer";

  # my $result = $plugin->execute;

  # "cutting-edge";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EnUs::JargonAdjective;

  my $plugin = Faker::Plugin::EnUs::JargonAdjective->new;

  # bless(..., "Faker::Plugin::EnUs::JargonAdjective")

=back

=cut