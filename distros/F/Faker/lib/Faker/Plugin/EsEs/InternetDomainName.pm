package Faker::Plugin::EsEs::InternetDomainName;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::EsEs';

# VERSION

our $VERSION = '1.17';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return join '.',
    $self->faker->internet_domain_word,
    $self->faker->internet_domain_tld,
}

1;



=head1 NAME

Faker::Plugin::EsEs::InternetDomainName - Internet Domain Name

=cut

=head1 ABSTRACT

Internet Domain Name for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EsEs::InternetDomainName;

  my $plugin = Faker::Plugin::EsEs::InternetDomainName->new;

  # bless(..., "Faker::Plugin::EsEs::InternetDomainName")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for internet domain name.

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

The execute method returns a returns a random fake internet domain name.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EsEs::InternetDomainName;

  my $plugin = Faker::Plugin::EsEs::InternetDomainName->new;

  # bless(..., "Faker::Plugin::EsEs::InternetDomainName")

  # my $result = $plugin->execute;

  # 'serrato-y-loera-sa.org';

  # my $result = $plugin->execute;

  # 'lozano-lugo-y-ferrer-e-hijo.com.es';

  # my $result = $plugin->execute;

  # 'grupo-cuesta-y-flia.com';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EsEs::InternetDomainName;

  my $plugin = Faker::Plugin::EsEs::InternetDomainName->new;

  # bless(..., "Faker::Plugin::EsEs::InternetDomainName")

=back

=cut