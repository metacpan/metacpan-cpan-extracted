package MS::Reader::MzIdentML::SpectrumIdentificationResult;

use strict;
use warnings;

use parent qw/MS::Reader::XML::Record::CV/;

sub _pre_load {

    my ($self) = @_;
    $self->{_toplevel} = 'SpectrumIdentificationResult';

    # Lookup tables to quickly check elements
    $self->{_make_named_array} = {
        cvParam   => 'accession',
        userParam => 'name',
    };

    $self->{_make_anon_array} = { map {$_ => 1} qw/
        SpectrumIdentificationItem
    / };

}

sub id          { return $_[0]->{id}              } 
sub name        { return $_[0]->{name}            }
sub hits        { return $_[0]->{SpectrumIdentificationItem} }
sub spectrum_id { return $_[0]->{spectrumID}      }
sub data_ref    { return $_[0]->{spectraData_ref} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MS::Reader::MzIdentML::SpectrumIdentificationResult - mzIdentML result object

=head1 SYNOPSIS

    my $result = $search->next_spectrum_result;

    print $result->id;
    print $result->name;
    print $result->spectrum_id;
    print $result->data_ref;

    for my $hit ( @{ $result->hits } ) {
        # do something
    }

=head1 DESCRIPTION

The C<MS::Reader::MzIdentML::SpectrumIdentificationResult> class represents
the primary result object from a database search.

=head1 METHODS

=head2 id

Returns the unique element identifier

=head2 name
=head2 spectrum_id

Return spectrum identifiers. Typically the C<spectrum_id> return value is the
"native ID" and the name may be a different identifier used by the software to
reference the spectrum. These values will not always be the same depending on
which software generated the results file.

=head2 data_ref

Returns an identifier which can be used to look up a SpectraData element,
which in turns holds information about the original peaks file used as input
to the search.

=head2 hits

Returns a reference to an array of SpectrumIdentificationItem elements, which
represent individual spectra/peptide matches. These are currently returned as
nested hash structures but will eventually be returned as objects.

=head1 CAVEATS AND BUGS

The API is in alpha stage and is not guaranteed to be stable.

Please reports bugs or feature requests through the issue tracker at
L<https://github.com/jvolkening/p5-MS/issues>.

=head1 AUTHOR

Jeremy Volkening <jdv@base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2016 Jeremy Volkening

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
