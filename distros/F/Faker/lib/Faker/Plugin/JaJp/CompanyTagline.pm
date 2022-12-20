package Faker::Plugin::JaJp::CompanyTagline;

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

  return join '',
    $self->faker->jargon_verb,
    $self->faker->jargon_adjective,
    $self->faker->jargon_noun,
}

1;



=head1 NAME

Faker::Plugin::JaJp::CompanyTagline - Company Tagline

=cut

=head1 ABSTRACT

Company Tagline for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::CompanyTagline;

  my $plugin = Faker::Plugin::JaJp::CompanyTagline->new;

  # bless(..., "Faker::Plugin::JaJp::CompanyTagline")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for company tagline.

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

The execute method returns a returns a random fake company tagline.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::CompanyTagline;

  my $plugin = Faker::Plugin::JaJp::CompanyTagline->new;

  # bless(..., "Faker::Plugin::JaJp::CompanyTagline")

  # my $result = $plugin->execute;

  # '利用する直感的インフラストラクチャ';

  # my $result = $plugin->execute;

  # 'オーケストレーションするスケーラブル相乗効果';

  # my $result = $plugin->execute;

  # 'オーケストレーションする革命的なパートナーシップ';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::CompanyTagline;

  my $plugin = Faker::Plugin::JaJp::CompanyTagline->new;

  # bless(..., "Faker::Plugin::JaJp::CompanyTagline")

=back

=cut