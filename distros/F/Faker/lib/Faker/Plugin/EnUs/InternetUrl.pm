package Faker::Plugin::EnUs::InternetUrl;

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

  return $self->process_format(
    $self->faker->random->select(data_for_internet_url())
  );
}

sub data_for_internet_url {
  state $internet_url = [
    'https://www.{{internet_domain_name}}/',
    'https://{{internet_domain_name}}/',
    'http://www.{{internet_domain_name}}/',
    'http://{{internet_domain_name}}/',
    'http://{{internet_domain_name}}/',
  ]
}

1;



=head1 NAME

Faker::Plugin::EnUs::InternetUrl - Internet Url

=cut

=head1 ABSTRACT

Internet Url for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EnUs::InternetUrl;

  my $plugin = Faker::Plugin::EnUs::InternetUrl->new;

  # bless(..., "Faker::Plugin::EnUs::InternetUrl")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for internet url.

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

The execute method returns a returns a random fake internet url.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EnUs::InternetUrl;

  my $plugin = Faker::Plugin::EnUs::InternetUrl->new;

  # bless(..., "Faker::Plugin::EnUs::InternetUrl")

  # my $result = $plugin->execute;

  # "https://krajcik-skiles-and-mayer.com/";

  # my $result = $plugin->execute;

  # "http://heidenreich-beier.co/";

  # my $result = $plugin->execute;

  # "https://goldner-mann-and-emard.org/";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EnUs::InternetUrl;

  my $plugin = Faker::Plugin::EnUs::InternetUrl->new;

  # bless(..., "Faker::Plugin::EnUs::InternetUrl")

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