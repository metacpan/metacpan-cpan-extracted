package Faker::Plugin::JaJp::TelephoneNumber;

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

  return $self->process_markers(
    $self->faker->random->select(data_for_telephone_number()),
    'numbers',
  );
}

sub data_for_telephone_number {
  state $telephone_number = [
    '080-####-####',
    '090-####-####',
    '0#-####-####',
    '0####-#-####',
    '0###-##-####',
    '0##-###-####',
    '0##0-###-###',
  ]
}

1;



=head1 NAME

Faker::Plugin::JaJp::TelephoneNumber - Telephone Number

=cut

=head1 ABSTRACT

Telephone Number for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::JaJp::TelephoneNumber;

  my $plugin = Faker::Plugin::JaJp::TelephoneNumber->new;

  # bless(..., "Faker::Plugin::JaJp::TelephoneNumber")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for telephone number.

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

The execute method returns a returns a random fake telephone number.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::JaJp::TelephoneNumber;

  my $plugin = Faker::Plugin::JaJp::TelephoneNumber->new;

  # bless(..., "Faker::Plugin::JaJp::TelephoneNumber")

  # my $result = $plugin->execute;

  # '01-4084-4684';

  # my $result = $plugin->execute;

  # '00769-4-5443';

  # my $result = $plugin->execute;

  # '080-8982-2037';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::JaJp::TelephoneNumber;

  my $plugin = Faker::Plugin::JaJp::TelephoneNumber->new;

  # bless(..., "Faker::Plugin::JaJp::TelephoneNumber")

=back

=cut