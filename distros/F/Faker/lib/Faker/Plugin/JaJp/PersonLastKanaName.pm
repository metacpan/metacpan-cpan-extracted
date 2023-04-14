package Faker::Plugin::JaJp::PersonLastKanaName;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::JaJp';

# VERSION

our $VERSION = '1.19';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->faker->random->select(data_for_last_name());
}

sub data_for_last_name {
  state $last_name = [
    'アオタ',
    'アオヤマ',
    'イシダ',
    'イダカ',
    'イトウ',
    'ウノ',
    'エコダ',
    'オオガキ',
    'カノウ',
    'カノウ',
    'キジマ',
    'キムラ',
    'キリヤマ',
    'クドウ',
    'コイズミ',
    'コバヤシ',
    'コンドウ',
    'サイトウ',
    'サカモト',
    'ササキ',
    'サトウ',
    'ササダ',
    'スズキ',
    'スギヤマ',
    'タカハシ',
    'タナカ',
    'タナベ',
    'ツダ',
    'ナカジマ',
    'ナカムラ',
    'ナギサ',
    'ナカツガワ',
    'ニシノソノ',
    'ノムラ',
    'ハラダ',
    'ハマダ',
    'ヒロカワ',
    'フジモト',
    'マツモト',
    'ミヤケ',
    'ミヤザワ',
    'ムラヤマ',
    'ヤマギシ',
    'ヤマグチ',
    'ヤマダ',
    'ヤマモト',
    'ヨシダ',
    'ヨシモト',
    'ワカマツ',
    'ワタナベ',
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::PersonLastKanaName - Person Last Kana Name

=cut

=head1 ABSTRACT

Person Last Kana Name for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::PersonLastKanaName;

  my $plugin = Faker::Plugin::JaJp::PersonLastKanaName->new;

  # bless(..., "Faker::Plugin::JaJp::PersonLastKanaName")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for person last kana name.

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

The execute method returns a returns a random fake person last kana name.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::PersonLastKanaName;

  my $plugin = Faker::Plugin::JaJp::PersonLastKanaName->new;

  # bless(..., "Faker::Plugin::JaJp::PersonLastKanaName")

  # my $result = $plugin->execute;

  # 'サイトウ';

  # my $result = $plugin->execute;

  # 'ササダ';

  # my $result = $plugin->execute;

  # 'ヤマギシ';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::PersonLastKanaName;

  my $plugin = Faker::Plugin::JaJp::PersonLastKanaName->new;

  # bless(..., "Faker::Plugin::JaJp::PersonLastKanaName")

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