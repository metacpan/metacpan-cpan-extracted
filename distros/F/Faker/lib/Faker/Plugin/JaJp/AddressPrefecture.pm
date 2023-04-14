package Faker::Plugin::JaJp::AddressPrefecture;

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

  return $self->faker->random->select(data_for_address_prefecture());
}

sub data_for_address_prefecture {
  state $address_prefecture = [
    '北海道',
    '青森県',
    '岩手県',
    '宮城県',
    '秋田県',
    '山形県',
    '福島県',
    '茨城県',
    '栃木県',
    '群馬県',
    '埼玉県',
    '千葉県',
    '東京都',
    '神奈川県',
    '新潟県',
    '富山県',
    '石川県',
    '福井県',
    '山梨県',
    '長野県',
    '岐阜県',
    '静岡県',
    '愛知県',
    '三重県',
    '滋賀県',
    '京都府',
    '大阪府',
    '兵庫県',
    '奈良県',
    '和歌山県',
    '鳥取県',
    '島根県',
    '岡山県',
    '広島県',
    '山口県',
    '徳島県',
    '香川県',
    '愛媛県',
    '高知県',
    '福岡県',
    '佐賀県',
    '長崎県',
    '熊本県',
    '大分県',
    '宮崎県',
    '鹿児島県',
    '沖縄県',
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::AddressPrefecture - Address Prefecture

=cut

=head1 ABSTRACT

Address Prefecture for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::AddressPrefecture;

  my $plugin = Faker::Plugin::JaJp::AddressPrefecture->new;

  # bless(..., "Faker::Plugin::JaJp::AddressPrefecture")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address prefecture.

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

The execute method returns a returns a random fake address prefecture.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::AddressPrefecture;

  my $plugin = Faker::Plugin::JaJp::AddressPrefecture->new;

  # bless(..., "Faker::Plugin::JaJp::AddressPrefecture")

  # my $result = $plugin->execute;

  # '石川県';

  # my $result = $plugin->execute;

  # '長野県';

  # my $result = $plugin->execute;

  # '佐賀県';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::AddressPrefecture;

  my $plugin = Faker::Plugin::JaJp::AddressPrefecture->new;

  # bless(..., "Faker::Plugin::JaJp::AddressPrefecture")

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