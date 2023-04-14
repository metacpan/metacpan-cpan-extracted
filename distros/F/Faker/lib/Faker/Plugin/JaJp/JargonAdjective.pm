package Faker::Plugin::JaJp::JargonAdjective;

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

  return $self->faker->random->select(data_for_jargon_adjective());
}

sub data_for_jargon_adjective {
  state $jargon_adjective = [
    '直感的',
    '付加価値',
    '垂直',
    '先回り',
    '屈強',
    '革命的な',
    'スケーラブル',
    '最先端',
    '革新的な',
    '直感的',
    '戦略的',
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::JargonAdjective - Jargon Adjective

=cut

=head1 ABSTRACT

Jargon Adjective for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::JargonAdjective;

  my $plugin = Faker::Plugin::JaJp::JargonAdjective->new;

  # bless(..., "Faker::Plugin::JaJp::JargonAdjective")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for jargon adjective.

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

The execute method returns a returns a random fake jargon adjective.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::JargonAdjective;

  my $plugin = Faker::Plugin::JaJp::JargonAdjective->new;

  # bless(..., "Faker::Plugin::JaJp::JargonAdjective")

  # my $result = $plugin->execute;

  # '先回り';

  # my $result = $plugin->execute;

  # '屈強';

  # my $result = $plugin->execute;

  # '直感的';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::JargonAdjective;

  my $plugin = Faker::Plugin::JaJp::JargonAdjective->new;

  # bless(..., "Faker::Plugin::JaJp::JargonAdjective")

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