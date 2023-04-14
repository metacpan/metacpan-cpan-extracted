package Faker::Plugin::EnUs::CompanyNameSuffix;

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

  return $self->faker->random->select(data_for_name_suffix());
}

sub data_for_name_suffix {
  state $name = [
    'Co.',
    'Consulting',
    'Electronics',
    'Entertainment',
    'Inc.',
    'Incorporated',
    'and Sons',
    'LLC',
    'Group',
    'PLC',
    'Ltd.',
    'Ventures',
    'Worldwide',
    'Pty.',
  ]
}

1;



=head1 NAME

Faker::Plugin::EnUs::CompanyNameSuffix - Company Name Suffix

=cut

=head1 ABSTRACT

Company Name Suffix for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EnUs::CompanyNameSuffix;

  my $plugin = Faker::Plugin::EnUs::CompanyNameSuffix->new;

  # bless(..., "Faker::Plugin::EnUs::CompanyNameSuffix")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for company name suffix.

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

The execute method returns a returns a random fake company name suffix.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EnUs::CompanyNameSuffix;

  my $plugin = Faker::Plugin::EnUs::CompanyNameSuffix->new;

  # bless(..., "Faker::Plugin::EnUs::CompanyNameSuffix")

  # my $result = $plugin->execute;

  # "Inc.";

  # my $result = $plugin->execute;

  # "Incorporated";

  # my $result = $plugin->execute;

  # "Ventures";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EnUs::CompanyNameSuffix;

  my $plugin = Faker::Plugin::EnUs::CompanyNameSuffix->new;

  # bless(..., "Faker::Plugin::EnUs::CompanyNameSuffix")

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