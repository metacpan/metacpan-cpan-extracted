package Faker::Plugin::EnUs::JargonVerb;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::EnUs';

# VERSION

our $VERSION = '1.19';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->faker->random->select(data_for_jargon_verb());
}

sub data_for_jargon_verb {
  state $jargon_verb = [
    'implement',
    'utilize',
    'integrate',
    'streamline',
    'optimize',
    'evolve',
    'transform',
    'embrace',
    'enable',
    'orchestrate',
    'leverage',
    'reinvent',
    'aggregate',
    'architect',
    'enhance',
    'incentivize',
    'morph',
    'empower',
    'envisioneer',
    'monetize',
    'harness',
    'facilitate',
    'seize',
    'disintermediate',
    'synergize',
    'strategize',
    'deploy',
    'brand',
    'grow',
    'target',
    'syndicate',
    'synthesize',
    'deliver',
    'mesh',
    'incubate',
    'engage',
    'maximize',
    'benchmark',
    'expedite',
    'reintermediate',
    'whiteboard',
    'visualize',
    'repurpose',
    'innovate',
    'scale',
    'unleash',
    'drive',
    'extend',
    'engineer',
    'revolutionize',
    'generate',
    'exploit',
    'transition',
    'e-enable',
    'iterate',
    'cultivate',
    'matrix',
    'productize',
    'redefine',
    'recontextualize',
  ]
}

1;



=head1 NAME

Faker::Plugin::EnUs::JargonVerb - Jargon Verb

=cut

=head1 ABSTRACT

Jargon Verb for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EnUs::JargonVerb;

  my $plugin = Faker::Plugin::EnUs::JargonVerb->new;

  # bless(..., "Faker::Plugin::EnUs::JargonVerb")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for jargon verb.

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

The execute method returns a returns a random fake jargon verb.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EnUs::JargonVerb;

  my $plugin = Faker::Plugin::EnUs::JargonVerb->new;

  # bless(..., "Faker::Plugin::EnUs::JargonVerb")

  # my $result = $plugin->execute;

  # "harness";

  # my $result = $plugin->execute;

  # "strategize";

  # my $result = $plugin->execute;

  # "exploit";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EnUs::JargonVerb;

  my $plugin = Faker::Plugin::EnUs::JargonVerb->new;

  # bless(..., "Faker::Plugin::EnUs::JargonVerb")

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