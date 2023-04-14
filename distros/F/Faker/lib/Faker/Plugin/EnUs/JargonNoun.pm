package Faker::Plugin::EnUs::JargonNoun;

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

  return $self->faker->random->select(data_for_jargon_noun());
}

sub data_for_jargon_noun {
  state $jargon_noun = [
    'synergies',
    'web-readiness',
    'paradigms',
    'markets',
    'partnerships',
    'infrastructures',
    'platforms',
    'initiatives',
    'channels',
    'eyeballs',
    'communities',
    'ROI',
    'solutions',
    'e-tailers',
    'e-services',
    'action-items',
    'portals',
    'niches',
    'technologies',
    'content',
    'vortals',
    'supply-chains',
    'convergence',
    'relationships',
    'architectures',
    'interfaces',
    'e-markets',
    'e-commerce',
    'systems',
    'bandwidth',
    'infomediaries',
    'models',
    'mindshare',
    'deliverables',
    'users',
    'schemas',
    'networks',
    'applications',
    'metrics',
    'e-business',
    'functionalities',
    'experiences',
    'webservices',
    'methodologies',
  ]
}

1;



=head1 NAME

Faker::Plugin::EnUs::JargonNoun - Jargon Noun

=cut

=head1 ABSTRACT

Jargon Noun for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EnUs::JargonNoun;

  my $plugin = Faker::Plugin::EnUs::JargonNoun->new;

  # bless(..., "Faker::Plugin::EnUs::JargonNoun")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for jargon noun.

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

The execute method returns a returns a random fake jargon noun.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EnUs::JargonNoun;

  my $plugin = Faker::Plugin::EnUs::JargonNoun->new;

  # bless(..., "Faker::Plugin::EnUs::JargonNoun")

  # my $result = $plugin->execute;

  # "action-items";

  # my $result = $plugin->execute;

  # "technologies";

  # my $result = $plugin->execute;

  # "applications";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EnUs::JargonNoun;

  my $plugin = Faker::Plugin::EnUs::JargonNoun->new;

  # bless(..., "Faker::Plugin::EnUs::JargonNoun")

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