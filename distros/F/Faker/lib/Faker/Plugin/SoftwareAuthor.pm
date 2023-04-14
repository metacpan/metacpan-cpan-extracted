package Faker::Plugin::SoftwareAuthor;

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

  return $self->process_format(
    $self->faker->random->select(format_for_software_author())
  );
}

sub format_for_software_author {
  state $software_author = [
    map([
      '{{person_name}}'
    ], 1..3),
    [
      '{{company_name}}',
    ],
  ]
}

1;



=head1 NAME

Faker::Plugin::SoftwareAuthor - Software Author

=cut

=head1 ABSTRACT

Software Author for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::SoftwareAuthor;

  my $plugin = Faker::Plugin::SoftwareAuthor->new;

  # bless(..., "Faker::Plugin::SoftwareAuthor")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for software author.

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

The execute method returns a returns a random fake software author.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::SoftwareAuthor;

  my $plugin = Faker::Plugin::SoftwareAuthor->new(
    faker => {locales => ['en-us']},
  );

  # bless(..., "Faker::Plugin::SoftwareAuthor")

  # my $result = $plugin->execute;

  # "Jamison Skiles";

  # my $result = $plugin->execute;

  # "Josephine Kunde";

  # my $result = $plugin->execute;

  # "Darby Boyer";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::SoftwareAuthor;

  my $plugin = Faker::Plugin::SoftwareAuthor->new;

  # bless(..., "Faker::Plugin::SoftwareAuthor")

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