package Faker::Plugin::JaJp::CompanyNamePrefix;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::JaJp';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->faker->random->select(data_for_company_name_prefix());
}

sub data_for_company_name_prefix {
  state $name = [
    '株式会社',
    '有限会社',
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::CompanyNamePrefix - Company Name Prefix

=cut

=head1 ABSTRACT

Company Name Prefix for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::CompanyNamePrefix;

  my $plugin = Faker::Plugin::JaJp::CompanyNamePrefix->new;

  # bless(..., "Faker::Plugin::JaJp::CompanyNamePrefix")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for company name prefix.

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

The execute method returns a returns a random fake company name prefix.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::CompanyNamePrefix;

  my $plugin = Faker::Plugin::JaJp::CompanyNamePrefix->new;

  # bless(..., "Faker::Plugin::JaJp::CompanyNamePrefix")

  # my $result = $plugin->execute;

  # '株式会社';

  # my $result = $plugin->execute;

  # '株式会社';

  # my $result = $plugin->execute;

  # '有限会社';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::CompanyNamePrefix;

  my $plugin = Faker::Plugin::JaJp::CompanyNamePrefix->new;

  # bless(..., "Faker::Plugin::JaJp::CompanyNamePrefix")

=back

=cut