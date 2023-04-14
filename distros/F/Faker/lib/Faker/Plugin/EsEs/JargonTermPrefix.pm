package Faker::Plugin::EsEs::JargonTermPrefix;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::EsEs';

# VERSION

our $VERSION = '1.19';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->faker->random->select(data_for_jargon_term_prefix());
}

sub data_for_jargon_term_prefix {
  state $jargon_term_prefix = [
    '24 hour',
    '24/7',
    '3rd-generation',
    '4th-generation',
    '5th-generation',
    '6th-generation',
    'actuating',
    'analyzing',
    'assymetric',
    'asynchronous',
    'attitude-oriented',
    'background',
    'bandwidth-monitored',
    'bi-directional',
    'bifurcated',
    'bottom-line',
    'clear-thinking',
    'client-driven',
    'client-server',
    'coherent',
    'cohesive',
    'composite',
    'context-sensitive',
    'contextually-based',
    'content-based',
    'dedicated',
    'demand-driven',
    'didactic',
    'directional',
    'discrete',
    'disintermediate',
    'dynamic',
    'eco-centric',
    'empowering',
    'encompassing',
    'even-keeled',
    'executive',
    'explicit',
    'exuding',
    'fault-tolerant',
    'foreground',
    'fresh-thinking',
    'full-range',
    'global',
    'grid-enabled',
    'heuristic',
    'high-level',
    'holistic',
    'homogeneous',
    'human-resource',
    'hybrid',
    'impactful',
    'incremental',
    'intangible',
    'interactive',
    'intermediate',
    'leadingedge',
    'local',
    'logistical',
    'maximized',
    'methodical',
    'mission-critical',
    'mobile',
    'modular',
    'motivating',
    'multimedia',
    'multi-state',
    'multi-tasking',
    'national',
    'needs-based',
    'neutral',
    'next-generation',
    'non-volatile',
    'object-oriented',
    'optimal',
    'optimizing',
    'radical',
    'real-time',
    'reciprocal',
    'regional',
    'responsive',
    'scalable',
    'secondary',
    'solution-oriented',
    'stable',
    'static',
    'systematic',
    'systemic',
    'system-worthy',
    'tangible',
    'tertiary',
    'transitional',
    'uniform',
    'upward-trending',
    'user-facing',
    'value-added',
    'web-enabled',
    'well-modulated',
    'zero-administration',
    'zero-defect',
    'zero-tolerance',
  ]
}

1;



=head1 NAME

Faker::Plugin::EsEs::JargonTermPrefix - Jargon Term Prefix

=cut

=head1 ABSTRACT

Jargon Term Prefix for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EsEs::JargonTermPrefix;

  my $plugin = Faker::Plugin::EsEs::JargonTermPrefix->new;

  # bless(..., "Faker::Plugin::EsEs::JargonTermPrefix")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for jargon term prefix.

=encoding utf8

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Faker::Plugin::EsEs>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 execute

  execute(HashRef $data) (Str)

The execute method returns a returns a random fake jargon term prefix.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EsEs::JargonTermPrefix;

  my $plugin = Faker::Plugin::EsEs::JargonTermPrefix->new;

  # bless(..., "Faker::Plugin::EsEs::JargonTermPrefix")

  # my $result = $plugin->execute;

  # 'encompassing';

  # my $result = $plugin->execute;

  # 'full-range';

  # my $result = $plugin->execute;

  # 'systematic';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EsEs::JargonTermPrefix;

  my $plugin = Faker::Plugin::EsEs::JargonTermPrefix->new;

  # bless(..., "Faker::Plugin::EsEs::JargonTermPrefix")

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