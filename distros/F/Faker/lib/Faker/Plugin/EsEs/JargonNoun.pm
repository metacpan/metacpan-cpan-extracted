package Faker::Plugin::EsEs::JargonNoun;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::EsEs';

# VERSION

our $VERSION = '1.17';

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

Faker::Plugin::EsEs::JargonNoun - Jargon Noun

=cut

=head1 ABSTRACT

Jargon Noun for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EsEs::JargonNoun;

  my $plugin = Faker::Plugin::EsEs::JargonNoun->new;

  # bless(..., "Faker::Plugin::EsEs::JargonNoun")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for jargon noun.

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

The execute method returns a returns a random fake jargon noun.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EsEs::JargonNoun;

  my $plugin = Faker::Plugin::EsEs::JargonNoun->new;

  # bless(..., "Faker::Plugin::EsEs::JargonNoun")

  # my $result = $plugin->execute;

  # 'action-items';

  # my $result = $plugin->execute;

  # 'technologies';

  # my $result = $plugin->execute;

  # 'applications';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EsEs::JargonNoun;

  my $plugin = Faker::Plugin::EsEs::JargonNoun->new;

  # bless(..., "Faker::Plugin::EsEs::JargonNoun")

=back

=cut