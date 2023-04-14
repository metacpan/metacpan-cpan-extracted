package Faker::Plugin::EnUs::CompanyDescription;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::EnUs';

# VERSION

our $VERSION = '1.19';

# METHODS

sub execute {
  my ($self, $data) = @_;

  my $does = $self->faker->random->select([
    'Delivers',
    'Delivering',
    'Excels at',
    'Offering',
    'Best-in-class for',
    'Provides',
    'Providing',
  ]);

  return join ' ', $does,
    $self->faker->jargon_term_prefix,
    $self->faker->jargon_adverb,
    $self->faker->jargon_term_suffix;
}

1;



=head1 NAME

Faker::Plugin::EnUs::CompanyDescription - Company Description

=cut

=head1 ABSTRACT

Company Description for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EnUs::CompanyDescription;

  my $plugin = Faker::Plugin::EnUs::CompanyDescription->new;

  # bless(..., "Faker::Plugin::EnUs::CompanyDescription")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for company description.

=encoding utf8

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Faker::Plugin::EnUs>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 execute

  execute(HashRef $data) (Str)

The execute method returns a returns a random fake company description.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EnUs::CompanyDescription;

  my $plugin = Faker::Plugin::EnUs::CompanyDescription->new;

  # bless(..., "Faker::Plugin::EnUs::CompanyDescription")

  # my $result = $plugin->execute;

  # "Excels at full-range synchronised implementations";

  # my $result = $plugin->execute;

  # "Provides logistical ameliorated methodologies";

  # my $result = $plugin->execute;

  # "Offering hybrid future-proofed applications";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EnUs::CompanyDescription;

  my $plugin = Faker::Plugin::EnUs::CompanyDescription->new;

  # bless(..., "Faker::Plugin::EnUs::CompanyDescription")

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