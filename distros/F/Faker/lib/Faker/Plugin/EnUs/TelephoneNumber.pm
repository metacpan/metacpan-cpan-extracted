package Faker::Plugin::EnUs::TelephoneNumber;

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

  return $self->process_markers(
    $self->faker->random->select(format_for_telephone_number()),
    'numbers',
  );
}

sub format_for_telephone_number {
  state $telephone_number = [
    '###-###-####',
    '###-###-####',
    '### ### ####',
    '### ### ####',
    '### ### ####',
    '### ### ####',
    '(###) ###-####',
    '(###) ###-####',
    '(###) ###-####',
    '(###) ###-####',
    '+##(#)##########',
    '+##(#)##########',
    '0##########',
    '0##########',
    '###-###-####',
    '(###) ### ####',
    '1-###-###-####',
    '###.###.####',
    '###-###-####',
    '### ### ####',
    '##########',
    '(###) ###-####',
    '1-###-###-####',
    '###.###.####',
    '###-###-####x###',
    '(###)###-####x###',
    '1-###-###-####x###',
    '###.###.####x###',
    '###-###-#### x####',
    '(###)###-####x####',
    '1-###-###-####x####',
    '###.###.####x####',
    '###-###-####x#####',
    '(###)###-####x#####',
    '1-###-###-####x#####',
    '###.###.#### x#####',
  ]
}

1;



=head1 NAME

Faker::Plugin::EnUs::TelephoneNumber - Telephone Number

=cut

=head1 ABSTRACT

Telephone Number for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EnUs::TelephoneNumber;

  my $plugin = Faker::Plugin::EnUs::TelephoneNumber->new;

  # bless(..., "Faker::Plugin::EnUs::TelephoneNumber")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for telephone number.

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

The execute method returns a returns a random fake telephone number.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EnUs::TelephoneNumber;

  my $plugin = Faker::Plugin::EnUs::TelephoneNumber->new;

  # bless(..., "Faker::Plugin::EnUs::TelephoneNumber")

  # my $result = $plugin->execute;

  # "01408446845";

  # my $result = $plugin->execute;

  # "769-454-4390";

  # my $result = $plugin->execute;

  # "1-822-037-0225x82882";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EnUs::TelephoneNumber;

  my $plugin = Faker::Plugin::EnUs::TelephoneNumber->new;

  # bless(..., "Faker::Plugin::EnUs::TelephoneNumber")

=back

=cut