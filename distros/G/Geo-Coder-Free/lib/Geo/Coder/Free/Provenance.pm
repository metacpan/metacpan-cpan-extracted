package Geo::Coder::Free::Provenance;

# The provenance of a result, and the vocabulary it speaks.  Kept out of
# Geo::Coder::Free::Utils, which is tracked from VWF master: a geocoder result
# has no provenance there, so an addition to that file lasts only until the next
# sync with upstream.  Everything in this module is specific to this
# distribution.

use strict;
use warnings;

use Geo::Location::Point 0.19 ();	# Defines the accuracy vocabulary this module speaks
use Exporter qw(import);
our @EXPORT_OK = qw(GEOCODER ACCURACY_LEVELS);

=encoding utf-8

=head1 NAME

Geo::Coder::Free::Provenance - The provenance keys that every Geo::Coder::Free result carries

=head1 DESCRIPTION

Which distribution and which backend produced a result, how good the match was
and how precise the coordinate is: the keys of section 2.1 of
F<BI-Phase6-Dependency-Specs.md>, and the vocabulary they speak.

    use Geo::Coder::Free::Provenance qw(GEOCODER);

    my $point = Geo::Location::Point->new({
        geocoder   => GEOCODER,
        database   => 'OpenAddresses',
        confidence => 1.0,
        accuracy   => Geo::Location::Point::accuracy_for(qw(house_number road city)),
    });

C<< Geo::Coder::Free->provenance($point) >> reads the four keys back, so a
consumer does not have to know them.

These two live here rather than in L<Geo::Coder::Free::Utils> because Utils is
synced from VWF master, where the provenance of a geocoder result has no
meaning; an addition there would be lost the next time that sync runs.

=head1 VERSION

Version 0.52

=cut

our $VERSION = '0.52';

# The distribution that produced a result.  Every backend stamps this on the
# Geo::Location::Point it hands back, so a consumer can tell a result from this
# distribution from one passed on by a wrapper such as Geo::Coder::List.
# Section 2.1 of BI-Phase6-Dependency-Specs.md.
use constant GEOCODER => 'Geo::Coder::Free';

# How precise the coordinates behind a match can claim to be, most precise
# first.  Geo::Location::Point::accuracy_for() returns one of these, and anything
# that validates an accuracy (section 3.2) validates against this list.
#
# The vocabulary is not written down here.  Geo::Location::Point defines it and
# refuses an accuracy outside it, so this module reads that one list: the levels
# a backend reports and the levels a point accepts cannot drift apart, and this
# constant is the same list object rather than a copy that agrees today.  The
# rule that turns matched fields into a level lives there too, with the list.
use constant ACCURACY_LEVELS => Geo::Location::Point::ACCURACY_LEVELS();

=head1 SUBROUTINES/METHODS

=head2 GEOCODER

The distribution that produced a result: C<Geo::Coder::Free>.  It is the
C<geocoder> key of every result this distribution returns, whether the answer
came from OpenAddresses, Local or MaxMind.

=head2 ACCURACY_LEVELS

A list of the accuracies a result may claim, most precise first: C<address>,
C<street>, C<postcode>, C<locality>, C<city>, C<region> and C<country>.

It is C<Geo::Location::Point::ACCURACY_LEVELS()>, the list that module
validates an accuracy against, re-exported here so that a backend can describe
the match it made without knowing which module the vocabulary is defined in.
There is one list behind both names, not a copy of it.

The rule that turns the fields a match was made on into one of these levels is
C<Geo::Location::Point::accuracy_for()>, which lives beside the list it returns
a level from.  This module reports the C<accuracy> key; it does not decide what
the key may hold.

=cut

1;

__END__

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2026 Nigel Horne.

The program code is released under the following licence: GPL2 for personal use on a single computer.
All other users (including Commercial, Charity, Educational, and Government)
must apply in writing for a licence for use from Nigel Horne at C<< <njh at nigelhorne.com> >>.
