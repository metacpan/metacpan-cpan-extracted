package Microarray::File::Image;

use 5.006;
use strict;
use warnings;
our $VERSION = '1.4';

{ package microarray_image_file;

	use Image::ExifTool;
	require Microarray::File;
	
	our @ISA = qw( microarray_file );
	
	sub new {
		my $class = shift;
		my $self = { };
		if (@_){		
			my $file_name = shift;
			$self->{ _file_name } = $file_name;		# shift in file name
			bless $self, $class;
			if ($class eq 'microarray_image_file'){
				# try and guess which file type we're dealing with
				my $class = $self->guess_class;
				unless ($class eq 'microarray_image_file'){
					# if we've found a better match, recreate ourself
					$self = { _file_name => $file_name };
					bless $self,$class;
				}
			}
			$self->import_data;
		} else {
			bless $self, $class;
		}
		return $self;
	}
	sub guess_class {
		my $self = shift;
		my $hInfo = $self->get_header_info;
		if ($hInfo->{ Model } =~ /GenePix/){
			return 'genepix_image';
		} elsif ($hInfo->{ Model } =~ /ScanArray/){
			return 'quantarray_image';
		} else {
			warn "Microarray::File::Image ERROR: Could not deduce the type of file from '".$self->file_name."'\n";
			return 'microarray_image_file';
		}
	}
	sub import_data {
		my $self = shift;
		$self->set_header_info;
	}
	sub set_exiftool_object {
		my $self = shift;
		my $exifTool = new Image::ExifTool;	
		$exifTool->ExtractInfo($self->file_name);		# extract info from file
		$self->{ _ExifTool_object } = $exifTool;
	}
	sub get_exiftool_object {
		my $self = shift;
		unless (defined $self->{ _ExifTool_object }){
			$self->set_exiftool_object;
		}
		$self->{ _ExifTool_object };
	}
	sub set_header_info {
		my $self = shift;
		my $exifTool = $self->get_exiftool_object;
		$self->{ _header_info } = $exifTool->GetInfo;
		$self->set_header_data;
	}
	sub set_header_data {
		return;
	}
	# get_header_info inherited from microarray_file class
	sub slide_barcode {
		my $self = shift;
		$self->guess_slide_barcode;
	}
	sub guess_slide_barcode {
		use File::Basename;
		my $self = shift;
		my $file = basename($self->file_name);
		my @aName = split(/-|_| /,$file);
		return $aName[0];
	}
}

1;

__END__

=head1 NAME

Microarray::File::Image - Perl objects for handling microarray image file formats

=head1 SYNOPSIS

	use Microarray::File::Image;

	my $array_file = microarray_image_file->new('/file.tif');  		# can pass just a filename...

=head1 DESCRIPTION

Microarray::File::Image - Perl objects for handling microarray image file formats. Support for managing image files is currently limited to parsing relevant image header information from microarray scanner images. 

=head1 METHODS

There are no generic methods for C<Microarray::File::Image> - see inheriting classes. 

=head1 SEE ALSO

L<Microarray|Microarray>, L<Microarray::File|Microarray::File>

=head1 AUTHOR

Christopher Jones, Gynaecological Cancer Research Laboratories, Institute for Women's Health, University College London.

L<http://www.instituteforwomenshealth.ucl.ac.uk/AcademicResearch/Cancer/trl>

c.jones@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Christopher Jones, University College London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

