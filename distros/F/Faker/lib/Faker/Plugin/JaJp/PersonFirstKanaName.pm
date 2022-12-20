package Faker::Plugin::JaJp::PersonFirstKanaName;

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

  return (lc($self->faker->person_gender) eq 'male')
    ? $self->faker->random->select(data_for_first_kana_name_male())
    : $self->faker->random->select(data_for_first_kana_name_female());
}

sub data_for_first_kana_name_male {
  state $first_kana_name = [
    'アキラ',
    'アツシ',
    'オサム',
    'カズヤ',
    'キョウスケ',
    'ケンイチ',
    'シュウヘイ',
    'ショウタ',
    'ジュン',
    'ソウタロウ',
    'タイチ',
    'タロウ',
    'タクマ',
    'ツバサ',
    'トモヤ',
    'ナオキ',
    'ナオト',
    'ヒデキ',
    'ヒロシ',
    'マナブ',
    'ミツル',
    'ミノル',
    'ユウキ',
    'ユウタ',
    'ヤスヒロ',
    'ヨウイチ',
    'ヨウスケ',
    'リョウスケ',
    'リョウヘイ',
    'レイ',
  ]
}

sub data_for_first_kana_name_female {
  state $first_kana_name = [
    'アケミ',
    'アスカ',
    'カオリ',
    'カナ',
    'クミコ',
    'サユリ',
    'サトミ',
    'チヨ',
    'ナオコ',
    'ナナミ',
    'ハナコ',
    'ハルカ',
    'マアヤ',
    'マイ',
    'ミカコ',
    'ミキ',
    'モモコ',
    'ユイ',
    'ユミコ',
    'ヨウコ',
    'リカ',
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::PersonFirstKanaName - Person First Kana Name

=cut

=head1 ABSTRACT

Person First Kana Name for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::PersonFirstKanaName;

  my $plugin = Faker::Plugin::JaJp::PersonFirstKanaName->new;

  # bless(..., "Faker::Plugin::JaJp::PersonFirstKanaName")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for person first kana name.

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

The execute method returns a returns a random fake person first kana name.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::PersonFirstKanaName;

  my $plugin = Faker::Plugin::JaJp::PersonFirstKanaName->new;

  # bless(..., "Faker::Plugin::JaJp::PersonFirstKanaName")

  # my $result = $plugin->execute;

  # 'タクマ';

  # my $result = $plugin->execute;

  # 'トモヤ';

  # my $result = $plugin->execute;

  # 'ヒデキ';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::PersonFirstKanaName;

  my $plugin = Faker::Plugin::JaJp::PersonFirstKanaName->new;

  # bless(..., "Faker::Plugin::JaJp::PersonFirstKanaName")

=back

=cut