package Faker::Plugin::EnUs::PersonFormalName;

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

  return $self->process_format($self->faker->random->select(format_for_name()));
}

sub format_for_name {
  state $name = [
    map([
      '{{person_first_name}}',
      '{{person_last_name}}'
    ], 1..6),
    [
      '{{person_name_prefix}}',
      '{{person_first_name}}',
      '{{person_last_name}}'
    ],
    [
      '{{person_first_name}}',
      '{{person_last_name}}',
      '{{person_name_suffix}}'
    ],
    [
      '{{person_first_name}}',
      '{{person_first_name}}',
      '{{person_last_name}}',
      '{{person_name_suffix}}'
    ],
    [
      '{{person_name_prefix}}',
      '{{person_first_name}}',
      '{{person_first_name}}',
      '{{person_last_name}}',
      '{{person_name_suffix}}',
    ],
    [
      '{{person_name_prefix}}',
      '{{person_first_name}}',
      '{{person_last_name}}',
      '{{person_name_suffix}}',
    ]
  ]
}

1;



=head1 NAME

Faker::Plugin::EnUs::PersonFormalName - Person Formal Name

=cut

=head1 ABSTRACT

Person Formal Name for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EnUs::PersonFormalName;

  my $plugin = Faker::Plugin::EnUs::PersonFormalName->new;

  # bless(..., "Faker::Plugin::EnUs::PersonFormalName")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for person formal name.

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

The execute method returns a returns a random fake person formal name.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EnUs::PersonFormalName;

  my $plugin = Faker::Plugin::EnUs::PersonFormalName->new;

  # bless(..., "Faker::Plugin::EnUs::PersonFormalName")

  # my $result = $plugin->execute;

  # "Russel Krajcik";

  # my $result = $plugin->execute;

  # "Miss Josephine Forest Beier DDS";

  # my $result = $plugin->execute;

  # "Duncan Mann";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EnUs::PersonFormalName;

  my $plugin = Faker::Plugin::EnUs::PersonFormalName->new;

  # bless(..., "Faker::Plugin::EnUs::PersonFormalName")

=back

=cut