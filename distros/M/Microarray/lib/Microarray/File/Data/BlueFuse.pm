package Microarray::File::Data::BlueFuse;

use 5.006;
use strict;
use warnings;
our $VERSION = '1.23';

require Microarray::File::Data;

sub auto_data_file {
	('bluefuse_file','bluefuse');
}

{ package bluefuse_post_file;

	our @ISA = qw( bluefuse_file );

	# should include methods for getting/setting extra header info at some point
	# for now, this class simply deals with the lack of some values in post files

	sub man_excl {
		return "no";
	}
	sub auto_excl {
		return "no";
	}
	sub spot_index {
		my $self = shift;
		my $index = shift;
		return ($index + 1);
	}
	
}

{ package bluefuse_file;

	our @ISA = qw( data_file );

	# setter for { _spot_data }, { _data_fields } and { _header_info }
	sub sort_data {
		my $self = shift;
		my $aaData = shift;		
		$self->set_header_info($aaData);
		$self->set_data_fields(shift @$aaData);
		$self->{ _spot_data } = $aaData;		# all the numbers
		$self->{ _spot_count } = scalar @$aaData;
	}
	
	# information about the scan
	sub set_header_info {
		my $self = shift;
		my $aaData = shift;
		my $hHeader_Info = { };
		my ($flags,$qc);
		
		while (my $aRow = shift @$aaData){
		
			next unless (@$aRow);
			if ($$aRow[0] eq 'ROW'){
				unshift(@$aaData,$aRow);	
				last;
			} elsif ($$aRow[0] =~ /#/){
				next;
			} elsif ($$aRow[0] =~ /^Created by/){
				my $value = $$aRow[0];
				$value =~ s/Created by //;
				$hHeader_Info->{ VERSION } = $value;
			} elsif ($$aRow[0] =~ /ARRAY QC START:/){
				$qc++;
			} elsif ($$aRow[0] =~ /ARRAY QC END:/){
				$qc = undef;
			} elsif ($qc) {
				if ($$aRow[0] eq 'Confidence Flags (%)'){
					$flags++;
				} elsif ($flags){
					$hHeader_Info->{ 'Confidence Flags (%)' } = {
						A => $$aRow[2], 
						B => $$aRow[3],
						C => $$aRow[4],
						D => $$aRow[5],
						E => $$aRow[6]
					};
					$flags = undef;
				} else {
					$hHeader_Info->{ $$aRow[0] } = $$aRow[3];
				}
			} else {
				my ($key,$value) = split(/: /,$$aRow[0]);
				if ($key eq 'CONFIDENCE FLAGS'){
					my @aFlag_Estimates = split(/, /,$value);
					my $hFlag_Ranges = { };
					for my $flag_range (@aFlag_Estimates){
						my ($start,$flag,$end) = split(/ < /,$flag_range);
						$hFlag_Ranges->{ $flag } = [$start,$end];
					}
					$value = $hFlag_Ranges;
				}
				$hHeader_Info->{ $key } = $value;
			}	
		}
		$self->{ _header_info } = $hHeader_Info;
	}
	sub delimiter {
		return "\t";
	}
	
	### header info getters ###
	
	#Êbarcode not saved in bluefuse file
	#Êhave to guess from data_file method
	sub slide_barcode {
		my $self = shift;
		$self->guess_barcode;
	}
	sub analysis_software {
		my $self = shift;
		$self->get_header_info('VERSION');
	}
	sub build {
		my $self = shift;
		$self->get_header_info('BUILD');
	}
	sub date {
		my $self = shift;
		$self->get_header_info('DATE');
	}
	sub experiment {
		my $self = shift;
		$self->get_header_info('EXPERIMENT');
	}
	sub channel1_image_file {
		my $self = shift;
		$self->get_header_info('CH1');
	}
	sub channel2_image_file {
		my $self = shift;
		$self->get_header_info('CH2');
	}
	sub frame_ch1 {
		my $self = shift;
		$self->get_header_info('FRAME CH1');
	}
	sub frame_ch2 {
		my $self = shift;
		$self->get_header_info('FRAME CH2');
	}
	sub gal_file {
		my $self = shift;
		$self->get_header_info('GAL');
	}
	sub clone_file {
		my $self = shift;
		$self->get_header_info('CLONEFILE');
	}
	sub clone_text {
		my $self = shift;
		$self->get_header_info('CLONETEXT');
	}
	sub confidence_flag_range {
		my $self = shift;
		my $hFlags = $self->get_header_info('CONFIDENCE FLAGS');
		if(@_){
			my $flag = shift;
			if (wantarray()) {
				return @{ $hFlags->{ $flag } };
			} else {
				return $hFlags->{ $flag };
			}
		} elsif (wantarray()) {
			return ($$hFlags{E}[0],$$hFlags{E}[1],$$hFlags{D}[1],$$hFlags{C}[1],$$hFlags{B}[1],$$hFlags{A}[1]);
		} else {
			return $hFlags;	# a hashref
		}
	}
	sub replicate_field {
		my $self = shift;
		return $self->get_header_info('IDENTIFY REPLICATES BY');
	}
	sub confidence_flag_percen {
		my $self = shift;
		my $hFlags = $self->get_header_info('Confidence Flags (%)');
		if(@_){
			my $flag = shift;
			return $hFlags->{ $flag };
		} elsif (wantarray()) {
			return ($hFlags->{A},$hFlags->{B},$hFlags->{C},$hFlags->{D},$hFlags->{E});
		} else {
			return $hFlags;	# a hashref
		}
	}
	sub log_ratio_sd {
		my $self = shift;
		return $self->get_header_info('SD of Log2Ratio');
	}
	sub rep_median_sd {
		my $self = shift;
		return $self->get_header_info('Median SD Between Replicates');
	}
	sub mean_ch1_amp {
		my $self = shift;
		return $self->get_header_info('Mean Ch1 Spot Amplitude');
	}
	sub mean_ch2_amp {
		my $self = shift;
		return $self->get_header_info('Mean Ch2 Spot Amplitude');
	}
	sub sbr_ch1 {
		my $self = shift;
		return $self->get_header_info('SBR Ch1');
	}
	sub sbr_ch2 {
		my $self = shift;
		return $self->get_header_info('SBR Ch2');
	}
	sub array_columns {
		my $self = shift;
		if (@_){
			$self->{ _array_columns } = shift;
		} else {
			unless (defined $self->{ _array_columns }){
				$self->set_array_layout;
			}
			$self->{ _array_columns };
		}
	}
	sub array_rows {
		my $self = shift;
		if (@_){
			$self->{ _array_rows } = shift;
		} else {
			unless (defined $self->{ _array_rows }){
				$self->set_array_layout;
			}
			$self->{ _array_rows };
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
		my $block_row = $self->get_column_id('ROW');
		my $block_col = $self->get_column_id('COL');
		my $spot_row = $self->get_column_id('SUBGRIDROW'); 
		my $spot_col = $self->get_column_id('SUBGRIDCOL'); 
		my $aLast_Row = $aaData->[-1];
		$self->array_columns($aLast_Row->[$block_col]);
		$self->array_rows($aLast_Row->[$block_row]);
		$self->spot_columns($aLast_Row->[$spot_col]);
		$self->spot_rows($aLast_Row->[$spot_row]);
	}
	### data file fields ###	
	sub spot_index {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('SPOTNUM'));
	}
	sub block_row {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('ROW'));
	}
	sub block_col {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('COL'));
	}
	sub spot_row {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('SUBGRIDROW'));
	}
	sub spot_col {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('SUBGRIDCOL'));
	}
	sub block {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('BLOCK'));
	}
	sub feature_id {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('NAME'));
	}
	sub synonym_id {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('ID'));
	}
	sub confidence {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('CONFIDENCE'));
	}
	sub flag_id {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('FLAG'));
	}
	sub man_excl {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('MAN EXCL'));
	}
	sub auto_excl {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('AUTO EXCL'));
	}
	sub ch1_mean_f {
		my $self = shift;
		$self->channel1_signal(shift);
	}
	sub ch2_mean_f {
		my $self = shift;
		$self->channel2_signal(shift);
	}
	# fudge to return some kind of snr value where required
	# quality=PONCH, which is a 0-1 measure of biological signal
	sub channel1_snr {
		my $self = shift;
		$self->channel1_quality(shift);
	}
	sub channel2_snr {
		my $self = shift;
		$self->channel2_quality(shift);
	}
	sub channel1_signal {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('AMPCH1'));
	}
	sub channel2_signal {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('AMPCH2'));
	}
	# bluefuse doesn't return a % sat value, 
	# and actually can return a signal value higher than 65536
	# if signal > 65536, we'll call that channel 100% saturated
	sub channel1_sat {
		my $self = shift;
		if ($self->channel1_signal(shift) > 65536){
			return 100;
		} else {
			return;
		}
	}
	sub channel2_sat {
		my $self = shift;
		if ($self->channel2_signal(shift) > 65536){
			return 100;
		} else {
			return;
		}
	}
	sub ch1_median_b {
		1
	}
	sub ch2_median_b {
		1
	}
	sub ratio_ch1ch2 {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('RATIO CH1/CH2'));
	}
	sub ratio_ch2ch1 {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('RATIO CH2/CH1'));
	}
	sub log2ratio_ch1ch2 {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('LOG2RATIO CH1/CH2'));
	}
	sub log2ratio_ch2ch1 {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('LOG2RATIO CH2/CH1'));
	}
	sub log2_ratio {
		my $self = shift;
		if ($self->flip_flop == 1){
			$self->log2ratio_ch1ch2(shift);
		} else {
			$self->log2ratio_ch2ch1(shift);
		}	
	}
	sub log10ratio_ch1ch2 {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('LOG10RATIO CH1/CH2'));
	}
	sub log10ratio_ch2ch1 {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('LOG10RATIO CH2/CH1'));
	}
	sub sumch1ch2 {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('SUM'));
	}
	sub log2sum {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('LOG2SUM'));
	}
	sub log10sum {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('LOG10SUM'));
	}
	sub product {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('PRODUCT'));
	}
	sub log2product {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('LOG2PRODUCT'));
	}
	sub log10product {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('LOG10PRODUCT'));
	}
	sub y_pos {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('PELROW'));
	}
	sub x_pos {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('PELCOL'));
	}
	sub channel1_quality {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('P ON CH1'));
	}
	sub channel2_quality {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('P ON CH2'));
	}
	sub spot_diameter {
		my $self = shift;
		return 2*($self->return_data(shift,$self->get_column_id('RADIUS')));
	}
	sub uniformity {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('UNIFORMITY'));
	}
	sub circularity {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('CIRCULARITY'));
	}
	sub grid_offset {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('GRID OFFSET'));
	}
	sub quality {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('QUALITY'));
	}
	sub chromosome {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('CHROMOSOME'));
	}
	sub position {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('POSITION'));
	}
	sub cyto_locn {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('CYTO LOCN'));
	}
	sub display {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('DISPLAY'));
	}
	
	sub omim {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('OMIM'));
	}
	
	sub disease {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('DISEASE'));
	}
	sub gc_content {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('GC CONTENT'));
	}	
	sub bad_flags {
		{ 'D'=>'1', 'E'=>'1' };
	}
}

1;

__END__

=head1 NAME

Microarray::File::Data::BlueFuse - A Perl module for managing BlueFuse 'output' files

=head1 SYNOPSIS

	use Microarray::File::Data::BlueFuse;
	my $data_file = bluefuse_file->new("/file.csv");

=head1 DESCRIPTION

Microarray::File::Data::BlueFuse is an object-oriented Perl module for managing microarray files created by BlueGnome's (L<http://www.bluegnome.co.uk/>) 'BlueFuse' software. It inherits from L<Microarray::File|Microarray::File>, and maps data fields in a BlueFuse 'output' data file to those used by L<Microarray::File::Data|Microarray::File::Data>. 

=head1 METHODS

=head2 General Header Information

=over

=item B<analysis_software>, B<build>, B<experiment>, B<frame_ch1>, B<frame_ch2>, B<gal_file>, B<clone_file>, B<clone_text>, B<channel1_image_file>, B<channel2_image_file>

These methods all return the relevant header information as a scalar.

=item B<confidence_flag_range>, B<confidence_flag_range($flag)>

Returns the confidence estimate range for each confidence flag. Passing a flag as an argument returns C<($start,$end)> for that flag. Alternatively if a list is requested it will return each division, starting at 0 and ending at 1, else will return a hashref of keys A to E and the range as an arrayref C<[$start,$end]>. 

=item B<slide_barcode>

Odd - BlueFuse does not return the barcode in the file header. So it has to guess it using the data_file method C<guess_barcode()>. Have asked the nice people at BlueGnome if they can fix this, and apparently they might, one day. 

=back

=head2 Array QC Header Information

=over

=item B<confidence_flag_percen>, B<confidence_flag_percen($flag)>

Returns the percentage of spots with each confidence flag. Passing a flag as an argument returns only the value for that flag. Alternatively if a list is requested it will return a list of values for flags A to E, else will return a hashref of keys A to E and their respective flag values.

=item B<log_ratio_sd>, B<rep_median_sd>, B<mean_ch1_amp>, B<mean_ch2_amp>, B<sbr_ch1>, B<sbr_ch2>

These methods all return the relevant header information as a scalar.

=back

=head2 Spot Information

Pass a spot index to any of these methods to retrieve the relevant value for that spot.

=over

=item B<block_row>, B<block_col>, B<spot_row>, B<spot_col>

The ROW, COL, SUBGRIDROW and SUBGRIDCOL columns - describing the grid location of the spot. 

=item B<feature_id>, B<synonym_id>

The NAME and ID columns - the unique identifiers of each spotted feature.

=item B<confidence>, B<flag_id>, B<man_excl>, B<auto_excl>

The CONFIDENCE, FLAG, MAN EXCL and AUTO EXCL columns. Flag confidence estimates can be returned separately (see above).  

=item B<ch1_mean_f>, B<ch2_mean_f>, B<channel1_signal>, B<channel2_signal>

Actually return the AMPCH1 and AMPCH2 columns - the spot signal. The C<ch_mean_f> methods are provided for compatibility with other modules which calculate signal and background separately, and in which the calculated signal is returned using the methods C<channel1_signal> and C<channel2_signal>. As a result, the methods C<ch1_median_b> and C<ch2_median_b> are also provided in this module, but will always return '0'. However, other values for signal and background (such as C<snr, median_f, sd_f, mean_b> and C<sd_b>) are not returned and will generate an error.

=item B<x_pos>, B<y_pos>

The PELROW and PELCOL columns - the spot coordinates, returning the top/left position of the spot. 

=item B<channel1_quality>, B<channel2_quality>

The P ON CH1 and P ON CH2 columns - estimates of the baysian probability that a biological signal is present in each channel

=item B<spot_diameter>, B<uniformity>, B<circularity>, B<grid_offset>, B<quality>

The 2*(RADIUS), UNIFORMITY, CIRCULARITY, QUALITY and GRID OFFSET columns.

=back

=head1 FUTURE DEVELOPMENT

At some point I plan to make this compatible with all of the BlueFuse file formats. While it has currently only been tested with the 'output' format, it might work with the other files. 

=head1 TESTING

This distribution does not include a data file for testing purposes, since the one used for the test is very large. If you would like to run the full test you can download the file at L<http://www.instituteforwomenshealth.ucl.ac.uk/trl/pipeline/download.html>.  

=head1 SEE ALSO

L<Microarray|Microarray>, L<Microarray::File|Microarray::File>, L<Microarray::File::Data|Microarray::File::Data>

=head1 AUTHOR

Christopher Jones, Gynaecological Cancer Research Laboratories, Institute for Women's Health, University College London.

L<http://www.instituteforwomenshealth.ucl.ac.uk/AcademicResearch/Cancer/trl>

c.jones@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Christopher Jones, University College London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

