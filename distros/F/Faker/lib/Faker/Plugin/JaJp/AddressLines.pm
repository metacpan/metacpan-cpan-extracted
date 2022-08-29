package Faker::Plugin::JaJp::AddressLines;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::JaJp';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->process_format(
    $self->faker->random->select(data_for_address_lines())
  );
}

sub data_for_address_lines {
  state $address_lines = [
    '{{address_line1}}',
    '{{address_line1}} {{address_line2}}',
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::AddressLines - Address Lines

=cut

=head1 ABSTRACT

Address Lines for Faker

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::AddressLines;

  my $plugin = Faker::Plugin::JaJp::AddressLines->new;

  # bless(..., "Faker::Plugin::JaJp::AddressLines")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address lines.

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

The execute method returns a returns a random fake address lines.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::AddressLines;

  my $plugin = Faker::Plugin::JaJp::AddressLines->new;

  # bless(..., "Faker::Plugin::JaJp::AddressLines")

  # my $result = $plugin->execute;

  # '1738707  愛知県鈴木市中央杉山町笹田10-9-9';

  # my $result = $plugin->execute;

  # '7551498  神奈川県喜嶋市北山口町田辺3-5-2';

  # my $result = $plugin->execute;

  # '8319487  神奈川県渚市東渚町江古田10-9-7 コーポ渚110号';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::AddressLines;

  my $plugin = Faker::Plugin::JaJp::AddressLines->new;

  # bless(..., "Faker::Plugin::JaJp::AddressLines")

=back

=cut