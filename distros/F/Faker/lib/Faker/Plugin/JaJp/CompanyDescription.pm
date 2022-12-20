package Faker::Plugin::JaJp::CompanyDescription;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::JaJp';

# VERSION

our $VERSION = '1.17';

# METHODS

sub execute {
  my ($self, $data) = @_;

  my $does = $self->faker->random->select([
    '配達します',
    '募集',
    '提供する',
  ]);

  return join '', $does,
    $self->faker->jargon_term_prefix,
    $self->faker->jargon_adverb,
    $self->faker->jargon_term_suffix;
}

1;



=head1 NAME

Faker::Plugin::JaJp::CompanyDescription - Company Description

=cut

=head1 ABSTRACT

Company Description for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::CompanyDescription;

  my $plugin = Faker::Plugin::JaJp::CompanyDescription->new;

  # bless(..., "Faker::Plugin::JaJp::CompanyDescription")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for company description.

=encoding utf8

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Faker::Plugin::JaJp>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 execute

  execute(HashRef $data) (Str)

The execute method returns a returns a random fake company description.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::CompanyDescription;

  my $plugin = Faker::Plugin::JaJp::CompanyDescription->new;

  # bless(..., "Faker::Plugin::JaJp::CompanyDescription")

  # my $result = $plugin->execute;

  # '募集明示的互換性アナライザー';

  # my $result = $plugin->execute;

  # '提供する耐障害性アダプティブアプリケーション';

  # my $result = $plugin->execute;

  # '募集にじみ出る同化した能力';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::CompanyDescription;

  my $plugin = Faker::Plugin::JaJp::CompanyDescription->new;

  # bless(..., "Faker::Plugin::JaJp::CompanyDescription")

=back

=cut