package Faker::Plugin::PersonGender;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin';

# VERSION

our $VERSION = '1.19';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->faker->random->select(['male', 'female']);
}

1;



=head1 NAME

Faker::Plugin::PersonGender - Person Gender

=cut

=head1 ABSTRACT

Person Gender for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::PersonGender;

  my $plugin = Faker::Plugin::PersonGender->new;

  # bless(..., "Faker::Plugin::PersonGender")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for person gender.

=encoding utf8

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Faker::Plugin>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 execute

  execute(HashRef $data) (Str)

The execute method returns a returns a random fake person gender.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::PersonGender;

  my $plugin = Faker::Plugin::PersonGender->new;

  # bless(..., "Faker::Plugin::PersonGender")

  # my $result = $plugin->execute;

  # "male";

  # my $result = $plugin->execute;

  # "male";

  # my $result = $plugin->execute;

  # "female";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::PersonGender;

  my $plugin = Faker::Plugin::PersonGender->new;

  # bless(..., "Faker::Plugin::PersonGender")

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