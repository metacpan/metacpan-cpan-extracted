#
#===============================================================================
#
#         FILE: Scan.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Felipe da Veiga Leprevost (Leprevost, F.V.), leprevost@cpan.org
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 07-10-2014 11:45:49
#     REVISION: ---
#===============================================================================
package MS2::Scan;

use strict;
use warnings;
use v5.12;
use Moose;
use namespace::autoclean;

has 'FirstScan' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'SecondScan' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'PrecursorMZ' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'RetTime' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'PrecursorInt' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'IonInjectionTime' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'ActivationType' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'PrecursorFile' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'PrecursorScan' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'InstrumentType' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'Charge' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'Mass' => (
    is  =>  'rw',
    isa =>  'Str',
    );

has 'DataMZ' => (
    is  =>  'rw',
    isa =>  'ArrayRef',
    default => sub { [] },
    );

has 'DataIntensity' => (
    is  =>  'rw',
    isa =>  'ArrayRef',
    default =>  sub { [] },
    );

sub parse {
    my $self = shift;
    my $line = shift;

    my @linepart = split(/\t/, $line);

    chomp $linepart[1] if $linepart[1];

    if ( $linepart[0] eq 'S' ) {
        
        $self->FirstScan($linepart[1]);
        $self->SecondScan($linepart[2]);
        $self->PrecursorMZ($linepart[3]);

    } elsif ( $linepart[0] eq 'I' ) {

        if ( $linepart[1] eq 'RetTime' ) {

            $self->RetTime($linepart[2]);

        } elsif ( $linepart[1] eq 'PrecursorInt' ) {

            $self->PrecursorInt($linepart[2]);

        } elsif ( $linepart[1] eq 'IonInjectionTime' ) {

            $self->IonInjectionTime($linepart[2]);

        } elsif ( $linepart[1] eq 'ActivationType' ) {

            $self->ActivationType($linepart[2]);

        } elsif ( $linepart[1] eq 'PrecursorFile' ) {

            $self->PrecursorFile($linepart[2]);

        } elsif ( $linepart[1] eq 'PrecursorScan' ) {

            $self->PrecursorScan($linepart[2]);

        } elsif ( $linepart[1] eq 'InstrumentType' ) {

            $self->InstrumentType($linepart[2]);
        }
        
    } elsif ( $linepart[0] eq 'Z' ) {

        $self->Charge($linepart[1]);
        $self->Mass($linepart[2]);

    } elsif ( $linepart[0] =~ m/^\d/ ) {

        my $dataMZ = $self->DataMZ;
        my @dataMZ = @{$dataMZ};

        my $dataInt = $self->DataIntensity;
        my @dataInt = @{$dataInt};

        my @datapart = split(/\s+/, $line);
        
        push(@dataMZ, $datapart[0]);
        push(@dataInt, $datapart[1]);

        $self->DataMZ(\@dataMZ);
        $self->DataIntensity(\@dataInt);
    }

}

1;
