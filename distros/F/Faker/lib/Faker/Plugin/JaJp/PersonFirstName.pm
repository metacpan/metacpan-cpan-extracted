package Faker::Plugin::JaJp::PersonFirstName;

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

  return (lc($self->faker->person_gender) eq 'male')
    ? $self->faker->random->select(data_for_first_name_male())
    : $self->faker->random->select(data_for_first_name_female());
}

sub data_for_first_name_male {
  state $first_name = [
    '晃',
    '篤司',
    '治',
    '和也',
    '京助',
    '健一',
    '修平',
    '翔太',
    '淳',
    '聡太郎',
    '太一',
    '太郎',
    '拓真',
    '翼',
    '智也',
    '直樹',
    '直人',
    '英樹',
    '浩',
    '学',
    '充',
    '稔',
    '裕樹',
    '裕太',
    '康弘',
    '陽一',
    '洋介',
    '亮介',
    '涼平',
    '零',
  ]
}

sub data_for_first_name_female {
  state $first_name = [
    '明美',
    'あすか',
    '香織',
    '加奈',
    'くみ子',
    'さゆり',
    '知実',
    '千代',
    '直子',
    '七夏',
    '花子',
    '春香',
    '真綾',
    '舞',
    '美加子',
    '幹',
    '桃子',
    '結衣',
    '裕美子',
    '陽子',
    '里佳',
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::PersonFirstName - Person First Name

=cut

=head1 ABSTRACT

Person First Name for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::PersonFirstName;

  my $plugin = Faker::Plugin::JaJp::PersonFirstName->new;

  # bless(..., "Faker::Plugin::JaJp::PersonFirstName")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for person first name.

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

The execute method returns a returns a random fake person first name.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::PersonFirstName;

  my $plugin = Faker::Plugin::JaJp::PersonFirstName->new;

  # bless(..., "Faker::Plugin::JaJp::PersonFirstName")

  # my $result = $plugin->execute;

  # '拓真';

  # my $result = $plugin->execute;

  # '智也';

  # my $result = $plugin->execute;

  # '英樹';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::PersonFirstName;

  my $plugin = Faker::Plugin::JaJp::PersonFirstName->new;

  # bless(..., "Faker::Plugin::JaJp::PersonFirstName")

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