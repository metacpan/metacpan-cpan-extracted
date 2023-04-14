package Faker::Plugin::JaJp;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin';

# VERSION

our $VERSION = '1.19';

# MODIFIERS

sub new {
  my ($self, @args) = @_;

  $self = $self->SUPER::new(@args);

  require Faker;

  my $caches = $self->faker->caches;

  $self->faker(Faker->new('ja-jp'));

  $self->faker->caches($caches) if $caches->count;

  return $self;
}

1;



=head1 NAME

Faker::Plugin::JaJp - Ja-Jp Plugin Superclass

=cut

=head1 ABSTRACT

Fake Data Plugin Superclass (Ja-Jp)

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp;

  my $plugin = Faker::Plugin::JaJp->new;

  # bless(..., "Faker::Plugin::JaJp")

  # my $result = $plugin->execute;

  # ""

=cut

=head1 DESCRIPTION

This package provides a superclass for ja-jp based plugins.

=encoding utf8

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Faker::Plugin>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp;

  my $plugin = Faker::Plugin::JaJp->new;

  # bless(..., "Faker::Plugin::JaJp")

=back

=over 4

=item new example 2

  package main;

  use Faker::Plugin::JaJp;

  my $plugin = Faker::Plugin::JaJp->new({faker => 'ru-ru'});

  # bless(..., "Faker::Plugin::JaJp")

=back

=over 4

=item new example 3

  package main;

  use Faker::Plugin::JaJp;

  my $plugin = Faker::Plugin::JaJp->new({faker => ['ru-ru', 'sk-sk']});

  # bless(..., "Faker::Plugin::JaJp")

=back

=cut

=head1 FEATURES

This package provides the following features:

=cut

=over 4

=item subclass-feature

This package is meant to be subclassed.

B<example 1>

  package Faker::Plugin::JaJp::UserHandle;

  use base 'Faker::Plugin::JaJp';

  sub execute {
    my ($self) = @_;

    return $self->process('@?{{person_last_name_ascii}}####');
  }

  package main;

  use Faker;

  my $faker = Faker->new('ja-jp');

  # bless(..., "Faker")

  my $result = $faker->user_handle;

  # "\@qkudo7078"

=back

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2000, Al Newkirk.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut