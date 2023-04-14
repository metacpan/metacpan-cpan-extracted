package Faker::Plugin::JaJp::JargonAdverb;

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

  return $self->faker->random->select(data_for_jargon_adverb());
}

sub data_for_jargon_adverb {
  state $jargon_adverb = [
    'アダプティブ',
    '高度',
    '改善した',
    '同化した',
    '自動化',
    'バランスの取れた',
    'ビジネス重視',
    '一元化された',
    '複製された',
    '互換性',
    '設定可能',
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::JargonAdverb - Jargon Adverb

=cut

=head1 ABSTRACT

Jargon Adverb for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::JargonAdverb;

  my $plugin = Faker::Plugin::JaJp::JargonAdverb->new;

  # bless(..., "Faker::Plugin::JaJp::JargonAdverb")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for jargon adverb.

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

The execute method returns a returns a random fake jargon adverb.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::JargonAdverb;

  my $plugin = Faker::Plugin::JaJp::JargonAdverb->new;

  # bless(..., "Faker::Plugin::JaJp::JargonAdverb")

  # my $result = $plugin->execute;

  # '同化した';

  # my $result = $plugin->execute;

  # '自動化';

  # my $result = $plugin->execute;

  # '互換性';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::JargonAdverb;

  my $plugin = Faker::Plugin::JaJp::JargonAdverb->new;

  # bless(..., "Faker::Plugin::JaJp::JargonAdverb")

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