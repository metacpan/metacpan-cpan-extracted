package MS::Reader::MzIdentML::Peptide;

use strict;
use warnings;

use parent qw/MS::Reader::MzIdentML::SequenceItem/;

sub id         { return $_[0]->{id}         } 
sub seq        { return $_[0]->{PeptideSequence}->{pcdata} }
sub mods       { return $_[0]->{Modification} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MS::Reader::MzIdentML::Peptide - mzIdentML peptide object

=head1 SYNOPSIS

    my $pep = $search->fetch_peptide_by_id('PEP_1');

    say $pep->id;
    say $pep->seq;
    for (@{ $pep->mods }) {
        say $_->{monoisotopicMassDelta};
    }

=head1 DESCRIPTION

The C<MS::Reader::MzIdentML::Peptide> class represents a <Peptide> element in
the search results. This is a specific peptide isoform with known sequence and
modifications, and can be referenced elsewhere in the results.

=head1 METHODS

=head2 id

    my $id = $pep->id;

Returns the peptide ID, which is a unique identifier within the results file

=head2 seq

    my $seq = $pep->seq;

Returns the peptide sequence as a one-letter IUPAC string

=head2 mods

    my $mods = $pep->mods;

Returns a reference to an array of modifications, each of which is a nested
hash structure. The details of this structure are currently undocumented and
need to be deduced using C<Data::Dumper> to be utilized. At some point a
Modification class will be implemented to make utilization of this data
easier.

=head1 CAVEATS AND BUGS

The API is in alpha stage and is not guaranteed to be stable.

Please reports bugs or feature requests through the issue tracker at
L<https://github.com/jvolkening/p5-MS/issues>.

=head1 AUTHOR

Jeremy Volkening <jdv@base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2019 Jeremy Volkening

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
