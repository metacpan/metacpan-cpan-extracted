package Microarray::File::Data::GenePix;

use 5.006;
use strict;
use warnings;
our $VERSION = '1.18';

sub auto_data_file {
	'genepix_file','genepix';
}

{ package genepix_file;

	require Microarray::File::Data;

	our @ISA = qw( data_file );

	# setter for { _spot_data }, { _data_fields } and { _header_info }
	sub sort_data {
		my $self = shift;
		my $aaData = shift;
		my $aFile_Format = shift @$aaData;
		my $aRow_Cols = shift @$aaData;
		my $header_rows = $$aRow_Cols[0];
		my $col_num = $$aRow_Cols[1];
		$self->set_header_info($aaData,$header_rows);
		$self->set_data_fields(shift @$aaData);
		$self->{ _spot_data } = $aaData;		# all the numbers
		$self->{ _spot_count } = scalar @$aaData;
	}
	# information about the scan
	sub set_header_info {
		my $self = shift;
		my $aaData = shift;
		my $header_rows = shift;
		my $hHeader_Info = { };
		for (my $i=1; $i<=$header_rows; $i++) {
			my $aLine = shift @$aaData;
			my ($key,$value) = split(/=/,$$aLine[0]);
			if ($value =~ /\t/){
				my @aValues = split(/\t/,$value);
				$hHeader_Info->{ "CH1 $key" } = $aValues[0];
				$hHeader_Info->{ "CH2 $key" } = $aValues[1];
			} else {
				$hHeader_Info->{ $key } = $value;
			}
		}
		$self->{ _header_info } = $hHeader_Info;
	}
	sub delimiter {
		return "\t";
	}
	sub pixel_size {
		my $self = shift;
		$self->get_header_info('PixelSize');
	}
	sub num_channels {
		2
	}
	sub channel1_name {
		'Cy5'
	}
	sub channel2_name {
		'Cy3'
	}
	sub channel_id {
		my $self = shift;
		my $ch = shift;
		"CH$ch";
	}
	sub channel_name {
		my $self = shift;
		my $ch = shift;
		my $method = "channel".$ch."_name";
		$self->$method;
	}	
	sub slide_barcode {
		my $self = shift;
		$self->get_header_info('Barcode');
	}
	sub gal_file {
		my $self = shift;
		$self->get_header_info('GalFile');
	}
	sub analysis_software {
		my $self = shift;
		$self->get_header_info('Creator');
	}
	sub scanner {
		my $self = shift;
		$self->get_header_info('Scanner');
	}
	sub user_comment {
		my $self = shift;
		$self->get_header_info('Comment');
	}
	sub channel1_image_file {
		my $self = shift;
		$self->get_header_info('CH1 FileName');
	}
	sub channel2_image_file {
		my $self = shift;
		$self->get_header_info('CH2 FileName');
	}
	sub channel_image_file {
		my $self = shift;
		my $ch = shift;
		$self->get_header_info("CH$ch FileName");
	}
	sub channel1_pmt {
		my $self = shift;
		$self->get_header_info('CH1 PMTVolts');
	}
	sub channel2_pmt {
		my $self = shift;
		$self->get_header_info('CH2 PMTVolts');
	}
	sub channel_pmt {
		my $self = shift;
		my $ch = shift;
		$self->get_header_info("CH$ch PMTVolts");
	}
	sub channel1_laser {
		my $self = shift;
		$self->get_header_info('CH1 LaserPower');
	}
	sub channel2_laser {
		my $self = shift;
		$self->get_header_info('CH2 LaserPower');
	}
	sub channel_laser {
		my $self = shift;
		my $ch = shift;
		$self->get_header_info("CH$ch LaserPower");
	}
	sub block_number {
		my $self = shift;
		if (@_){
			$self->{ _block_number } = shift;
		} else {
			unless (defined $self->{ _block_number }){
				$self->set_array_layout;
			}
			$self->{ _block_number };
		}
	}
	sub spot_columns {
		my $self = shift;
		if (@_){
			$self->{ _spot_columns } = shift;
		} else {
			unless (defined $self->{ _spot_columns }){
				$self->set_array_layout;
			}
			$self->{ _spot_columns };
		}
	}
	sub spot_rows {
		my $self = shift;
		if (@_){
			$self->{ _spot_rows } = shift;
		} else {
			unless (defined $self->{ _spot_rows }){
				$self->set_array_layout;
			}
			$self->{ _spot_rows };
		}
	}
	# this only works if the array is sorted by block/spot
	sub set_array_layout {
		my $self = shift;
		my $aaData = $self->spot_data;
		my $block_num = $self->get_column_id('Block');
		my $spot_row = $self->get_column_id('Row'); 
		my $spot_col = $self->get_column_id('Column'); 
		my $aLast_Row = $aaData->[-1];
		$self->block_number($aLast_Row->[$block_num]);
		$self->spot_columns($aLast_Row->[$spot_col]);
		$self->spot_rows($aLast_Row->[$spot_row]);
	}
	# data
	sub feature_id {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Name'));
	}
	sub synonym_id {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('ID'));
	}
	sub x_pos {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('X'));
	}
	sub y_pos {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Y'));
	}
	sub ch1_mean_f {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('F635 Mean'));
	}
	sub ch2_mean_f {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('F532 Mean'));
	}
	sub ch1_mean_b {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('B635 Mean'));
	}
	sub ch2_mean_b {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('B532 Mean'));
	}
	sub ch1_median_b {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('B635 Median'));
	}
	sub ch2_median_b {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('B532 Median'));
	}
	sub ch1_b1_sd {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('% > B635+1SD'));
	}
	sub ch2_b1_sd {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('% > B532+1SD'));
	}
	sub block_row {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Block'));
	}
	sub block_col {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Block'));
	}
	sub block {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Block'));
	}
	sub spot_row {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Row'));
	}
	sub spot_col {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Column'));
	}
	sub channel1_signal {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('F635 Mean - B635'));
	}
	sub channel2_signal {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('F532 Mean - B532'));
	}
	sub ch1_sd_b {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('B635 SD'));
	}
	sub ch2_sd_b {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('B532 SD'));
	}
	sub ch1_sd_f {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('F635 SD'));
	}
	sub ch2_sd_f {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('F532 SD'));
	}
	sub ch1_median_f {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('F635 Median'));
	}
	sub ch2_median_f {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('F532 Median'));
	}
	sub channel1_quality {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('% > B635+2SD'));
	}
	sub channel2_quality {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('% > B532+2SD'));
	}
	sub channel1_sat {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('F635 % Sat.'));
	}
	sub channel2_sat {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('F532 % Sat.'));
	}
	sub spot_diameter {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Dia.'));
	}
	sub spot_pixels {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('F Pixels'));
	}
	sub flag_id {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Flags'));
	}
	sub bad_flags {
		{ '-50'=>'1', '-75'=>'1' }
	}
}

{ package genepix_image;

	require Microarray::File::Image;

	our @ISA = qw( microarray_image_file );
	
	sub set_header_data {
		my $self = shift;
		my $hInfo = $self->get_header_info;
		my $info = $hInfo->{HostComputer}."; ".$hInfo->{Artist};
		$info =~ s/AxImageIO: //g;
		my @aInfo = split(/; /,$info);
		for my $data (@aInfo){
			if ($data =~ /PMT|Power|Barcode/){
				my ($field,$value) = split(/=/,$data);
				$hInfo->{ "_$field" } = $value;
			}
		}
	}
	sub image_user_name {
		return;
	}
	sub fluor_name {
	    return;
	}
	sub laser_id {
	    return;
	}
	sub filter_id {
	    return;
	}
	sub image_resolution {
	    my $self = shift;
	    my $hInfo = $self->get_header_info;
		my $res = $hInfo->{'XResolution'};
		return (10000/$res);
	}
	sub scan_speed {
	    return;
	}
	sub image_width {
		my $self = shift;
		my $hInfo = $self->get_header_info;
		return $hInfo->{'ImageWidth'};
	}
	sub image_height {
		my $self = shift;
		my $hInfo = $self->get_header_info;
		return $hInfo->{'ImageHeight'};
	}
	sub image_scanner {
		my $self = shift;
		my $hInfo = $self->get_header_info;
		return $hInfo->{'Model'};
	}
	sub laser_power {
		my $self = shift;
		my $hInfo = $self->get_header_info;
		return $hInfo->{'_ScanPower'};
	}
	sub laser_power_watts {
		my $self = shift;
		my $hInfo = $self->get_header_info;
		return $hInfo->{'_LaserPower'};
	}
	sub pmt_gain {
		my $self = shift;
		my $hInfo = $self->get_header_info;
		return $hInfo->{'_PMT'};
	}
	sub scan_power {
		my $self = shift;
		my $hInfo = $self->get_header_info;
		return $hInfo->{'_ScanPower'};
	}
	sub slide_barcode {
		my $self = shift;
		my $hInfo = $self->get_header_info;
		my $barcode = $hInfo->{'_Barcode'};
		if ($barcode) {
		  return $barcode;		
		} else {
			warn 	"Microarray::File::Data::GenePix WARNING: \n".
					"Image file '".$self->file_name."'\n".
					"Could not find a barcode in the image header - guessing its the first part of the file name\n";
			return $self->guess_slide_barcode;
		  }
	}
	sub image_name {
		my $self = shift;
		my $hInfo = $self->get_header_info;
		return $hInfo->{'FileName'};
	}
	sub image_description {
		my $self = shift;
		my $hInfo = $self->get_header_info;
		return $hInfo->{'ImageDescription'};
	}
	sub fluor_excitation {
		my $self = shift;
		my $wavelength = $self->image_description;
		if ($wavelength =~ s/ \[R1\]//){
			$wavelength =~ s/\(|\)//g;
		} else {
			$wavelength =~ s/ \[W\d\]//;
		}
		return $wavelength;
	}
	sub collection_software {
		my $self = shift;
		my $hInfo = $self->get_header_info;
		return $hInfo->{'Software'};
	}
	sub image_datetime {
		my $self = shift;
		my $hInfo = $self->get_header_info;
		return $hInfo->{'FileModifyDate'};
	}
}

1;

__END__

=head1 NAME

Microarray::File::Data::GenePix - A Perl module for managing microarray Axon GenePix data files

=head1 SYNOPSIS

	use Microarray::File::Data::GenePix;

	my $data_file = genepix_file->new("/file.csv");
	my $image_file = genepix_image->new("/image.tif");

=head1 DESCRIPTION

Microarray::File::Data::GenePix is an object-oriented Perl module for managing microarray data files created by Axon's GenePix software. It inherits from L<Microarray::File|Microarray::File>, and maps data fields in the GenePix file to those used by L<Microarray::File::Data|Microarray::File::Data>. This module also parses GenePix image header info, although the amount of information contained there is limited.

=head1 METHODS

=head2 genepix_file methods

Where a method exists for "channel1" in the following methods, there is an equivalent method for "channel2". 

=head3 General methods - typically retrieving information from the header

=over

=item B<pixel_size>

Measured in micrometers. 

=item B<channel1_name>

i.e. Cy3, or Cy5. 

=item B<channel1_image_file>

The full path of the image file when saved by GenePix.

=item B<gal_file>

The full path of the GAL file, when/if imported by GenePix during data extraction. 

=item B<user_comment>

No idea where this comes from. But its there in the data file.

=item B<block_number>

GenePix numbers blocks consecutively, and does not record their layout in terms of rows/columns. While it isn't really very useful in the real World, this method returns this number. 

=item B<spot_columns>, B<spot_rows>

Number of columns and rows of spots in each block.

=back

The following methods don't really need any explanation;

=over

=item B<analysis_software>, B<num_channels>, B<slide_barcode>, B<channel1_pmt>, B<channel1_laser>

=back

=head3 Spot methods 

Pass the data row index to these methods to return information for a particular spot. The first row of data is index 0.

=over

=item B<block>, B<spot_row>, B<spot_col>

While there are no C<'block_row'> or C<'block_col'> equivalents in a GenePix file, these methods can be used and will return the C<block_number>. Also note there is no C<'spot_index'> field in GenePix. And to think that Axon invented the array file format.....

=item B<feature_id>, B<synonym_id>

The 'Name' and 'ID' columns respectively. 

=item B<x_pos>, B<y_pos>

Spot centre location in pixels, from the top-left of the image. 

=item B<flag_id>

The flag associated with the spot. 

=item B<ch1_median_f, ch1_mean_f, ch1_sd_f>

Median, mean and SD values for the fluorescence measurements of spot pixels.

=item B<ch1_median_b, ch1_mean_b, ch1_sd_b>

Median, mean and SD values for the fluorescence measurements of background pixels.

=item B<ch1_b1sd, channel1_quality, channel1_sat>

The percent of spot pixels 1 SD above background, percent of spot pixels 2 SD above background, and percent of spot pixels that are saturated.

=item B<channel1_snr>

GenePix does not return signal-to-noise ratios, so this is calculated as the median signal/background SD.

=item B<spot_diameter>, B<spot_pixels>

Diameter is measured in microns. 

=back

=head2 genepix_image methods

GenePix can save images as individual TIFF files, or both images in a single file. Channel specific information, such as the laser power and PMT, is not available in the combined file. To be honest, Axon have completely missed the boat when it comes to understanding the point of having information in the TIFF header - there's very little here that helps you keep track of your experiments, other than the slide barcode. Compare the information here with what is returned from a L<ScanArray image header|Microarray::File::Data::Quantarray/"quantarray_image methods">, and you'll see what I mean.

=over

=item B<image_barcode>

Returns the slide barcode associated with the scan. 

=item B<fluor_excitation>

The wavelength of the laser used to generate the image. Returns both wavelengths from combined image files.

=item B<pmt_gain>, B<laser_power>, B<laser_power_watts>, B<scan_power>

PMT and laser powers used in the scan - return null from combined image files. laser_power() and scan_power() return the same value, which is the laser power as a percentage. laser_power_watts() returns that actual mW value of the laser power at the time of scanning. 

=item B<image_name>, B<image_width>, B<image_height>, B<image_datetime>

Basic image information.

=item B<image_scanner>, B<collection_software>

Scanner model and serial number, and some strange code that doesn't appear to have anything to do with the software version. Go figure....

=item B<image_resolution>

Returns the pixel size in microns. This is calculated from the 'XResolution' value, which describes how many pixels there are in a specified unit. For the Axon4000B this is set to 1cm, and although we haven't tested it for other Axon scanners we're assuming it is likely to be the same.  

=item Other methods returning undefined values

There are a few methods that return undefined values, for compatibility with other Microarray::File::Data modules (actually, that means ::Quantarray). These are image_user_name, fluor_name, laser_id and filter_id.  

=back

=head1 SEE ALSO

L<Microarray|Microarray>, L<Microarray::File|Microarray::File>, L<Microarray::File::Data|Microarray::File::Data>, L<Image::ExifTool|Image::ExifTool>

=head1 AUTHOR

Christopher Jones, Gynaecological Cancer Research Laboratories, Institute for Women's Health, University College London.

L<http://www.instituteforwomenshealth.ucl.ac.uk/AcademicResearch/Cancer/trl>

c.jones@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Christopher Jones, University College London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

