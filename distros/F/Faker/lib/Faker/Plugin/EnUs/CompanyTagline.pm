package Faker::Plugin::EnUs::CompanyTagline;

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

  return join ' ',
    $self->faker->jargon_verb,
    $self->faker->jargon_adjective,
    $self->faker->jargon_noun,
}

1;



=head1 NAME

Faker::Plugin::EnUs::CompanyTagline - Company Tagline

=cut

=head1 ABSTRACT

Company Tagline for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EnUs::CompanyTagline;

  my $plugin = Faker::Plugin::EnUs::CompanyTagline->new;

  # bless(..., "Faker::Plugin::EnUs::CompanyTagline")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for company tagline.

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

The execute method returns a returns a random fake company tagline.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EnUs::CompanyTagline;

  my $plugin = Faker::Plugin::EnUs::CompanyTagline->new;

  # bless(..., "Faker::Plugin::EnUs::CompanyTagline")

  # my $result = $plugin->execute;

  # "transform revolutionary supply-chains";

  # my $result = $plugin->execute;

  # "generate front-end web-readiness";

  # my $result = $plugin->execute;

  # "iterate back-end content";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EnUs::CompanyTagline;

  my $plugin = Faker::Plugin::EnUs::CompanyTagline->new;

  # bless(..., "Faker::Plugin::EnUs::CompanyTagline")

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