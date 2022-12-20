package Faker::Plugin::EsEs::InternetEmailDomain;

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

  return $self->faker->random->select(data_for_internet_email_domain());
}

sub data_for_internet_email_domain {
  state $internet_email_domain = [
    'gmail.com',
    'hotmail.com',
    'hotmail.es',
    'yahoo.com',
    'yahoo.es',
    'live.com',
    'hispavista.com',
    'latinmail.com',
    'terra.com',
  ]
}

1;



=head1 NAME

Faker::Plugin::EsEs::InternetEmailDomain - Internet Email Domain

=cut

=head1 ABSTRACT

Internet Email Domain for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EsEs::InternetEmailDomain;

  my $plugin = Faker::Plugin::EsEs::InternetEmailDomain->new;

  # bless(..., "Faker::Plugin::EsEs::InternetEmailDomain")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for internet email domain.

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

The execute method returns a returns a random fake internet email domain.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EsEs::InternetEmailDomain;

  my $plugin = Faker::Plugin::EsEs::InternetEmailDomain->new;

  # bless(..., "Faker::Plugin::EsEs::InternetEmailDomain")

  # my $result = $plugin->execute;

  # 'yahoo.com';

  # my $result = $plugin->execute;

  # 'yahoo.com';

  # my $result = $plugin->execute;

  # 'latinmail.com';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EsEs::InternetEmailDomain;

  my $plugin = Faker::Plugin::EsEs::InternetEmailDomain->new;

  # bless(..., "Faker::Plugin::EsEs::InternetEmailDomain")

=back

=cut