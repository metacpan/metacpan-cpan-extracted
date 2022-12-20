package Faker::Plugin::EsEs::AddressPostalCode;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin::EsEs';

# VERSION

our $VERSION = '1.17';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->process_markers('#####', 'numbers');
}

1;



=head1 NAME

Faker::Plugin::EsEs::AddressPostalCode - Address Postal Code

=cut

=head1 ABSTRACT

Address Postal Code for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EsEs::AddressPostalCode;

  my $plugin = Faker::Plugin::EsEs::AddressPostalCode->new;

  # bless(..., "Faker::Plugin::EsEs::AddressPostalCode")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address postal code.

=encoding utf8

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Faker::Plugin::EsEs>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 execute

  execute(HashRef $data) (Str)

The execute method returns a returns a random fake address postal code.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EsEs::AddressPostalCode;

  my $plugin = Faker::Plugin::EsEs::AddressPostalCode->new;

  # bless(..., "Faker::Plugin::EsEs::AddressPostalCode")

  # my $result = $plugin->execute;

  # '31408';

  # my $result = $plugin->execute;

  # '46845';

  # my $result = $plugin->execute;

  # '07694';

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EsEs::AddressPostalCode;

  my $plugin = Faker::Plugin::EsEs::AddressPostalCode->new;

  # bless(..., "Faker::Plugin::EsEs::AddressPostalCode")

=back

=cut