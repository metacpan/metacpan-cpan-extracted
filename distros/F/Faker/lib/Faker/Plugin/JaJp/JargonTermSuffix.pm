package Faker::Plugin::JaJp::JargonTermSuffix;

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

  return $self->faker->random->select(data_for_jargon_term_suffix());
}

sub data_for_jargon_term_suffix {
  state $jargon_term_suffix = [
    '能力',
    'アクセス',
    'アダプタ',
    'アルゴリズム',
    '同盟',
    'アナライザー',
    'アプリケーション',
    'アプローチ',
    'アーキテクチャ',
    'アーカイブ',
    '人工知能',
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::JargonTermSuffix - Jargon Term Suffix

=cut

=head1 ABSTRACT

Jargon Term Suffix for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::JargonTermSuffix;

  my $plugin = Faker::Plugin::JaJp::JargonTermSuffix->new;

  # bless(..., "Faker::Plugin::JaJp::JargonTermSuffix")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for jargon term suffix.

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

The execute method returns a returns a random fake jargon term suffix.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::JargonTermSuffix;

  my $plugin = Faker::Plugin::JaJp::JargonTermSuffix->new;

  # bless(..., "Faker::Plugin::JaJp::JargonTermSuffix")

  # my $result = $plugin->execute;

  # 'アルゴリズム';

  # my $result = $plugin->execute;

  # '同盟';

  # my $result = $plugin->execute;

  # 'アーカイブ';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::JargonTermSuffix;

  my $plugin = Faker::Plugin::JaJp::JargonTermSuffix->new;

  # bless(..., "Faker::Plugin::JaJp::JargonTermSuffix")

=back

=cut