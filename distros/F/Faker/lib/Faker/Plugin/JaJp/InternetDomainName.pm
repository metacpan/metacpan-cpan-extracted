package Faker::Plugin::JaJp::InternetDomainName;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::JaJp';

# VERSION

our $VERSION = '1.17';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->process_format(
    $self->faker->random->select(data_for_internet_domain_name())
  );
}

sub data_for_internet_domain_name {
  state $internet_domain_name = [
    '{{internet_domain_word}}.{{internet_domain_tld}}',
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::InternetDomainName - Internet Domain Name

=cut

=head1 ABSTRACT

Internet Domain Name for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::InternetDomainName;

  my $plugin = Faker::Plugin::JaJp::InternetDomainName->new;

  # bless(..., "Faker::Plugin::JaJp::InternetDomainName")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for internet domain name.

=encoding utf8

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Faker::Plugin::JaJp>

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

  use Faker::Plugin::JaJp::InternetDomainName;

  my $plugin = Faker::Plugin::JaJp::InternetDomainName->new;

  # bless(..., "Faker::Plugin::JaJp::InternetDomainName")

  # my $result = $plugin->execute;

  # 'sasada.jp';

  # my $result = $plugin->execute;

  # 'murayama.net';

  # my $result = $plugin->execute;

  # 'nagisa.info';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::InternetDomainName;

  my $plugin = Faker::Plugin::JaJp::InternetDomainName->new;

  # bless(..., "Faker::Plugin::JaJp::InternetDomainName")

=back

=cut