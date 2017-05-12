package Microarray::Reporter;

use 5.006;
use strict;
use warnings;
our $VERSION = '1.5';

# an array_reporter contains a number of spot objects
# the reporter objects are identified by a biologically relevant id
# the reporter summarises the averaged spot data
{ package array_reporter;

	sub new {
		my $class = shift;

		# require QC defaults
		die "Microarray::Reporter ERROR: Quality control variables not set\n" 
			unless (
				$ENV{ _LOW_SIGNAL_ }		&&
				$ENV{ _HIGH_SIGNAL_ }		&&
				$ENV{ _PERCEN_SAT_ }		&&
				$ENV{ _MIN_SNR_ }			&&
				$ENV{ _SIGNAL_QUALITY_ }	&&
				$ENV{ _MIN_DIAMETER_ } 		&&
				$ENV{ _MAX_DIAMETER_ }		&&
				$ENV{ _TARGET_DIAMETER_ }	&&
				$ENV{ _MAX_DIAMETER_DEVIATION_ }
			);
				
		my $self = { _id => shift, _spots => [] };
		bless $self, $class;		
		return $self;
	}
	sub get_reporter_ratios {
		my $self = shift;
		my $hAnalysed_Data = { };
		$hAnalysed_Data->{ M_mean_of_ratios } = $self->mean_log_ratios;
		$hAnalysed_Data->{ M_ratio_of_means } = $self->log_ratio_means;
		$hAnalysed_Data->{ ch1_mean } = $self->mean_ch1;
		$hAnalysed_Data->{ ch2_mean } = $self->mean_ch2;
		return $hAnalysed_Data;
	}	
	# genetic_data() will set some relevant value(s)
	# usually, a sub-class such as bac_reporter or gene_reporter 
	# will have its own methods for getting and setting the genetic data
	sub genetic_data {
		my $self = shift;
		@_	?	$self->{ _genetic_data } = shift
			:	$self->{ _genetic_data };
	}
	# reporter_id() will be an alias for the genetic reporter id
	sub reporter_id {
		my $self = shift;
		$self->{ _id };
	}
	sub add_reporter_spot {
		my $self = shift;
		my $aSpots = $self->get_reporter_spots;
		push (@$aSpots, shift);	
	}
	sub get_reporter_spots {
		my $self = shift;
		$self->{ _spots };
	}
	sub get_reporter_replicates {
		my $self = shift;
		my $aSpots = $self->get_reporter_spots;
		if (@$aSpots){
			my $replicates = @$aSpots;
			return $replicates;
		} else {
			return;
		}
	}
	
	#******************* SPOT QUALITY CONTROL VARIABLES *************************
	# These are set as environment variables, not to individual feature objects
	# Typically, these would be set within a Microarray object, 
	# (which defines defaults on initialisation) but could be set manually in a script 
	#****************************************************************************
	
	sub do_spot_qc {
		my $self = shift;
		my $aSpots = $self->get_reporter_spots;
		
		my $hBad_Flags = $ENV{ _BAD_FLAGS_ };	# from a Data File object
		
		SPOT: for my $oSpot (@$aSpots) {
			$oSpot->spot_status(0); 	# set spot to 'rejected' at start
			next SPOT if (defined $hBad_Flags->{ $oSpot->flag_id });
			unless ($ENV{ _ignore_signal_qa }){
				######## SIGNAL QUALITY ASSESSMENTS ########
				if (($oSpot->channel1_signal < $ENV{ _LOW_SIGNAL_ }) 		||
					($oSpot->channel1_signal > $ENV{ _HIGH_SIGNAL_ })		||
					($oSpot->channel1_sat && ($oSpot->channel1_sat > $ENV{ _PERCEN_SAT_ }))			||
					($oSpot->channel1_snr < $ENV{ _MIN_SNR_ })				||
					($oSpot->channel1_quality < $ENV{ _SIGNAL_QUALITY_ })	||
					($oSpot->channel2_signal < $ENV{ _LOW_SIGNAL_ }) 		||
					($oSpot->channel2_signal > $ENV{ _HIGH_SIGNAL_ }) 		||
					($oSpot->channel2_sat && ($oSpot->channel2_sat > $ENV{ _PERCEN_SAT_ }))			||
					($oSpot->channel2_snr < $ENV{ _MIN_SNR_ })				||
					($oSpot->channel2_quality < $ENV{ _SIGNAL_QUALITY_ }) ){
					next SPOT;			
				} 
			}
			unless ($ENV{ _ignore_spot_qa }){
				######## SPOT QUALITY ASSESSMENTS ########
				if (($oSpot->spot_diameter < $ENV{ _MIN_DIAMETER_ }) 		|| 
					($oSpot->spot_diameter > $ENV{ _MAX_DIAMETER_ })){
					next SPOT;			
				} 
			}		
			# spot passes quality assessment
			$oSpot->spot_status(1);
			$self->good_spot; 
			# for calculation of feature signal ratios
			$self->all_ch1($oSpot->channel1_signal);
			$self->all_ch2($oSpot->channel2_signal);
			# for some plots
			$self->x_pos($oSpot->x_pos);
			$self->y_pos($oSpot->y_pos);
			unless ($oSpot->channel2_signal == 0){
				$self->all_ratios(($oSpot->channel1_signal)/($oSpot->channel2_signal));
			}
		}
		if ($ENV{ REJECT_UNIQUE } && ($self->spots_passed_qc < 2)){
			$self->reset_data;
		}
	}
	sub good_spot {
		my $self = shift;
		$self->{ _spots_passed_qc }++;
	}
	sub spots_passed_qc {
		my $self = shift;
		$self->{ _spots_passed_qc };
	}
	sub reset_data {
		my $self = shift;
		$self->{ _all_ch1 } = [];
		$self->{ _all_ch2 } = [];
		$self->{ _all_ratios } = [];
	}
	# for the following methods, shifting a single value
	# unlike similar methods in Microarray, which shift these array refs
	sub all_ch1 {
		my $self = shift;
		unless (defined $self->{ _all_ch1 }){
			$self->{ _all_ch1 } = [];
		}
		if (@_){
			my $aCh1_Signals = $self->{ _all_ch1 };
			push (@$aCh1_Signals, shift);
		} else {
			$self->{ _all_ch1 };
		}
	}
	sub all_ch2 {
		my $self = shift;
		unless (defined $self->{ _all_ch2 }){
			$self->{ _all_ch2 } = [];
		}
		if (@_){
			my $aCh2_Signals = $self->{ _all_ch2 };
			push (@$aCh2_Signals, shift);
		} else {
			$self->{ _all_ch2 };
		}
	}
	sub all_ratios {
		my $self = shift;
		unless (defined $self->{ _all_ratios }){
			$self->{ _all_ratios } = [];
		}
		if (@_){
			my $aRatios = $self->{ _all_ratios };
			push (@$aRatios, shift);
		} else {
			$self->{ _all_ratios };
		}
	}
	sub x_pos {
		my $self = shift;
		unless (defined $self->{ _x_pos }){
			$self->{ _x_pos } = [];
		}
		if (@_){
			my $aX_Pos = $self->{ _x_pos };
			push (@$aX_Pos, shift);
		} else {
			$self->{ _x_pos };
		}
	}
	sub y_pos {
		my $self = shift;
		unless (defined $self->{ _y_pos }){
			$self->{ _y_pos } = [];
		}
		if (@_){
			my $aY_Pos = $self->{ _y_pos };
			push (@$aY_Pos, shift);
		} else {
			$self->{ _y_pos };
		}
	}
	##########
	
	sub mean_ch1 {
		my $self = shift;
		if (my $sig = stats_or_return($self->all_ch1)){
			return $sig;
		} else {
			return 0;
		}
	}
	sub mean_ch2 {
		my $self = shift;
		if (my $sig = stats_or_return($self->all_ch2)){
			return $sig;
		} else {
			return 0;
		}
	}
	sub mean_ratios {
		my $self = shift;
		stats_or_return($self->all_ratios);
	}
	sub stats_or_return {
		my $aValues = shift;
		if (@$aValues > 1){
			return mean_values($aValues);
		} elsif (@$aValues == 1){
			return $$aValues[0];
		} else {
			return;
		}
	}
	sub ratio_means {
		my $self = shift;
		if ($self->mean_ch2 > 0){
			return ($self->mean_ch1) / ($self->mean_ch2);
		} else {
			return;
		}
	}
	sub log_ratio_means {
		my $self = shift;
		return calculate_log2($self->ratio_means);
	}
	sub mean_log_ratios {
		my $self = shift;
		my $aLog_Ratios = calculate_log2($self->all_ratios);
		return mean_values($aLog_Ratios);
	}
	sub mean_values {
		my $aValues = shift;
		my $sum;
		for my $value (@$aValues){
			next unless $value;
			$sum += $value;
		}
		if ($sum){
			return $sum/scalar(@$aValues);
		} else {
			return 0;
		}
	}
	sub calculate_log2 {
		my $value = shift;
		if (ref $value){
			my @aLog_Value = ();
			for my $val (@$value){
				next if ($val<=0);
				my $log_val = log ($val) / log(2);
				push(@aLog_Value,$log_val);
			}
			return \@aLog_Value;
		} else {
			return if ($value<=0);
			return log ($value) / log(2);
		}
	}	
}

1;


__END__

=head1 NAME

Microarray::Reporter - A Perl module for creating and manipulating microarray reporter objects

=head1 SYNOPSIS

	my $oArray = microarray->new($barcode,$data_file);	
	$oArray->set_reporter_data;
	
	my $oReporter = $oArray->get_reporter('RP11-354D4');  	# returns a single reporter object
	my $oReporter = array_reporter->new('reporter 1');
	$oReporter->add_reporter_spot($oSpot);
	$oReporter->do_spot_qc;
	my $mean_log_ratio = $oReporter->mean_log_ratios;

=head1 DESCRIPTION

Microarray::Reporter is an object-oriented Perl module for creating and manipulating microarray reporter objects. It serves as a container into which you place spot objects that are replicates of the same genetic reporter, and returns average information about those spots. 

=head1 METHODS

=over

=item B<do_spot_qc>

Performs QC on the spot level data. This uses a number of variables whose defaults are set by the L<Microarray|Microarray> module during initialisation of a Microarray object, and whose values can be changed using appropriate L<Microarray|Microarray.pm> methods. The L<Microarray|Microarray.pm> method L<should_reject_unique()|Microarray/"should_reject_unique"> causes the QC process to reject any reporter that contains only a single spot. It should be called on the microarray object before the L<set_reporter_data()|Microarray/"set_reporter_data"> method. 

=item B<reporter_id>

Name of the reporter

=item B<genetic_data>

An object containing relevant genetic data. 

=item B<get_reporter_spots>

Returns a list of spot objects attributed to a reporter

=item B<get_reporter_replicates>

Returns the number of spots attributed to a reporter

=item B<spots_passed_qc>

Returns the number of spots that passed QC criteria and are included in the reporter data

=item B<mean_ch1> and B<mean_ch2>

Mean signal of all spots representing a reporter

=item B<mean_ratios> and B<mean_log_ratios>

Calculates the ratio (or log2 ratio) between the two signal channels for each replicate, and returns the mean of those values

=item B<ratio_means> and B<log_ratio_means>

Calculates the mean of the replicate signals for each channel, and returns their ratio (or log2 ratio)

=back

=head1 SEE ALSO

L<Microarray|Microarray>, L<Microarray::Spot|Microarray::Spot>

=head1 AUTHOR

Christopher Jones, Gynaecological Cancer Research Laboratories, Institute for Women's Health, University College London.

L<http://www.instituteforwomenshealth.ucl.ac.uk/AcademicResearch/Cancer/trl>

c.jones@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Christopher Jones, University College London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

