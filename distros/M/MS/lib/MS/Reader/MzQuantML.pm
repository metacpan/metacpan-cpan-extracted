package MS::Reader::MzQuantML;

use strict;
use warnings;

use parent qw/MS::Reader::XML/;

use Carp;

use MS::CV qw/:MS/;

our $VERSION = 0.001;


sub _pre_load {

    my ($self) = @_;

    # ---------------------------------------------------------------------------#
    # These tables are the main configuration point between the parser and the
    # specific document schema. For more information, see the documentation
    # for the parent class MS::Reader::XML
    # ---------------------------------------------------------------------------#


    $self->{record_classes} = {
    };

    $self->{_skip_inside} = { map {$_ => 1} qw/
    / };

    $self->{_make_index} = { map {$_ => 'id'} qw/
    / };

    $self->{_make_named_array} = {
        cvParam   => 'accession',
        userParam => 'name',
    };

    $self->{_make_named_hash} = { map {$_ => 'id'} qw/
        Assay
        AssayQuantLayer
        BibliographicReference
        Cv
        DataProcessing
        Organization
        Person
        Feature
        FeatureQuantLayer
        FeatureList
        GlobalQuantLayer
        IdentificationFile
        MethodFile
        MS2AssayQuantLayer
        MS2StudyVariableQuantLayer
        PeptideConsensus
        PeptideConsensusList
        ProteinGroup
        Protein
        Provider
        RatioQuantLayer
        Ratio
        RawFile
        RawFilesGroup
        SearchDatabase
        SmallMolecule
        Software
        SourceFile
        StudyVariable
        StudyVariableQuantLayer

    / };

    $self->{_make_anon_array} = { map {$_ => 1} qw/
        Affiliation
        Column
        DBIdentificationRef
        EvidenceRef
        IdentificationRef
        Modification
        ProcessingMethod
        ProteinRef
        Row
    / };

}


1;


__END__

=head1 NAME

MS::Reader::MzQuantML - A simple but complete mzQuantML parser

=head1 SYNOPSIS

    use MS::Reader::MzQuantML;

    my $q = MS::Reader::MzQuantML->new('expt.');

=head1 DESCRIPTION

C<MS::Reader::MzQuantML> is a parser for the HUPO PSI standard mzQuantML
format for mass spectrometry quantification data. It aims to provide complete
access to the data contents while not being overburdened by detailed class
infrastructure.

NOTE: While the XML parser is complete, currently no accessors are implemented
for this module. Please check back for progress in this area.

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
