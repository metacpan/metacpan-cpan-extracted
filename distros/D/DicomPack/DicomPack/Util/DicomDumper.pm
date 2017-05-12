##############################################################################
# DicomDumper.pm -- a module to dump the conent of a dicom file to stdout
#
# Copyright (c) 2010 Baoshe Zhang. All rights reserved.
# This file is part of "DicomPack". DicomReader is free software. You can 
# redistribute it and/or modify it under the same terms as Perl itself.
##############################################################################

package DicomPack::Util::DicomDumper;

use strict;
use warnings;

use DicomPack::IO::DicomReader;

our $VERSION = '0.95';

sub new
{
	my $classname = shift;
	my $self = {};	
	bless $self, $classname;
	return $self;
}

# dump the content of a dicom file
sub dump
{
	my $self = shift;
	my $infile = shift;
	my $verbose = shift;

	$verbose = 0 unless defined $verbose;
	$verbose = 0 unless $verbose =~ /^[0-2]$/;

	my $reader = DicomPack::IO::DicomReader->new($infile);

	$reader->showDicomField($verbose);
}

1;

__END__

=head1 NAME

DicomDumper - dump the content of a dicom file to stdout

=head1 SYNOPSIS

    use DicomPack::Util::DicomDumper;
    my $dumper  = DicomPack::Util::DicomDumper->new();
    my $inDicomFile = "your dicom file";
    $dumper->dump($inDicomFile, $verbose);


=head1 DESCRIPTION

This module dumps the content of a dicom file to stdout.

=head2 Methods

=over 12

=item C<new>

Returns a new DicomDumper object.

=item C<dump>

Dump the content of a dicom file to stdout. 

=over 4

=item Input parameter(s): 

=over 4

=item 1. 

A path to a dicom file.

=item 2.

Verbose level. Available values: 0, 1, 2. By default, 0.

=back

=back

=back

=head1 AUTHOR

Baoshe Zhang, MCV Medical School, Virginia Commonwealth University

=cut

