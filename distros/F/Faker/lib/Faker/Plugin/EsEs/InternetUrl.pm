package Faker::Plugin::EsEs::InternetUrl;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::EsEs';

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

Faker::Plugin::EsEs::InternetUrl - Internet Url

=cut

=head1 ABSTRACT

Internet Url for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EsEs::InternetUrl;

  my $plugin = Faker::Plugin::EsEs::InternetUrl->new;

  # bless(..., "Faker::Plugin::EsEs::InternetUrl")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for internet url.

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

The execute method returns a returns a random fake internet url.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EsEs::InternetUrl;

  my $plugin = Faker::Plugin::EsEs::InternetUrl->new;

  # bless(..., "Faker::Plugin::EsEs::InternetUrl")

  # my $result = $plugin->execute;

  # 'https://loera-y-santacruz.org/';

  # my $result = $plugin->execute;

  # 'https://www.lugo-y-ferrer-e-hijo.com.es/';

  # my $result = $plugin->execute;

  # 'https://cuesta-miramontes.com/';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EsEs::InternetUrl;

  my $plugin = Faker::Plugin::EsEs::InternetUrl->new;

  # bless(..., "Faker::Plugin::EsEs::InternetUrl")

=back

=cut