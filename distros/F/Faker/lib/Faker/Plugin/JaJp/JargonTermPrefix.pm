package Faker::Plugin::JaJp::JargonTermPrefix;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::JaJp';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->faker->random->select(data_for_jargon_term_prefix());
}

sub data_for_jargon_term_prefix {
  state $jargon_term_prefix = [
    '力を与える',
    '包括的',
    '平らな',
    'エグゼクティブ',
    '明示的',
    'にじみ出る',
    '耐障害性',
    '前景',
    '斬新な考え方',
    'フルレンジ',
    'グローバル',
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::JargonTermPrefix - Jargon Term Prefix

=cut

=head1 ABSTRACT

Jargon Term Prefix for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::JargonTermPrefix;

  my $plugin = Faker::Plugin::JaJp::JargonTermPrefix->new;

  # bless(..., "Faker::Plugin::JaJp::JargonTermPrefix")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for jargon term prefix.

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

The execute method returns a returns a random fake jargon term prefix.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::JargonTermPrefix;

  my $plugin = Faker::Plugin::JaJp::JargonTermPrefix->new;

  # bless(..., "Faker::Plugin::JaJp::JargonTermPrefix")

  # my $result = $plugin->execute;

  # 'エグゼクティブ';

  # my $result = $plugin->execute;

  # '明示的';

  # my $result = $plugin->execute;

  # 'フルレンジ';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::JargonTermPrefix;

  my $plugin = Faker::Plugin::JaJp::JargonTermPrefix->new;

  # bless(..., "Faker::Plugin::JaJp::JargonTermPrefix")

=back

=cut