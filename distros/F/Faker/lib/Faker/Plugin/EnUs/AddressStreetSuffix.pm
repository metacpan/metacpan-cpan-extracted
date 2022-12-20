package Faker::Plugin::EnUs::AddressStreetSuffix;

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

  return $self->faker->random->select(data_for_address_street_suffix());
}

sub data_for_address_street_suffix {
  state $address_street_suffix = [
    'Alley',
    'Avenue',
    'Branch',
    'Bridge',
    'Brook',
    'Burg',
    'Bypass',
    'Camp',
    'Canyon',
    'Cape',
    'Causeway',
    'Center',
    'Circle',
    'Cliff',
    'Club',
    'Common',
    'Corner',
    'Course',
    'Court',
    'Cove',
    'Creek',
    'Crescent',
    'Crest',
    'Crossing',
    'Crossroad',
    'Curve',
    'Dale',
    'Dam',
    'Divide',
    'Drive',
    'Drive',
    'Estate',
    'Expressway',
    'Extension',
    'Fall',
    'Ferry',
    'Field',
    'Flat',
    'Ford',
    'Forest',
    'Forge',
    'Fork',
    'Fort',
    'Freeway',
    'Garden',
    'Gateway',
    'Glen',
    'Green',
    'Grove',
    'Harbor',
    'Haven',
    'Highway',
    'Hill',
    'Hills',
    'Hollow',
    'Inlet',
    'Inlet',
    'Island',
    'Island',
    'Isle',
    'Isle',
    'Junction',
    'Key',
    'Knoll',
    'Lake',
    'Land',
    'Landing',
    'Lane',
    'Loaf',
    'Lodge',
    'Lodge',
    'Loop',
    'Mall',
    'Manor',
    'Meadow',
    'Mill',
    'Mission',
    'Mission',
    'Motorway',
    'Mount',
    'Mountain',
    'Mountain',
    'Neck',
    'Orchard',
    'Oval',
    'Overpass',
    'Park',
    'Parkway',
    'Pass',
    'Passage',
    'Path',
    'Pike',
    'Pine',
    'Pines',
    'Place',
    'Plain',
    'Plaza',
    'Plaza',
    'Point',
    'Points',
    'Port',
    'Port',
    'Prairie',
    'Prairie',
    'Radial',
    'Ramp',
    'Ranch',
    'Rapid',
    'Rest',
    'Ridge',
    'River',
    'Road',
    'Road',
    'Route',
    'Row',
    'Rue',
    'Run',
    'Shore',
    'Skyway',
    'Spring',
    'Springs',
    'Springs',
    'Square',
    'Square',
    'Station',
    map(
      'Street', 1..50
    ),
    'Summit',
    'Terrace',
    'Trail',
    'Trail',
    'Village',
    'Ville',
    'Way',
  ]
}

1;



=head1 NAME

Faker::Plugin::EnUs::AddressStreetSuffix - Address Street Suffix

=cut

=head1 ABSTRACT

Address Street Suffix for Faker

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::EnUs::AddressStreetSuffix;

  my $plugin = Faker::Plugin::EnUs::AddressStreetSuffix->new;

  # bless(..., "Faker::Plugin::EnUs::AddressStreetSuffix")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for address street suffix.

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

The execute method returns a returns a random fake address street suffix.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::EnUs::AddressStreetSuffix;

  my $plugin = Faker::Plugin::EnUs::AddressStreetSuffix->new;

  # bless(..., "Faker::Plugin::EnUs::AddressStreetSuffix")

  # my $result = $plugin->execute;

  # "Key";

  # my $result = $plugin->execute;

  # "Mission";

  # my $result = $plugin->execute;

  # "Street";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::EnUs::AddressStreetSuffix;

  my $plugin = Faker::Plugin::EnUs::AddressStreetSuffix->new;

  # bless(..., "Faker::Plugin::EnUs::AddressStreetSuffix")

=back

=cut