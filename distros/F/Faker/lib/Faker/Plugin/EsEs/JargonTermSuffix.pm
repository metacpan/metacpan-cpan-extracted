package Faker::Plugin::EsEs::JargonTermSuffix;

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

  return $self->faker->random->select(data_for_jargon_term_suffix());
}

sub data_for_jargon_term_suffix {
  state $jargon_term_suffix = [
    'abilities',
    'access',
    'adapters',
    'algorithms',
    'alliances',
    'analyzers',
    'applications',
    'approaches',
    'architectures',
    'archives',
    'artificial intelligence',
    'arrays',
    'attitudes',
    'benchmarks',
    'budgetary management',
    'capabilities',
    'capacities',
    'challenges',
    'circuits',
    'collaborations',
    'complexity',
    'concepts',
    'conglomeration',
    'contingencies',
    'cores',
    'customer loyalty',
    'databases',
    'data-warehouses',
    'definitions',
    'emulations',
    'encodings',
    'encryptions',
    'extranets',
    'firmwares',
    'flexibilities',
    'focus groups',
    'forecasts',
    'framings',
    'frameworks',
    'functions',
    'functionalities',
    'graphic interfaces',
    'groupware',
    'graphical user interfaces',
    'hardware',
    'help-desk',
    'hierarchies',
    'hubs',
    'implementations',
    'info-mediaries',
    'infrastructures',
    'initiatives',
    'installations',
    'instruction sets',
    'interfaces',
    'internet solutions',
    'intranets',
    'knowledge workers',
    'knowledgebases',
    'local area networks',
    'matrices',
    'methodologies',
    'middlewares',
    'migrations',
    'models',
    'moderators',
    'monitoring',
    'moratoriums',
    'neural-nets',
    'open architectures',
    'open systems',
    'orchestrations',
    'paradigms',
    'parallelism',
    'policies',
    'portals',
    'pricing structures',
    'process improvements',
    'products',
    'productivity',
    'projects',
    'projection',
    'protocols',
    'secured lines',
    'service-desks',
    'software',
    'solutions',
    'standardization',
    'strategies',
    'structures',
    'successes',
    'superstructures',
    'support',
    'synergies',
    'system engines',
    'task-forces',
    'throughput',
    'time-frames',
    'toolsets',
    'utilisation',
    'websites',
    'workforces',
  ]
}

1;



=head1 NAME

Faker::Plugin::EsEs::JargonTermSuffix - Jargon Term Suffix

=cut

=head1 ABSTRACT

Jargon Term Suffix for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EsEs::JargonTermSuffix;

  my $plugin = Faker::Plugin::EsEs::JargonTermSuffix->new;

  # bless(..., "Faker::Plugin::EsEs::JargonTermSuffix")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for jargon term suffix.

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

The execute method returns a returns a random fake jargon term suffix.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EsEs::JargonTermSuffix;

  my $plugin = Faker::Plugin::EsEs::JargonTermSuffix->new;

  # bless(..., "Faker::Plugin::EsEs::JargonTermSuffix")

  # my $result = $plugin->execute;

  # 'flexibilities';

  # my $result = $plugin->execute;

  # 'graphical user interfaces';

  # my $result = $plugin->execute;

  # 'standardization';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EsEs::JargonTermSuffix;

  my $plugin = Faker::Plugin::EsEs::JargonTermSuffix->new;

  # bless(..., "Faker::Plugin::EsEs::JargonTermSuffix")

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