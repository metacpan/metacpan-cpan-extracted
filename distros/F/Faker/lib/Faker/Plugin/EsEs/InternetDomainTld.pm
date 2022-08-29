package Faker::Plugin::EsEs::InternetDomainTld;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::EsEs';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->faker->random->select(data_for_internet_domain_tld());
}

sub data_for_internet_domain_tld {
  state $internet_domain_tld = [
    'com',
    'com',
    'com',
    'com',
    'net',
    'org',
    'org',
    'es',
    'es',
    'es',
    'com.es',
  ]
}

1;



=head1 NAME

Faker::Plugin::EsEs::InternetDomainTld - Internet Domain Tld

=cut

=head1 ABSTRACT

Internet Domain Tld for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EsEs::InternetDomainTld;

  my $plugin = Faker::Plugin::EsEs::InternetDomainTld->new;

  # bless(..., "Faker::Plugin::EsEs::InternetDomainTld")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for internet domain tld.

=encoding utf8

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Faker::Plugin::EsEs>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 execute

  execute(HashRef $data) (Str)

The execute method returns a returns a random fake internet domain tld.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EsEs::InternetDomainTld;

  my $plugin = Faker::Plugin::EsEs::InternetDomainTld->new;

  # bless(..., "Faker::Plugin::EsEs::InternetDomainTld")

  # my $result = $plugin->execute;

  # 'com';

  # my $result = $plugin->execute;

  # 'net';

  # my $result = $plugin->execute;

  # 'es';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EsEs::InternetDomainTld;

  my $plugin = Faker::Plugin::EsEs::InternetDomainTld->new;

  # bless(..., "Faker::Plugin::EsEs::InternetDomainTld")

=back

=cut