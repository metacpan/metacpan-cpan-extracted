package Faker::Plugin::EnUs::PersonNameSuffix;

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

  return lc($self->faker->person_gender) eq 'male'
    ? $self->faker->random->select(data_for_name_suffix_male())
    : $self->faker->random->select(data_for_name_suffix());
}

sub data_for_name_suffix {
  state $name_suffix = [
    'MD',
    'DDS',
    'PhD',
    'DVM',
  ]
}

sub data_for_name_suffix_male {
  state $name_suffix = [
    data_for_name_suffix(),
    'Jr.',
    'Sr.',
    'I',
    'II',
    'III',
    'IV',
    'V',
  ]
}

1;



=head1 NAME

Faker::Plugin::EnUs::PersonNameSuffix - Person Name Suffix

=cut

=head1 ABSTRACT

Person Name Suffix for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EnUs::PersonNameSuffix;

  my $plugin = Faker::Plugin::EnUs::PersonNameSuffix->new;

  # bless(..., "Faker::Plugin::EnUs::PersonNameSuffix")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for person name suffix.

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

The execute method returns a returns a random fake person name suffix.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EnUs::PersonNameSuffix;

  my $plugin = Faker::Plugin::EnUs::PersonNameSuffix->new;

  # bless(..., "Faker::Plugin::EnUs::PersonNameSuffix")

  # my $result = $plugin->execute;

  # "I";

  # my $result = $plugin->execute;

  # "I";

  # my $result = $plugin->execute;

  # "II";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EnUs::PersonNameSuffix;

  my $plugin = Faker::Plugin::EnUs::PersonNameSuffix->new;

  # bless(..., "Faker::Plugin::EnUs::PersonNameSuffix")

=back

=cut