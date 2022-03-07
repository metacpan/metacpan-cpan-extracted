package MS::Reader::MzIdentML;

use strict;
use warnings;

use parent qw/MS::Reader::XML/;

use Carp;

use MS::Reader::MzIdentML::SpectrumIdentificationResult;
use MS::Reader::MzIdentML::SequenceItem;
use MS::Reader::MzIdentML::DBSequence;
use MS::Reader::MzIdentML::Peptide;
use MS::Reader::MzIdentML::PeptideEvidence;
use MS::Reader::MzIdentML::ProteinAmbiguityGroup;
use MS::CV qw/:MS/;

BEGIN {

    *fetch_peptide_by_id         = \&_fetch_seqitem_by_id;
    *fetch_peptideevidence_by_id = \&_fetch_seqitem_by_id;
    *fetch_dbsequence_by_id      = \&_fetch_seqitem_by_id;

}

sub _post_load {

    my ($self) = @_;

    $self->{__curr_ident_list} = 0;
    $self->SUPER::_post_load();

}

sub _pre_load {

    my ($self) = @_;

    # ---------------------------------------------------------------------------#
    # These tables are the main configuration point between the parser and the
    # specific document schema. For more information, see the documentation
    # for the parent class MS::Reader::XML
    # ---------------------------------------------------------------------------#

    $self->{_toplevel} = 'MzIdentML';

    # the situation for DBSequence, Peptide, and PeptideEvidence is a bit
    # tricky. They are all direct children of the SequenceCollection element,
    # and the parser infrastructure currently cannot handle this easily.
    # Instead, they will all be assigned the record type of the first element
    # seen. Since the XSD requires at least one DBSequence item, and it should
    # always come before the other element types, this is the type that will
    # be used. To work around this, we point to a base SequenceItem class, and
    # within that class figure out what type of item it is and return a
    # specific sublclass object as appropriate.
    $self->{__record_classes} = {
        DBSequence                   => 'MS::Reader::MzIdentML::SequenceItem',
        #Peptide                      => 'MS::Reader::MzIdentML::Peptide',
        #PeptideEvidence              => 'MS::Reader::MzIdentML::PeptideEvidence',
        SpectrumIdentificationResult => 'MS::Reader::MzIdentML::SpectrumIdentificationResult',
        ProteinAmbiguityGroup        => 'MS::Reader::MzIdentML::ProteinAmbiguityGroup',
    };

    $self->{_skip_inside} = { map {$_ => 1} qw/
        Peptide
        DBSequence
        PeptideEvidence
        SpectrumIdentificationResult
        ProteinAmbiguityGroup
    / };

    $self->{_make_index} = { map {$_ => 'id'} qw/
        Peptide
        DBSequence
        PeptideEvidence
        SpectrumIdentificationResult
        ProteinAmbiguityGroup
    / };

    # these are indexed elements with no children
    $self->{_empty_el} = { map {$_ => 1} qw/
        DBSequence
        PeptideEvidence
    / };

    $self->{_store_child_iters} = {
        SpectrumIdentificationList => 'SpectrumIdentificationResult',
    };

    $self->{_make_named_array} = {
        cvParam   => 'accession',
        userParam => 'name',
    };

    $self->{_make_named_hash} = { map {$_ => 'id'} qw/
        AnalysisSoftware
        BibliographicReference
        cv
        Enzyme
        MassTable
        Measure
        Organization
        Person
        ProteinDetectionHypothesis
        SampleType
        SearchDatabase
        SourceFile
        SpectraData
        SpectrumIdentification
        SpectrumIdentificationItem
        SpectrumIdentificationProtocol
        TranslationTable
    / };

    # NOTE: SpectrumIdentificationList has unique id, but make array to allow
    # ordered selection of indexed elements

    $self->{_make_anon_array} = { map {$_ => 1} qw/
        Affiliation
        AmbiguousResidue
        ContactRole
        Filter
        FragmentArray
        InputSpectra
        InputSpectrumIdentifications
        IonType
        PeptideHypothesis
        Residue
        SearchDatabaseRef
        SearchModification
        SpecificityRules
        SpectrumIdentificationItemRef
        SubSample
        SpectrumIdentificationList
    / };

}

sub fetch_spectrum_result {

    my ($self, $idx) = @_;
    my $ref = $self->{DataCollection}->{AnalysisData}
        ->{SpectrumIdentificationList}->[ $self->{__curr_ident_list} ];
    return $self->fetch_record($ref => $idx);

}

sub fetch_protein_group {

    my ($self, $idx) = @_;
    my $ref = $self->{DataCollection}->{AnalysisData}
        ->{ProteinDetectionList};
    return $self->fetch_record($ref, $idx);

}

sub _fetch_seqitem_by_id {

    my ($self, $id) = @_;
    my $ref = $self->{SequenceCollection};
    my $idx = $self->get_index_by_id($ref => $id);
    return $self->fetch_record($ref => $idx);

}

sub next_spectrum_result {

    my ($self) = @_;
    my $ref = $self->{DataCollection}->{AnalysisData}
        ->{SpectrumIdentificationList}->[ $self->{__curr_ident_list} ];
    return $self->next_record($ref);

}

sub next_protein_group {

    my ($self) = @_;
    my $ref = $self->{DataCollection}->{AnalysisData}
        ->{ProteinDetectionList};
    return $self->next_record($ref);

}

sub n_ident_lists {

    my ($self) = @_;
    return scalar @{ $self->{DataCollection}->{AnalysisData}
        ->{SpectrumIdentificationList} };

}

sub goto_ident_list {

    my ($self, $idx) = @_;
    $self->{__curr_ident_list} = $idx;
    my $ref = $self->{DataCollection}->{AnalysisData}
        ->{SpectrumIdentificationList}->[ $self->{__curr_ident_list} ];
    $ref->{__pos} = 0;
    return(1); # otherwise returns zero, causing tests to fail

}

sub raw_file {

    my ($self, $id) = @_;
    return $self->{DataCollection}->{Inputs}
        ->{SpectraData}->{$id}->{location} ;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MS::Reader::MzIdentML - A simple but complete mzIdentML parser

=head1 SYNOPSIS

    use MS::Reader::MzIdentML;

    my $idents = MS::Reader::MzIdentML->new('idents.mzIdentML');

    # spectrum/peptide-level results
    while (my $result = $idents->next_spectrum_result) {

        # result is an MS::Reader::MzIdentML::SpectrumIdentificationResult
        # object

    }

    # protein-level results
    while (my $grp = $idents->next_protein) {

        # result is an MS::Reader::MzIdentML::ProteinAmbiguityGroup
        # object

    }

    # multi-analysis file
    my $n = $idents->n_ident_lists;
    for (0..$n-1) {
        $idents->goto_ident_list($_);
        while (my $result = $idents->next_spectrum_result) {

            # result is an MS::Reader::MzIdentML::SpectrumIdentificationResult
            # object

        }
    }

=head1 DESCRIPTION

C<MS::Reader::MzIdentML> is a parser for the HUPO PSI standard mzIdentML format for 
mass spectrometry search results. It aims to provide complete access to the data
contents while not being overburdened by detailed class infrastructure.
Convenience methods are provided for accessing commonly used data. Users who
want to extract data not accessible through the available methods should
examine the data structure of the parsed object. The C<dump()> method of
L<MS::Reader::XML>, from which this class inherits, provides an easy method of
doing so.

Currently this module is only semi-complete. The parsing routines are
functional, but there is a lack of direct access to much of the data,
requiring traversal of the underlying data structure. Hopefully this situation
will improve in the future.

=head1 INHERITANCE

C<MS::Reader::MzIdentML> is a subclass of L<MS::Reader::XML>, which in turn
inherits from L<MS::Reader>, and inherits the methods of these parental
classes. Please see the documentation for those classes for details of
available methods not detailed below.

=head1 METHODS

=head2 new

    my $idents = MS::Reader::MzIdentML->new( $fn,
        use_cache => 0,
        paranoid  => 0,
    );

Takes an input filename (required) and optional argument hash and returns an
C<MS::Reader::MzIdentML> object. This constructor is inherited directly from
L<MS::Reader>. Available options include:

=over

=item * use_cache — cache fetched records in memory for repeat access
(default: FALSE)

=item * paranoid — when loading index from disk, recalculates MD5 checksum
each time to make sure raw file hasn't changed. This adds (typically) a few
seconds to load times. By default, only file size and mtime are checked.

=back

=head2 next_spectrum_result

    while (my $r = $idents->next_spectrum_result) {
        # do something
    }

Returns an C<MS::Reader::MzIdentML::SpectrumIdentificationResult> object
representing the next spectrum query in the file, or C<undef> if the end of records
has been reached. Typically used to iterate over each search query in the run.

=head2 fetch_spectrum_result

    my $r = $idents->fetch_spectrum_result($idx);

Takes a single argument (zero-based result index) and returns an
C<MS::Reader::MzIdentML::SpectrumIdentificationResult> object representing the
result at that index. Throws an exception if the index is out of range.

=head2 next_protein_group

    while (my $g = $idents->next_protein_group) {
        # do something
    }

Returns an C<MS::Reader::MzIdentML::ProteinAmbiguityGroup> object
representing the next protein group result in the file, or C<undef> if the end of records
has been reached. Typically used to iterate over each protein group in the run.

=head2 fetch_protein_group

    my $g = $idents->fetch_protein_group($idx);

Takes a single argument (zero-based result index) and returns an
C<MS::Reader::MzIdentML::ProteinAmbiguityGroup> object representing the
protein group at that index. Throws an exception if the index is out of range.

=head2 goto_ident_list

    $idents->goto_ident_list($idx);

Takes a single argument (zero-based list index) and sets the current spectrum
result list to that index (for subsequent calls to C<next_spectrum_result>).

=head2 n_ident_lists

    my $n = $idents->n_ident_lists;

Returns the number of spectrum identification lists in the file.

=head2 fetch_dbsequence_by_id

    my $seq = $idents->fetch_dbsequence_by_id( $seq_id );

Given a DBSequence element ID, returns the corresponding
L<MS::Reader::MzIdentML::DBSequence> object.

=head2 fetch_peptide_by_id

    my $pep = $idents->fetch_peptide_by_id( $pep_id );

Given a Peptide element ID, returns the corresponding
L<MS::Reader::MzIdentML::Peptide> object.

=head2 fetch_peptideevidence_by_id

    my $pe = $idents->fetch_peptideevidence_by_id( $pe_id );

Given a PeptideEvidence element ID, returns the corresponding
L<MS::Reader::MzIdentML::PeptideEvidence> object.

=head2 raw_file

    my $fn = $idents->raw_file($id);

Takes a single argument (ID of raw source) and returns the path on disk to the
raw file (as recorded in the mzIdentML).

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
