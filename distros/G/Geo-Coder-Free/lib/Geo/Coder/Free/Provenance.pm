package Geo::Coder::Free::Provenance;

# The provenance of a result, and the vocabulary it speaks.  Kept out of
# Geo::Coder::Free::Utils, which is tracked from VWF master: a geocoder result
# has no provenance there, so an addition to that file lasts only until the next
# sync with upstream.  Everything in this module is specific to this
# distribution.

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(GEOCODER ACCURACY_LEVELS _accuracy_for);

=encoding utf-8

=head1 NAME

Geo::Coder::Free::Provenance - The provenance keys that every Geo::Coder::Free result carries

=head1 DESCRIPTION

Which distribution and which backend produced a result, how good the match was
and how precise the coordinate is: the keys of section 2.1 of
F<BI-Phase6-Dependency-Specs.md>, and the vocabulary they speak.

    use Geo::Coder::Free::Provenance qw(GEOCODER _accuracy_for);

    my $point = Geo::Location::Point->new({
        geocoder   => GEOCODER,
        database   => 'OpenAddresses',
        confidence => 1.0,
        accuracy   => _accuracy_for(qw(house_number road city)),
    });

C<< Geo::Coder::Free->provenance($point) >> reads the four keys back, so a
consumer does not have to know them.

These three live here rather than in L<Geo::Coder::Free::Utils> because Utils is
synced from VWF master, where the provenance of a geocoder result has no
meaning; an addition there would be lost the next time that sync runs.

=head1 VERSION

Version 0.46

=cut

our $VERSION = '0.46';

# The distribution that produced a result.  Every backend stamps this on the
# Geo::Location::Point it hands back, so a consumer can tell a result from this
# distribution from one passed on by a wrapper such as Geo::Coder::List.
# Section 2.1 of BI-Phase6-Dependency-Specs.md.
use constant GEOCODER => 'Geo::Coder::Free';

# How precise the coordinates behind a match can claim to be, most precise
# first.  _accuracy_for() returns one of these, and anything that validates an
# accuracy (section 3.2) validates against this list.
use constant ACCURACY_LEVELS => [qw(address street postcode locality city region country)];

=head1 SUBROUTINES/METHODS

=head2 GEOCODER

The distribution that produced a result: C<Geo::Coder::Free>.  It is the
C<geocoder> key of every result this distribution returns, whether the answer
came from OpenAddresses, Local or MaxMind.

=head2 ACCURACY_LEVELS

A list of the accuracies a result may claim, most precise first: C<address>,
C<street>, C<postcode>, C<locality>, C<city>, C<region> and C<country>.

=head2 _accuracy_for

The precision a match can claim, from the fields that made it.  The most
precise field present decides: a house number makes it an C<address>, a road a
C<street>, a postcode a C<postcode>, a name or a city a C<locality>, a state or
region a C<region>, and a country a C<country>.  So a dataset row carrying only
a city, state and country is a C<locality>, which is what the geographic centres
C<Local.pm> derives are.

Always returns one of the C<ACCURACY_LEVELS>: a match on a row with none of the
fields above is still a named place, so it is reported as a C<locality> rather
than left unsaid, because every result promises an accuracy.

Exported so that a backend can describe the match it made without repeating the
vocabulary.

=cut

sub _accuracy_for {
	my @fields = @_;

	my %field = map { lc($_) => 1 } @fields;

	return 'address'  if($field{'house_number'} || $field{'number'});
	return 'street'   if($field{'road'} || $field{'street'});
	return 'postcode' if($field{'postcode'} || $field{'post_code'} || $field{'zip'});
	return 'locality' if($field{'city'} || $field{'town'} || $field{'name'});
	return 'region'   if($field{'state'} || $field{'state_district'} || $field{'county'} || $field{'region'});
	return 'country'  if($field{'country'});

	return 'locality';
}

1;

__END__

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2026 Nigel Horne.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License, version 2.
