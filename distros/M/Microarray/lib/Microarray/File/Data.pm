package Microarray::File::Data;

use 5.006;
use strict;
use warnings;
our $VERSION = '2.22';

require Microarray::File;
require Microarray::Spot;

{ package data_file;

	our @ISA = qw( delimited_file );

	sub new {
		my $class = shift;
		my $self = { };
		if (@_){		
			$self->{ _file_name } = shift;		# shift in file name
			bless $self, $class;
			$self->set_filehandle(shift) if (@_);	# Fh is passed from CGI
			if ($class eq 'data_file'){
				# try and guess which file type we're dealing with
				if(my $new_class = $self->guess_class){
					# we've found a better match, recreate ourself
					my $file_name = $self->file_name;
					my $source = $self->get_source;
					$self = { 	_file_name => $file_name, 
								_source => $source
							};
					bless $self,$new_class;
				}
			}
			$self->import_data;
		} else {
			bless $self, $class;
		}
		return $self;
	}
	sub guess_class {
		use Module::List qw(list_modules);
		my $self = shift;
		
		my $source = $self->get_source;
		
		my $hModules = list_modules('Microarray::File::Data::',{list_modules=>1,list_prefixes=>1});
		for my $module (keys %$hModules){
			eval "require $module";	
			next unless ($module->can('auto_data_file'));
			if (my ($class,$search_term) = $module->auto_data_file){
				return $class if ($source =~ /$search_term/i);
			}
		}
		warn "Microarray::File::Data ERROR: Could not deduce the type of file from '".$self->file_name."'\n";
		return;
	}
	sub import_data {
		my $self = shift;
		my $aaData = $self->load_file_data;
		$self->sort_data($aaData);
	}

	# _spot_data 	= scanner data imported as array of arrays
	#Ê_data_fields	= column field names and indeces
	# _header_info	= scanner set up information from the data file header
	# _spots 		= spot objects	
	sub sort_data {
		my $self = shift;
		my $aaData = shift;
		$self->set_data_fields(shift @$aaData);	# method in class delimited_file
		$self->{ _spot_data } = $aaData;		# all the numbers
		$self->{ _spot_count } = scalar @$aaData;
	}
	# not anything to do with the above, but instead is the data 
	# sorted on any specific field other than spot_index - 
	# used to discriminate processed_data from other data
	sub comes_sorted {
		return;
	}
	# the size of the data array after removing data fields
	# for the number of spot OBJECTS created, use number_spots()
	sub spot_count {
		my $self = shift;
		$self->{ _spot_count };
	}
	sub import_header_info {					# import a hash ref containing header information
		my $self = shift;
		$self->{ _header_info } = shift;
	}
	# sets spot objects for all data in one go
	sub set_spot_objects {
		my $self = shift;
		my $aaData = $self->spot_data;
		my $aData_Fields = $self->data_file_fields;				# required data fields from any data file format
		my $spot_object_count	= 0; 							# count of number of objects created
		for (my $i=0; $i<@$aaData; $i++){	
			my $oSpot = array_spot->new();						# new spot object
			for my $field (@$aData_Fields){						# each spot field name
				$oSpot->$field($self->$field($i));				#Êfill the spot object with the spot_row data
			}
			# add spot object to data_file
			$self->add_spot($oSpot);
			$spot_object_count++;
		}
		$self->number_spots($spot_object_count);
	}
	# the data array
	sub spot_data {
		my $self = shift;
		$self->{ _spot_data };
	}
	# return a spot object for a specific index
	sub spot_object {
		my $self = shift;
		my $index = shift;
		if (my $oSpot = $self->get_spots($index)){
			return $oSpot;
		} else {
			my $aData_Fields = $self->data_file_fields;	 		# required data fields from any data file format
			my $oSpot = array_spot->new();						# new spot object
			for my $field (@$aData_Fields){						# each spot field name
				$oSpot->$field($self->$field($index-1));		#Êfill the spot object with the spot_row data
			}
			return $oSpot;
		}
	}
	
	# adds spot objects to the arrayref held in { _spots }
	# NOTE: the zero index in this arrayref is a count of the total number of spots, 
	# and spots are placed in the array index corresponding to their "spot index"
	sub add_spot {
		my $self = shift;
		my $oSpot = shift;
		my $aSpots = $self->get_spots;
		$$aSpots[ $oSpot->spot_index ] = $oSpot;
	}
	# the total number of spot OBJECTS in the array
	# for number of spots counted from data array length, use spot_count() 
	sub number_spots {
		my $self = shift;
		my $aSpots = $self->get_spots;
		if (@_){
			$$aSpots[0] = shift;	# set from set_spot_objects()
		} else {
			$$aSpots[0];	# first index is the number of spots
		}
	}
	# the spots objects are stored as an array ref
	# each spot is placed at the array index that matches the spot index
	# THEREFORE THE INDEX[0] DOES NOT CONTAIN A SPOT!
	sub get_spots {
		my $self = shift;
		unless (defined $self->{ _spots }){
			$self->{ _spots } = [];
		}
		if (@_) { 	# passed a spot index
			my $index = shift;
			return unless (defined $self->{ _spots }[$index]);
			$self->{ _spots }[$index];
		} else {	# return all objects
			$self->{ _spots };
		}
	}
	sub data_file_fields {	# minimum required fields
		[	'spot_index','feature_id','synonym_id',
			'channel1_signal','channel2_signal',
			'channel1_quality','channel2_quality',
			'block_row','block_col',
			'spot_diameter','flag_id',
			'spot_row','spot_col','x_pos','y_pos', 
			'ch1_mean_f','ch1_median_b','ch2_mean_f','ch2_median_b',
			'channel1_snr','channel2_snr',
			'log2_ratio'];
	}
	sub return_data {
		my $self = shift;
		my $aaData = $self->spot_data;
		return $aaData->[shift][shift];
	}
	sub image_file_names {
		my $self = shift;
		return ($self->channel1_image_file,$self->channel2_image_file);
	}
	sub fluor_names {
		my $self = shift;
		return ($self->channel1_name,$self->channel2_name);
	}
	sub laser_powers {
		my $self = shift;
		return ($self->channel1_laser,$self->channel2_laser);
	}
	sub pmt_voltages {
		my $self = shift;
		return ($self->channel1_pmt,$self->channel2_pmt);
	}

	### calculated fields ###
	sub channel1_signal {
		my $self = shift;
		my $index = shift;
		$self->ch1_mean_f($index) - $self->ch1_median_b($index);
	}
	sub channel2_signal {
		my $self = shift;
		my $index = shift;
		$self->ch2_mean_f($index) - $self->ch2_median_b($index);
	}
	sub log2_ratio {
		my $self = shift;
		my $index = shift;
		my $ch1 = $self->channel1_signal($index);
		my $ch2 = $self->channel2_signal($index);
		return if (($ch1 <= 0) || ($ch2 <= 0));
		if ($self->flip_flop == 1){
			return log($ch1/$ch2)/log(2);
		} else {
			return log($ch2/$ch1)/log(2);
		}
	}
	sub flip_flop {
		my $self = shift;
		if (defined $self->{ _flip_flop }){
			$self->{ _flip_flop };
		} else {
			return 1;
		}
	}
	sub flip {
		my $self = shift;
		$self->{ _flip_flop } = -1;
	}
	sub flop {
		my $self = shift;
		$self->{ _flip_flop } = 1;
	}
	sub channel_signal {
		my $self = shift;
		my $index = shift;
		my $ch = shift;
		my $method = 'channel'.$ch.'_signal';
		$self->$method($index);
	}
	sub channel1_snr {
		my $self = shift;
		my $index = shift;
		$self->ch1_median_f($index) / $self->ch1_sd_b($index);
	}
	sub channel2_snr {
		my $self = shift;
		my $index = shift;
		$self->ch2_median_f($index) / $self->ch2_sd_b($index);
	}
	sub channel_snr {
		my $self = shift;
		my $index = shift;
		my $ch = shift;
		my $method = 'channel'.$ch.'_snr';
		$self->$method($index);
	}
	sub channel_quality {
		my $self = shift;
		my $index = shift;
		my $ch = shift;
		my $method = 'channel'.$ch.'_quality';
		$self->$method($index);
	}
	sub channel_sat {
		my $self = shift;
		my $index = shift;
		my $ch = shift;
		my $method = 'channel'.$ch.'_sat';
		$self->$method($index);
	}
	sub guess_barcode {
		use File::Basename;
		my $self = shift;
		my $file = basename($self->file_name);
		my @aName = split(/-|_| /,$file);
		return $aName[0];
	}
	sub channel_image_file {
		my $self = shift;
		my $ch = shift;
		my $method = "channel".$ch."_image_file";
		$self->$method;
	}
	sub num_channels {
		2
	}
	
}


1;


__END__

=head1 NAME

Microarray::File::Data - An object oriented Perl module describing microarray data files

=head1 SYNOPSIS

	use Microarray::File::Data;

	my $oFile = data_file->new('/results.txt');

=head1 DESCRIPTION

Microarray::File::Data provides methods for retrieving data from microarray data file objects. 

=head1 METHODS

=head2 Object creation

If you know the type of data file you are dealing with, then you should use the appropriate file module. However, if for some reason you don't know you can create a C<data_file> object and the module will attempt to create a file object of the correct type for you. This depends on the correct Plug-In module being present. If you write your own Plug-In module, you'll need to include a class-level method 'auto_data_file' in your module, which returns the package name of the file object and a search term that will identify an unknown file as the correct type.  

=head2 Spot object methods

=head3 Spot object creation

The module can create individual L<Microarray::Spot|Microarray::Spot> objects for you, either on-mass, or individually as you want them. The overhead for doing this is not huge, so if you have replicates that you want to handle using the L<Microarray::Reporter|Microarray::Reporter> module, this is a handy way to fill the reporter container. 

	$oFile->spot_object(123);				# sets and gets object for spot index 123

	$oFile->set_spot_objects;				# sets all spot objects
	my $oSpot = $oFile->spot_object(1234);	# spot object for spot index 1234

=over 4

=item B<set_spot_objects>

Creates spot objects for all spots.

=item B<spot_object>

Pass a spot index to this method to return the relevant spot object. If C<set_spot_objects> has not been called, this will create and return only this object. 

=item B<number_spots>

Returns the total number of spot objects created by C<set_spot_objects()>. 

=item B<get_spots>

Returns the spot objects as an array, where each index of the array matches that of the spot. (Therefore there is not a spot at index[0], but instead this element holds the number of spots!)

=back

=head2 Other methods

=over

=item B<image_file_names>, B<fluor_names>, B<laser_powers>, B<pmt_voltages>

Returns the relevant values for each analysed channel as a list. Will only work for file types that return the relevant information (for instance, BlueFuse does not return laser/PMT information).

=item B<guess_barcode>

In the event that a barcode is not present in the data file, will parse the file name and assume that the first portion of the name (using an underscore or hyphen as a delimiter) is the barcode. 

=item B<num_channels>

Defaults to two in the event that a file type is used which does not return the number of channels. 

=back

And many other methods that need no explanation;

=over

=item B<analysis_software, pixel_size, channel1_name, channel2_name, channel1_signal, channel2_signal, channel1_snr, channel2_snr, channel_quality, channel_sat, bad_flags>

Once again, not all file types will return the relevant information (BlueFuse does not return channel saturation or SNR). 

=back

=head1 TESTING

This distribution has been extensively tested, but does not include data files for testing purposes since they are very large. If you would like to run the full test you can download the files at L<http://www.instituteforwomenshealth.ucl.ac.uk/trl/pipeline/download.html>. 

=head1 SEE ALSO

L<Microarray|Microarray>, L<Microarray::File|Microarray::File>, L<Microarray::Spot|Microarray::Spot>

=head1 AUTHOR

Christopher Jones, Gynaecological Cancer Research Laboratories, Institute for Women's Health, University College London.

L<http://www.instituteforwomenshealth.ucl.ac.uk/AcademicResearch/Cancer/trl>

c.jones@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Christopher Jones, University College London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

