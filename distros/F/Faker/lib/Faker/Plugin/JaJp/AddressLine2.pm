package Faker::Plugin::JaJp::AddressLine2;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::JaJp';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->process_format(
    $self->faker->random->select(data_for_address_line2())
  );
}

sub data_for_address_line2 {
  state $address_line2 = [
    'ハイツ{{person_last_name}}{{address_number}}号',
    'コーポ{{person_last_name}}{{address_number}}号',
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::AddressLine2 - Address Line2

=cut

=head1 ABSTRACT

Address Line2 for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::AddressLine2;

  my $plugin = Faker::Plugin::JaJp::AddressLine2->new;

  # bless(..., "Faker::Plugin::JaJp::AddressLine2")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address line2.

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

The execute method returns a returns a random fake address line2.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::AddressLine2;

  my $plugin = Faker::Plugin::JaJp::AddressLine2->new;

  # bless(..., "Faker::Plugin::JaJp::AddressLine2")

  # my $result = $plugin->execute;

  # 'ハイツ佐藤109号';

  # my $result = $plugin->execute;

  # 'ハイツ村山106号';

  # my $result = $plugin->execute;

  # 'ハイツ中村105号';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::AddressLine2;

  my $plugin = Faker::Plugin::JaJp::AddressLine2->new;

  # bless(..., "Faker::Plugin::JaJp::AddressLine2")

=back

=cut