package Geo::Coder::Free::Validate;

# The one definition of what counts as a location.  The facade applies it before
# it touches a backend, and the backends apply it to whatever is handed to them
# directly, so a string the facade refuses is refused by them too.
#
# It lives in a module of its own for the same reason Provenance.pm does - see
# the note at the top of that file: the shared helpers module is tracked from VWF
# master, so anything added to it lasts only until the next sync with upstream,
# and two call sites that both reach for it would then be two call sites holding
# copies of it.  Everything in this module is specific to this distribution.

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(_valid_location);

=encoding utf-8

=head1 NAME

Geo::Coder::Free::Validate - The rule that decides whether a string could be a location

=head1 VERSION

Version 0.47

=cut

our $VERSION = '0.47';

=head1 DESCRIPTION

One question, asked in three places: could this string be a location at all?
C<Geo::Coder::Free::geocode()> asks it of a C<location> and of a C<scantext>
before it queries a backend, and L<Geo::Coder::Free::MaxMind> and
L<Geo::Coder::Free::OpenAddresses> ask it of what a caller hands them directly.
The rule lives here rather than being written out at each of those places, so
they cannot drift apart on which strings are worth looking up - a string the
facade refuses must not be accepted by a backend, and the other way round.

It is a cheap syntactic test and nothing more.  A C<true> answer means the string
is not disqualified, B<not> that a backend knows it: C<'Ramsgate, Kent'> is a
location and may still find nothing.  What is disqualified is a string of digits
only, which is what a numeric column holds when the wrong column has been read,
plus C<undef>, the empty string and a reference.  Anything with a non-digit
character in it counts, C<'3.14'> and C<'-'> included - including a comma, which
is why a rejected C<'0044'> is a column mistake rather than a missing place.

A caller should not need this module: the same rule is public as
C<< $geo->valid_location($row->{'place'}) >>, which is what a batch caller should
pre-filter with.  The sub is exported under its private name because the facade
and the backends are the only intended callers, and because its public spelling
already exists and has a name a caller can rely on.

=head1 SUBROUTINES/METHODS

=head2 _valid_location

Whether the string handed to it could be a location.  False for C<undef>, for
C<''>, for a reference and for a string of digits only; true for anything else,
including a single punctuation character.

    use Geo::Coder::Free::Validate qw(_valid_location);

    if(_valid_location($row->{'place'})) {
        # worth a lookup
    }

=cut

sub _valid_location {
	my $location = shift;

	return 0 unless defined($location) && !ref($location) && length($location);
	return $location =~ /\D/ ? 1 : 0;
}

1;

__END__

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2026 Nigel Horne.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License, version 2.
