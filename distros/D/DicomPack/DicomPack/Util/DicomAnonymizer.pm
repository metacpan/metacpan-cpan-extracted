##############################################################################
# DicomAnonymizer.pm -- a module to anonymize Dicom files
#
# Copyright (c) 2010 Baoshe Zhang. All rights reserved.
# This file is part of "DicomPack". DicomReader is free software. You can 
# redistribute it and/or modify it under the same terms as Perl itself.
##############################################################################

package DicomPack::Util::DicomAnonymizer;

use strict;
use warnings;

use DicomPack::IO::DicomReader;
use DicomPack::IO::DicomWriter;

our $VERSION = '0.95';

sub new
{
	my $classname = shift;
	my $self = {};	
	bless $self, $classname;
	return $self;
}

# get dicom fields from DICOM data file
sub anonymize
{
	my $self = shift;

	my $infile = shift;
	my $outfile = shift;

	my $anonymizedFieldList = shift;

	my $reader = DicomPack::IO::DicomReader->new($infile);
	my $dicomFields = $reader->getDicomField();

	my $writer = DicomPack::IO::DicomWriter->new($dicomFields);
	while(my ($tagPath, $tagValue) = each(%$anonymizedFieldList))
	{
		if(my ($value,$vr) = $reader->getValue($tagPath))
		{
			$writer->setValue($tagPath, $tagValue, $vr);
		}
		else
		{
			print $tagPath." : does not exists in $infile!!!\n";
		} 	
	}
	$writer->flush($outfile);
}

1;

__END__

=head1 NAME

DicomAnonymizer - A module to anonymize Dicom files

=head1 SYNOPSIS

    use DicomPack::Util::DicomAnonymizer;

    # get a DicomAnonymizer object
    my $anonymizer  = DicomPack::Util::DicomAnonymizer->new();

    # input and output Dicom files
    my $inDicomFile = "your dicom file";
    my $outDicomFile = "anonymized dicom file";

    # anonymize PatientName and PatientID
    $anonymizer->anonymize($inDicomFile, $outDicomFile, 
			{PatientName=>"NewPatientName", PatientID=>"NewPatientID"});


=head1 DESCRIPTION

This module anonymize (or change) the values of specified Dicom fields.

=head2 Methods

=over 12

=item C<new>

Returns a new DicomAnonymizer object.

=back

=item C<anonymize>

Anonymize the specified dicom fields with new values.

=over 4

=item Input parameter(s):

=over 4

=item 1.

A path to a to-be-anonymized dicom file

=item 2.

A path to the output anonymized dicom file

=item 3.

A hash reference (format: DicomFieldName=>"NewValue", DicomFieldName is the
Dicom tag path pointing to the dicom field whose value will be set to NewValue).

=back

=back

=head1 AUTHOR

Baoshe Zhang, Medical School, Virginia Commonwealth University.

=cut

