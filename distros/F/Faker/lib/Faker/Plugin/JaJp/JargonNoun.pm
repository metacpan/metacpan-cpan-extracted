package Faker::Plugin::JaJp::JargonNoun;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::JaJp';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->faker->random->select(data_for_jargon_noun());
}

sub data_for_jargon_noun {
  state $jargon_noun = [
    '相乗効果',
    'ウェブ対応',
    'パラダイム',
    '市場',
    'パートナーシップ',
    'インフラストラクチャ',
    'プラットフォーム',
    'イニシアチブ',
    'チャンネル',
    '眼球',
    'コミュニティ',
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::JargonNoun - Jargon Noun

=cut

=head1 ABSTRACT

Jargon Noun for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::JargonNoun;

  my $plugin = Faker::Plugin::JaJp::JargonNoun->new;

  # bless(..., "Faker::Plugin::JaJp::JargonNoun")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for jargon noun.

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

The execute method returns a returns a random fake jargon noun.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::JargonNoun;

  my $plugin = Faker::Plugin::JaJp::JargonNoun->new;

  # bless(..., "Faker::Plugin::JaJp::JargonNoun")

  # my $result = $plugin->execute;

  # '市場';

  # my $result = $plugin->execute;

  # 'パートナーシップ';

  # my $result = $plugin->execute;

  # '眼球';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::JargonNoun;

  my $plugin = Faker::Plugin::JaJp::JargonNoun->new;

  # bless(..., "Faker::Plugin::JaJp::JargonNoun")

=back

=cut