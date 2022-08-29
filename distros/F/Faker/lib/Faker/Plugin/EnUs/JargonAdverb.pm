package Faker::Plugin::EnUs::JargonAdverb;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::EnUs';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->faker->random->select(data_for_jargon_adverb());
}

sub data_for_jargon_adverb {
  state $jargon_adverb = [
    'adaptive',
    'advanced',
    'ameliorated',
    'assimilated',
    'automated',
    'balanced',
    'business-focused',
    'centralized',
    'cloned',
    'compatible',
    'configurable',
    'cross-group',
    'cross-platform',
    'customer-focused',
    'customizable',
    'decentralized',
    'de-engineered',
    'devolved',
    'digitized',
    'distributed',
    'diverse',
    'down-sized',
    'enhanced',
    'enterprise-wide',
    'ergonomic',
    'exclusive',
    'expanded',
    'extended',
    'facetoface',
    'focused',
    'front-line',
    'fully-configurable',
    'function-based',
    'fundamental',
    'future-proofed',
    'grass-roots',
    'horizontal',
    'implemented',
    'innovative',
    'integrated',
    'intuitive',
    'inverse',
    'managed',
    'mandatory',
    'monitored',
    'multi-channelled',
    'multi-lateral',
    'multi-layered',
    'multi-tiered',
    'networked',
    'object-based',
    'open-architected',
    'open-source',
    'operative',
    'optimized',
    'optional',
    'organic',
    'organized',
    'persevering',
    'persistent',
    'phased',
    'polarised',
    'pre-emptive',
    'proactive',
    'profit-focused',
    'profound',
    'programmable',
    'progressive',
    'public-key',
    'quality-focused',
    'reactive',
    'realigned',
    're-contextualized',
    're-engineered',
    'reduced',
    'reverse-engineered',
    'right-sized',
    'robust',
    'seamless',
    'secured',
    'self-enabling',
    'sharable',
    'stand-alone',
    'streamlined',
    'switchable',
    'synchronised',
    'synergistic',
    'synergized',
    'team-oriented',
    'total',
    'triple-buffered',
    'universal',
    'up-sized',
    'upgradable',
    'user-centric',
    'user-friendly',
    'versatile',
    'virtual',
    'visionary',
    'vision-oriented',
  ]
}

1;



=head1 NAME

Faker::Plugin::EnUs::JargonAdverb - Jargon Adverb

=cut

=head1 ABSTRACT

Jargon Adverb for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EnUs::JargonAdverb;

  my $plugin = Faker::Plugin::EnUs::JargonAdverb->new;

  # bless(..., "Faker::Plugin::EnUs::JargonAdverb")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for jargon adverb.

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

The execute method returns a returns a random fake jargon adverb.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EnUs::JargonAdverb;

  my $plugin = Faker::Plugin::EnUs::JargonAdverb->new;

  # bless(..., "Faker::Plugin::EnUs::JargonAdverb")

  # my $result = $plugin->execute;

  # "future-proofed";

  # my $result = $plugin->execute;

  # "managed";

  # my $result = $plugin->execute;

  # "synchronised";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EnUs::JargonAdverb;

  my $plugin = Faker::Plugin::EnUs::JargonAdverb->new;

  # bless(..., "Faker::Plugin::EnUs::JargonAdverb")

=back

=cut