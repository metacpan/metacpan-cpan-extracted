package Faker::Plugin::JaJp::PersonFirstNameAscii;

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

  return $self->faker->random->select(data_for_first_name_ascii());
}

sub data_for_first_name_ascii {
  state $first_name_ascii = [
    'akira',
    'atsushi',
    'osamu',
    'akemi',
    'asuka',
    'kazuya',
    'kyosuke',
    'kenichi',
    'kaori',
    'kana',
    'kumiko',
    'shuhei',
    'shota',
    'jun',
    'soutaro',
    'sayuri',
    'satomi',
    'taichi',
    'taro',
    'takuma',
    'tsubasa',
    'tomoya',
    'chiyo',
    'naoki',
    'naoto',
    'naoko',
    'nanami',
    'hideki',
    'hiroshi',
    'hanako',
    'haruka',
    'manabu',
    'mitsuru',
    'minoru',
    'maaya',
    'mai',
    'mikako',
    'miki',
    'momoko',
    'yuki',
    'yuta',
    'yasuhiro',
    'youichi',
    'yosuke',
    'yui',
    'yumiko',
    'yoko',
    'ryosuke',
    'ryohei',
    'rei',
    'rika',
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::PersonFirstNameAscii - Person First Name Ascii

=cut

=head1 ABSTRACT

Person First Name Ascii for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::PersonFirstNameAscii;

  my $plugin = Faker::Plugin::JaJp::PersonFirstNameAscii->new;

  # bless(..., "Faker::Plugin::JaJp::PersonFirstNameAscii")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for person first name ascii.

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

The execute method returns a returns a random fake person first name ascii.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::PersonFirstNameAscii;

  my $plugin = Faker::Plugin::JaJp::PersonFirstNameAscii->new;

  # bless(..., "Faker::Plugin::JaJp::PersonFirstNameAscii")

  # my $result = $plugin->execute;

  # 'taichi';

  # my $result = $plugin->execute;

  # 'tomoya';

  # my $result = $plugin->execute;

  # 'yosuke';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::PersonFirstNameAscii;

  my $plugin = Faker::Plugin::JaJp::PersonFirstNameAscii->new;

  # bless(..., "Faker::Plugin::JaJp::PersonFirstNameAscii")

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