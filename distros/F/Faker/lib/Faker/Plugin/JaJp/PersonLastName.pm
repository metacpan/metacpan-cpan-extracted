package Faker::Plugin::JaJp::PersonLastName;

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
    '青田',
    '青山',
    '石田',
    '井高',
    '伊藤',
    '井上',
    '宇野',
    '江古田',
    '大垣',
    '加藤',
    '加納',
    '喜嶋',
    '木村',
    '桐山',
    '工藤',
    '小泉',
    '小林',
    '近藤',
    '斉藤',
    '坂本',
    '佐々木',
    '佐藤',
    '笹田',
    '鈴木',
    '杉山',
    '高橋',
    '田中',
    '田辺',
    '津田',
    '中島',
    '中村',
    '渚',
    '中津川',
    '西之園',
    '野村',
    '原田',
    '浜田',
    '廣川',
    '藤本',
    '松本',
    '三宅',
    '宮沢',
    '村山',
    '山岸',
    '山口',
    '山田',
    '山本',
    '吉田',
    '吉本',
    '若松',
    '渡辺',
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::PersonLastName - Person Last Name

=cut

=head1 ABSTRACT

Person Last Name for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::PersonLastName;

  my $plugin = Faker::Plugin::JaJp::PersonLastName->new;

  # bless(..., "Faker::Plugin::JaJp::PersonLastName")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for person last name.

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

The execute method returns a returns a random fake person last name.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::PersonLastName;

  my $plugin = Faker::Plugin::JaJp::PersonLastName->new;

  # bless(..., "Faker::Plugin::JaJp::PersonLastName")

  # my $result = $plugin->execute;

  # '近藤';

  # my $result = $plugin->execute;

  # '佐藤';

  # my $result = $plugin->execute;

  # '山岸';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::PersonLastName;

  my $plugin = Faker::Plugin::JaJp::PersonLastName->new;

  # bless(..., "Faker::Plugin::JaJp::PersonLastName")

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