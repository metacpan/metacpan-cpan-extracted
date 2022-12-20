package Faker::Plugin::EnUs::CompanyName;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::EnUs';

# VERSION

our $VERSION = '1.17';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->process_format(
    $self->faker->random->select(format_for_company_name())
  );
}

sub format_for_company_name {
  state $name = [
    '{{person_last_name}} {{company_name_suffix}}',
    '{{person_last_name}}-{{person_last_name}}',
    '{{person_last_name}}, {{person_last_name}} and {{person_last_name}}',
  ]
}

1;



=head1 NAME

Faker::Plugin::EnUs::CompanyName - Company Name

=cut

=head1 ABSTRACT

Company Name for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EnUs::CompanyName;

  my $plugin = Faker::Plugin::EnUs::CompanyName->new;

  # bless(..., "Faker::Plugin::EnUs::CompanyName")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for company name.

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

The execute method returns a returns a random fake company name.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EnUs::CompanyName;

  my $plugin = Faker::Plugin::EnUs::CompanyName->new;

  # bless(..., "Faker::Plugin::EnUs::CompanyName")

  # my $result = $plugin->execute;

  # "Johnston-Steuber";

  # my $result = $plugin->execute;

  # "Skiles-Mayer";

  # my $result = $plugin->execute;

  # "Miller and Sons";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EnUs::CompanyName;

  my $plugin = Faker::Plugin::EnUs::CompanyName->new;

  # bless(..., "Faker::Plugin::EnUs::CompanyName")

=back

=cut