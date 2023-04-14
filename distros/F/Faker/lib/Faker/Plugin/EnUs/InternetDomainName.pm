package Faker::Plugin::EnUs::InternetDomainName;

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

  return join '.',
    $self->faker->internet_domain_word,
    $self->faker->internet_domain_tld,
}

1;



=head1 NAME

Faker::Plugin::EnUs::InternetDomainName - Internet Domain Name

=cut

=head1 ABSTRACT

Internet Domain Name for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EnUs::InternetDomainName;

  my $plugin = Faker::Plugin::EnUs::InternetDomainName->new;

  # bless(..., "Faker::Plugin::EnUs::InternetDomainName")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for internet domain name.

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

The execute method returns a returns a random fake internet domain name.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EnUs::InternetDomainName;

  my $plugin = Faker::Plugin::EnUs::InternetDomainName->new;

  # bless(..., "Faker::Plugin::EnUs::InternetDomainName")

  # my $result = $plugin->execute;

  # "steuber-krajcik.org";

  # my $result = $plugin->execute;

  # "miller-and-sons.com";

  # my $result = $plugin->execute;

  # "witting-entertainment.com";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EnUs::InternetDomainName;

  my $plugin = Faker::Plugin::EnUs::InternetDomainName->new;

  # bless(..., "Faker::Plugin::EnUs::InternetDomainName")

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