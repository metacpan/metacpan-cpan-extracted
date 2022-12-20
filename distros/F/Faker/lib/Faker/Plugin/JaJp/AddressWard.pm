package Faker::Plugin::JaJp::AddressWard;

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
    $self->faker->random->select(data_for_address_ward())
  );
}

sub data_for_address_ward {
  state $address_ward = [
    '中央',
    '北',
    '東',
    '南',
    '西',
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::AddressWard - Address Ward

=cut

=head1 ABSTRACT

Address Ward for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::AddressWard;

  my $plugin = Faker::Plugin::JaJp::AddressWard->new;

  # bless(..., "Faker::Plugin::JaJp::AddressWard")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address ward.

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

The execute method returns a returns a random fake address ward.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::AddressWard;

  my $plugin = Faker::Plugin::JaJp::AddressWard->new;

  # bless(..., "Faker::Plugin::JaJp::AddressWard")

  # my $result = $plugin->execute;

  # '北';

  # my $result = $plugin->execute;

  # '東';

  # my $result = $plugin->execute;

  # '西';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::AddressWard;

  my $plugin = Faker::Plugin::JaJp::AddressWard->new;

  # bless(..., "Faker::Plugin::JaJp::AddressWard")

=back

=cut