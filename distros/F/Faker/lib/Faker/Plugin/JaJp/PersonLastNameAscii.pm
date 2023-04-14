package Faker::Plugin::JaJp::PersonLastNameAscii;

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

  return $self->faker->random->select(data_for_last_name_ascii());
}

sub data_for_last_name_ascii {
  state $last_name_ascii = [
    'aota',
    'aoyama',
    'ishida',
    'idaka',
    'ito',
    'uno',
    'ekoda',
    'ogaki',
    'kato',
    'kanou',
    'kijima',
    'kimura',
    'kiriyama',
    'kudo',
    'koizumi',
    'kobayashi',
    'kondo',
    'saito',
    'sakamoto',
    'sasaki',
    'sato',
    'sasada',
    'suzuki',
    'sugiyama',
    'takahashi',
    'tanaka',
    'tanabe',
    'tsuda',
    'nakajima',
    'nakamura',
    'nagisa',
    'nakatsugawa',
    'nishinosono',
    'nomura',
    'harada',
    'hamada',
    'hirokawa',
    'fujimoto',
    'matsumoto',
    'miyake',
    'miyazawa',
    'murayama',
    'yamagishi',
    'yamaguchi',
    'yamada',
    'yamamoto',
    'yoshida',
    'yoshimoto',
    'wakamatsu',
    'watanabe',
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::PersonLastNameAscii - Person Last Name Ascii

=cut

=head1 ABSTRACT

Person Last Name Ascii for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::PersonLastNameAscii;

  my $plugin = Faker::Plugin::JaJp::PersonLastNameAscii->new;

  # bless(..., "Faker::Plugin::JaJp::PersonLastNameAscii")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for person last name ascii.

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

The execute method returns a returns a random fake person last name ascii.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::PersonLastNameAscii;

  my $plugin = Faker::Plugin::JaJp::PersonLastNameAscii->new;

  # bless(..., "Faker::Plugin::JaJp::PersonLastNameAscii")

  # my $result = $plugin->execute;

  # 'saito';

  # my $result = $plugin->execute;

  # 'sasada';

  # my $result = $plugin->execute;

  # 'yamagishi';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::PersonLastNameAscii;

  my $plugin = Faker::Plugin::JaJp::PersonLastNameAscii->new;

  # bless(..., "Faker::Plugin::JaJp::PersonLastNameAscii")

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