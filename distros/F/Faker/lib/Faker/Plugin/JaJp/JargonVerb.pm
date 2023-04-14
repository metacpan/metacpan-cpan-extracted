package Faker::Plugin::JaJp::JargonVerb;

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

  return $self->faker->random->select(data_for_jargon_verb());
}

sub data_for_jargon_verb {
  state $jargon_verb = [
    '埋め込む',
    '利用する',
    '統合',
    '流線型',
    '最適化',
    '進化',
    '変身',
    '擁する',
    '有効',
    'オーケストレーションする',
    'てこの作用',
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::JargonVerb - Jargon Verb

=cut

=head1 ABSTRACT

Jargon Verb for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::JargonVerb;

  my $plugin = Faker::Plugin::JaJp::JargonVerb->new;

  # bless(..., "Faker::Plugin::JaJp::JargonVerb")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for jargon verb.

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

The execute method returns a returns a random fake jargon verb.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::JargonVerb;

  my $plugin = Faker::Plugin::JaJp::JargonVerb->new;

  # bless(..., "Faker::Plugin::JaJp::JargonVerb")

  # my $result = $plugin->execute;

  # '流線型';

  # my $result = $plugin->execute;

  # '最適化';

  # my $result = $plugin->execute;

  # 'オーケストレーションする';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::JargonVerb;

  my $plugin = Faker::Plugin::JaJp::JargonVerb->new;

  # bless(..., "Faker::Plugin::JaJp::JargonVerb")

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