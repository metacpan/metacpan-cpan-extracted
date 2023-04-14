package Faker::Plugin::SoftwareSemver;

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

  return $self->process_markers(
    $self->faker->random->select(data_for_software_semver()),
    'numbers',
  );
}

sub data_for_software_semver {
  state $software_semver = [
    '0.#.#',
    '#.#.#',
    '#.##.##',
  ]
}

1;



=head1 NAME

Faker::Plugin::SoftwareSemver - Software Semver

=cut

=head1 ABSTRACT

Software Semver for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::SoftwareSemver;

  my $plugin = Faker::Plugin::SoftwareSemver->new;

  # bless(..., "Faker::Plugin::SoftwareSemver")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for software semver.

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

The execute method returns a returns a random fake software semver.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::SoftwareSemver;

  my $plugin = Faker::Plugin::SoftwareSemver->new;

  # bless(..., "Faker::Plugin::SoftwareSemver")

  # my $result = $plugin->execute;

  # "1.4.0";

  # my $result = $plugin->execute;

  # "4.6.8";

  # my $result = $plugin->execute;

  # "5.0.7";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::SoftwareSemver;

  my $plugin = Faker::Plugin::SoftwareSemver->new;

  # bless(..., "Faker::Plugin::SoftwareSemver")

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