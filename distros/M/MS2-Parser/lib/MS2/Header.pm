#
#===============================================================================
#
#         FILE: Header.pm
#
#  DESCRIPTION: Representativa class for MS2 file headers.
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Felipe da Veiga Leprevost (Leprevost, F.V.), leprevost@cpan.org
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 07-10-2014 10:53:06
#     REVISION: ---
#===============================================================================

package MS2::Header;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'CreationDate' => (
    is  => 'rw',
	isa => 'Str',
    );

has 'Extractor' => (
	is  => 'rw',
	isa => 'Str',
    );

has 'ExtractorVersion' => (
	is  => 'rw',
	isa => 'Str',
    );

has 'Comments' => (
	is  => 'rw',
	isa => 'Str',
    );

has 'ExtractorOptions' => (	
	is  => 'rw',
	isa => 'Str',
    );

has 'AcquisitionMethod' => (	
	is  => 'rw',
	isa => 'Str',
    );

has 'InstrumentType' => (	
	is  => 'rw',
	isa => 'Str',
    );

has 'ScanType' => (	
	is  => 'rw',
	isa => 'Str',
    );

has 'DataType' => (	
	is  => 'rw',
	isa => 'Str',
    );

has 'IsolationWindow' => (	
	is  => 'rw',
	isa => 'Any',
    );

has 'FirstScan' => (	
	is  => 'rw',
	isa => 'Str',
    );

has 'LastScan' => (	
	is  => 'rw',
	isa => 'Str',
    );


sub parse {
    my $self = shift;
    my $line = shift;

    my @linepart = split(/\t/, $line);

    chomp $linepart[1];

    if ( $linepart[1] eq 'CreationDate' ) {

        $self->CreationDate($linepart[2]);

    } elsif ( $linepart[1] eq 'Extractor' ) {

        $self->Extractor($linepart[2]);

    } elsif ( $linepart[1] eq 'ExtractorVersion' ) {

        $self->ExtractorVersion($linepart[2]);

    } elsif ( $linepart[1] eq 'Comments' ) {

        $self->Comments($linepart[2]);

    } elsif ( $linepart[1] eq 'ExtractorOptions' ) {

        $self->ExtractorOptions($linepart[2]);

    } elsif ( $linepart[1] eq 'AcquisitionMethod' ) {

        $self->AcquisitionMethod($linepart[2]);

    } elsif ( $linepart[1] eq 'InstrumentType' ) {

        $self->InstrumentType($linepart[2]);

    } elsif ( $linepart[1] eq 'ScanType' ) {

        $self->ScanType($linepart[2]);

    } elsif ( $linepart[1] eq 'DataType' ) {

        $self->DataType($linepart[2]);

    } elsif ( $linepart[1] eq 'IsolationWindow' ) {

        $self->IsolationWindow($linepart[2]);

    } elsif ( $linepart[1] eq 'FirstScan' ) {

        $self->FirstScan($linepart[2]);

    } elsif ( $linepart[1] eq 'LastScan' ) {

        $self->LastScan($linepart[2]);

    } else {

        say "\nUnrecognized Tag: $linepart[1] ignored\n";
    }

}
 

1;
