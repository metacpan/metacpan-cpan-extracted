package Faker::Plugin::EsEs::CompanyTagline;

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

  return join ' ',
    $self->faker->jargon_verb,
    $self->faker->jargon_adjective,
    $self->faker->jargon_noun,
}

1;



=head1 NAME

Faker::Plugin::EsEs::CompanyTagline - Company Tagline

=cut

=head1 ABSTRACT

Company Tagline for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EsEs::CompanyTagline;

  my $plugin = Faker::Plugin::EsEs::CompanyTagline->new;

  # bless(..., "Faker::Plugin::EsEs::CompanyTagline")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for company tagline.

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

The execute method returns a returns a random fake company tagline.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EsEs::CompanyTagline;

  my $plugin = Faker::Plugin::EsEs::CompanyTagline->new;

  # bless(..., "Faker::Plugin::EsEs::CompanyTagline")

  # my $result = $plugin->execute;

  # 'transform revolutionary supply-chains';

  # my $result = $plugin->execute;

  # 'generate front-end web-readiness';

  # my $result = $plugin->execute;

  # 'iterate back-end content';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EsEs::CompanyTagline;

  my $plugin = Faker::Plugin::EsEs::CompanyTagline->new;

  # bless(..., "Faker::Plugin::EsEs::CompanyTagline")

=back

=cut