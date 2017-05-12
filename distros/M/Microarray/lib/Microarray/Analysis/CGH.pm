package Microarray::Analysis::CGH;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.9';

use Microarray::Analysis;

{ package cgh_analysis;

	our @ISA = qw( analysis );

	sub new {
		my $class = shift;
		my $self  = { };
		bless $self, $class;
		if (@_){
			$self->set_data(@_);
		} 
		return $self;
	}
	sub set_data {
		my $self = shift;
		while (my $oData = shift){
			$self->data_object($oData) if ($oData->isa('data_file') || $oData->isa('processed_data'));
			$self->clone_locns_file($oData) if $oData->isa('clone_locn_file');
			$self->cgh_call_object($oData) if ($oData->isa('processed_data') && $oData->cgh_call_data);
		} 
	}
	sub cgh_call_data {
		$ENV{ CGH_CALL_DATA };
	}
	sub cgh_call_object {
		my $self = shift;
		@_	?	$self->{ _cgh_call_object } = shift
			:	$self->{ _cgh_call_object };
	}
	# pass a feature_id to return its call value
	sub cgh_call {
		my $self = shift;
		if ($self->cgh_call_data){
			my $oCGH_Call = $self->cgh_call_object;
			return $oCGH_Call->cgh_call(shift);
		} else {
			return;
		}
	}
	# pass a feature_id to return its segment level
	sub seg_level {
		my $self = shift;
		if ($self->cgh_call_data){
			my $oCGH_Call = $self->cgh_call_object;
			return $oCGH_Call->seg_level(shift);
		} else {
			return;
		}
	}
	# the call data in chromosome chunks
	sub chr_cgh_calls {
		my $self = shift;
		if ($self->cgh_call_data){
			my $oCGH_Call = $self->cgh_call_object;
			return $oCGH_Call->chr_cgh_calls;
		} else {
			return;
		}
	}
	sub chr_seg_levels {
		my $self = shift;
		if ($self->cgh_call_data){
			my $oCGH_Call = $self->cgh_call_object;
			return $oCGH_Call->chr_seg_levels;
		} else {
			return;
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
	sub reporter_chrs {
		my $self = shift;
		$self->{ _reporter_chrs };
	}
	sub get_reporter_data {
		my $self = shift;
		my $reporter = shift;
		my $hReporters = $self->reporters;
		unless (defined $hReporters->{ $reporter }){
			$hReporters->{ $reporter } = { ratios => [] };
		}
		$hReporters->{ $reporter };
	}
	# pass reporter,log2,locn
	sub set_reporter_data {
		my $self = shift;
		my $hReporter_data = $self->get_reporter_data(shift);	
		my $aRatios = $hReporter_data->{ ratios };
		push(@$aRatios,shift);
		$hReporter_data->{ locn } = shift;
	}
	sub reporter_locn {
		my $self = shift;
		my $hReporter = $self->get_reporter_data(shift,shift);	# second shift for genome plot - chromosome name
		return $hReporter->{locn};
	}
	sub reporter_log {
		my $self = shift;
		my $hReporter = $self->get_reporter_data(shift,shift);	# second shift for genome plot - chromosome name
		my $aFeat_Ratios = $hReporter->{ratios};
		if (@$aFeat_Ratios == 1){
			return $aFeat_Ratios->[0];
		} else {
			my $log_ratio;
			for my $ratio (@$aFeat_Ratios){
				$log_ratio += $ratio;
			}
			return ($log_ratio/scalar @$aFeat_Ratios);
		}
	}
	sub parse_embedded_locn {
		my $self = shift;
		my $location = shift;
		my ($chr,$start,$end) = split(/:|\.\./,$location);
		$chr =~ s/chr//;
		return ($chr,int(($start+$end)/2));
	}
	sub clone_locns_file {
		my $self = shift;
		@_	?	$self->{ _clone_locns_file } = shift
			:	$self->{ _clone_locns_file };
	}
	sub embedded_locns {
		my $self = shift;
		@_	?	$self->{ _embedded_locns } = shift
			:	$self->{ _embedded_locns };
	}
	sub do_smoothing {
		my $self = shift;
		@_	?	$self->{ _do_smoothing } = shift
			:	$self->{ _do_smoothing };
	}
	sub smoothing {
		my $self = shift;
		if (@_){
			$self->smooth_window(shift);
			$self->smooth_step(shift);
			$self->{ _do_smoothing }++;
		} else {
			$self->{ _do_smoothing };		
		}
	}
	sub smooth_window {
		my $self = shift;
		if (@_){
			$self->{ _smooth_window } = shift;
			$self->{ _do_smoothing }++;
		} else {
			if (defined $self->{ _smooth_window }){
				$self->{ _smooth_window };		
			} else {
				$self->default_smooth_window;
			}
		}
	}
	sub default_smooth_window {
		500000
	}
	sub smooth_step {
		my $self = shift;
		if(@_){
			$self->{ _smooth_step } = shift;
			$self->{ _do_smoothing }++;
		} else {
			if (defined $self->{ _smooth_step }){
				$self->{ _smooth_step };		
			} else {
				$self->default_smooth_step;
			}
		}
	}
	sub default_smooth_step {
		150000
	}
	sub is_smoothed {
		my $self = shift;
		$self->{ _smoothed };
	}
 	# this method uses a moving window of a specific genomic length, 
	# that moves along the genome in steps of a defined length,
	# to smooth our CGH profiles. 
	sub smooth_data_by_location {
		my $self 			= shift;
		
		# our smoothing parameters
		my $window 			= $self->smooth_window;
		my $step 			= $self->smooth_step;
		
		# all of the sorted data
		my $aAll_Locns 		= $self->x_values;
		my $aAll_Logs 		= $self->y_values;
		my $aAll_CGH_Calls 	= $self->z_values;	# returns null if no CGHcall/DNAcopy data

		$self->starting_data($aAll_Locns,$aAll_Logs);

		# arrays to hold the final smoothed data
		my @aAll_Smooth_Locns 	= ();
		my @aAll_Smooth_Logs 	= ();
		my @aAll_Smooth_Calls 	= ();

		# set the chromosome we are working with - single or whole genome?
		my @aPlot_Chromosomes;
		if (my $chr = $self->plot_chromosome){
			@aPlot_Chromosomes = ($chr);
		} else {
			@aPlot_Chromosomes = (1..22,'X','Y');
		}
		
		# scroll through the individual chromosomes...
		for (my $j=0; $j<@aPlot_Chromosomes; $j++){
		
			# ...and get the sorted data for this chromosome
			my $aLocns 		= $aAll_Locns->[$j];
			my $aLogs 		= $aAll_Logs->[$j];
			my $aCGH_Calls 	= $aAll_CGH_Calls->[$j] if ($aAll_CGH_Calls && @$aAll_CGH_Calls);

			# reset the window start and end location
			my $start = $aLocns->[0];
			my $end = $start + $window;
			
			# arrays to hold the smoothed data for this chromosome
			my @aSmooth_Chr_Locns 	= ();
			my @aSmooth_Chr_Logs 	= ();
			my @aSmooth_Chr_Calls 	= ();
			
			#Êarrays to hold data in the moving window
			#Êmust be empty 'real' lists so that moving_average() works as expected
			my @aWindow_Logs		= ();
			my @aWindow_Locns		= ();
			my @aWindow_Calls		= ();
				
			# scroll through the sorted data
			for (my $i=0; $i<@$aLocns; $i++){
				my $genomic_locn = $aLocns->[$i];
				my $log_value = $aLogs->[$i]; 
				my $cgh_call = $aCGH_Calls->[$i] if ($aCGH_Calls && @$aCGH_Calls);
				
				# are we past the end of the window?
				if ($genomic_locn > $end){
					# if so, average up what's in the window...
					#Êmust pass referenced 'real' lists here, so that moving average works as expected
					my ($av_locn, $av_log, $av_call) = $self->moving_average(\@aWindow_Locns, \@aWindow_Logs, \@aWindow_Calls);
					# ...add these values to the smoothed data arrays...
					push(@aSmooth_Chr_Locns, $av_locn);
					push(@aSmooth_Chr_Logs, $av_log);
					push(@aSmooth_Chr_Calls, $av_call) if ($aCGH_Calls && @$aCGH_Calls);

					# ...move the end of the window to include the next location...
					$end = (int($genomic_locn/100000) * 100000) + $step;
					# ...move the start up as well...
					$start = $end - $window;

					# ...and remove any data that is no longer in the window
					if ((@aWindow_Locns) && ($aWindow_Locns[-1] < $start)){
						@aWindow_Locns = ();
						@aWindow_Logs = ();
						@aWindow_Calls = () if ($aCGH_Calls && @$aCGH_Calls);	
					} else {
						while ((@aWindow_Locns) && ($aWindow_Locns[0] < $start)){		# get rid of any values now out of the region 
							my $shifted1 = shift @aWindow_Locns;
							my $shifted2 = shift @aWindow_Logs;
							my $shifted3 = shift @aWindow_Calls if ($aCGH_Calls && @$aCGH_Calls);
						}		
					}
				}
				
				# either this location fell in the window to start with, 
				# or the window has now been moved to include it
				# so we add it to the window array and continue to the next location
				push (@aWindow_Locns, $genomic_locn);
				push (@aWindow_Logs, $log_value);
				push (@aWindow_Calls, $cgh_call) if ($aCGH_Calls && @$aCGH_Calls);
			}
			# we've finished with this chromosome, but have some values left in the last window
			my ($av_locn, $av_log, $av_call) = $self->moving_average(\@aWindow_Locns, \@aWindow_Logs, \@aWindow_Calls);
			push(@aSmooth_Chr_Locns, $av_locn);
			push(@aSmooth_Chr_Logs, $av_log);
			push(@aSmooth_Chr_Calls, $av_call) if ($aCGH_Calls && @$aCGH_Calls);
			
			# add the smoothed data for this chromosome to our array
			# and then continue to the next chromosome
			push(@aAll_Smooth_Locns,\@aSmooth_Chr_Locns);
			push(@aAll_Smooth_Logs,\@aSmooth_Chr_Logs);
			push(@aAll_Smooth_Calls,\@aSmooth_Chr_Calls) if (@aSmooth_Chr_Calls);
		}

		# finally, set all the smoothed data to our plotting values
		$self->{ _x_values } = \@aAll_Smooth_Locns;
		$self->{ _y_values } = \@aAll_Smooth_Logs;
		$self->{ _z_values } = \@aAll_Smooth_Calls if (@aAll_Smooth_Calls);
		$self->{ _smoothed } = 1;	
	}
	sub starting_data {
		my $self = shift;
		if (@_){
			$self->start_x_values(shift);
			$self->start_y_values(shift);
		} else {
			return ($self->start_x_values,$self->start_y_values);
		}
	}
	sub start_x_values {
		my $self = shift;
		@_	?	$self->{ _start_x_values } = shift
			:	$self->{ _start_x_values };
	}
	sub start_y_values {
		my $self = shift;
		@_	?	$self->{ _start_y_values } = shift
			:	$self->{ _start_y_values };
	}
	sub moving_average {
		my $self = shift;
		my ($aLocns,$aLogs,$aCalls) = @_;
		my ($av_locn, $av_log2, $av_call);
		if (@$aLocns > 1){
			$av_locn = calc_average($aLocns);
			$av_log2 = calc_average($aLogs);
			$av_call = calc_mode($aCalls) if ($aCalls && @$aCalls);
		} elsif (@$aLocns == 1){
			$av_locn = $aLocns->[0];
			$av_log2 = $aLogs->[0];
			$av_call = $aCalls->[0] if ($aCalls && @$aCalls);
		}
		return(int $av_locn, $av_log2, $av_call);
	}
	# the next two methods avoid using the horribly slow Statistics::Descriptive module 
	sub calc_mode {	#Êor the first value, if no mode
		my $aList = shift;
		my %hFreq = ();
		for my $num (@$aList){
			$hFreq{$num}++;
		}
		my ($max_count,$most_common) = ($hFreq{$$aList[0]},$$aList[0]);
		while (my ($num,$count) = each %hFreq){
			$most_common = $num if ($count > $max_count);
		}
		return $most_common;
	}
	sub calc_average {
		my $aList = shift;
		my $total;
		for my $val (@$aList){
			$total += $val;
		}
		return ($total/scalar @$aList);
	}
}

{ package chromosome_cgh;

	our @ISA = qw( cgh_analysis );

	sub sort_genome_data {
		my $self = shift;
		$self->sort_chromosome_data;
	}
	sub all_cgh_smooth {
		my $self = shift;
		if ($self->cgh_call_data){
			my $oCGH_Call = $self->cgh_call_object;
			my $aahAll_CGH_Smooth = $oCGH_Call->all_cgh_smooth;
			return $aahAll_CGH_Smooth->[0];
		} else {
			return;
		}
	}
	sub sort_chromosome_data {
		my $self = shift;
		my $plot_chr = $self->plot_chromosome;
		my $oData_File = $self->data_object;
		die "Microarray::Analysis::CGH ERROR: No data object provided\n" unless $oData_File;
				
		$oData_File->flip if ($self->flip_flop == -1);
		my $spot_count = $oData_File->spot_count;
		if ($self->embedded_locns){
			for (my $i=0; $i<$spot_count; $i++){
				if (my $embedded_locn = $oData_File->feature_id($i)){
					my ($chr,$locn) = $self->parse_embedded_locn($embedded_locn);
					next unless ($plot_chr eq $chr);
					if (my $log = $oData_File->log2_ratio($i)){
						$self->set_reporter_data($oData_File->synonym_id($i),$log,$locn);
					}
				}
			}	
		} elsif (my $oClone_Positions = $self->clone_locns_file) {
			my $hClones = $oClone_Positions->clone_hash;
			for (my $i=0; $i<$spot_count; $i++){
				my $feature = $oData_File->feature_id($i);
				next unless (	(defined $$hClones{$feature}) && 
								($plot_chr eq $$hClones{$feature}{_chr}) );
				if (my $log = $oData_File->log2_ratio($i)){
					$self->set_reporter_data($feature,$log,$oClone_Positions->location($feature));
				}
			}
		} else {
			die "Microarray::Analysis::CGH ERROR; No clone positions to work with\n";
		}
		$self->order_data;
	}
	sub order_data {
		my $self = shift;
		my $hReporters = $self->reporters;
		my @aReporters = keys %$hReporters;
		my $aSorted_Reporters = [];
		if ($self->smoothing){
			@$aSorted_Reporters = sort { $$hReporters{ $a }{locn} <=> $$hReporters{ $b }{locn} } @aReporters;
		} else {
			$aSorted_Reporters = \@aReporters;
		}
		my $call_data = $self->cgh_call_data;	#Êto save 32,000 calls later
		my @aLog_Ratios = ();
		my @aLocns = ();
		my @aZ_Values = ();
		for my $reporter (@$aSorted_Reporters){
			push(@aLocns,$self->reporter_locn($reporter));
			push(@aLog_Ratios,$self->reporter_log($reporter));
			push(@aZ_Values,$self->z_value($reporter)) if $call_data;
		}
		$self->{ _x_values } = [\@aLocns];
		$self->{ _y_values } = [\@aLog_Ratios];
		$self->{ _reporter_names } = [$aSorted_Reporters];
		$self->{ _z_values } = [\@aZ_Values] if @aZ_Values;
	}
}

{ package genome_cgh;

	our @ISA = qw( chromosome_cgh );

	sub sort_genome_data {
		my $self = shift;
		my $oData_File = $self->data_object;
		die "Microarray::Analysis::CGH ERROR: No data object provided\n" unless $oData_File;

		$oData_File->flip if ($self->flip_flop == -1);
		$self->{ _reporters } = {};	# reset the reporters for this chromosome
		my $spot_count = $oData_File->spot_count;
		if ($self->embedded_locns){
			for (my $i=0; $i<$spot_count; $i++){
				if (my $embedded_locn = $oData_File->feature_id($i)){
					my ($chr,$locn) = $self->parse_embedded_locn($embedded_locn);
					if (my $log = $oData_File->log2_ratio($i)){
						$self->set_reporter_data($oData_File->synonym_id($i),$log,$locn,$chr);
					}
				}
			}	
		} elsif (my $oClone_Positions = $self->clone_locns_file) {
			my $hClones = $oClone_Positions->clone_hash;
			for (my $i=0; $i<$spot_count; $i++){
				my $feature = $oData_File->feature_id($i);
				next unless (defined $$hClones{$feature});
				if (my $log = $oData_File->log2_ratio($i)){
					$self->set_reporter_data($feature,$log,$oClone_Positions->location($feature),$$hClones{$feature}{_chr});
				}
			}
		} else {
			die "Microarray::Analysis::CGH ERROR; No clone positions to work with\n";
		}
		$self->order_genome_data;
	}
	sub all_cgh_smooth {
		my $self = shift;
		if (my $oCGH_Call = $self->cgh_call_object){
			return $oCGH_Call->all_cgh_smooth;
		} else {
			return;
		}
	}
	sub order_genome_data {
		my $self = shift;
		my $hReporters = $self->reporters;
		my (@aReporters,@aLocns,@aLog_Ratios,@aZ_Values);
		my $call_data = $self->cgh_call_data;	#Êto save 32,000 calls later
		
		for my $chr ((1..22,'X','Y')){
		
			my $hChr_Reporters = $hReporters->{ $chr };
			my @aChr_Reporters = keys %$hChr_Reporters;
			
			my $aSorted_Chr_Reporters = [];
			my $aSorted_Chr_Logs = [];
			my $aSorted_Chr_Locns = [];
			my $aSorted_Chr_Zvals = [];
			
			if ($self->smoothing){
				@$aSorted_Chr_Reporters = sort { $$hChr_Reporters{ $a }{locn} <=> $$hChr_Reporters{ $b }{locn} } @aChr_Reporters;
			} else {
				$aSorted_Chr_Reporters = \@aChr_Reporters;
			}
			for my $reporter (@$aSorted_Chr_Reporters){
				push(@$aSorted_Chr_Locns,$$hChr_Reporters{$reporter}{ locn });
				push(@$aSorted_Chr_Logs,$self->reporter_log($reporter,$chr));
				push(@$aSorted_Chr_Zvals,$self->z_value($reporter)) if $call_data;
			}
			push (@aReporters,$aSorted_Chr_Reporters);
			push (@aLocns,$aSorted_Chr_Locns);
			push (@aLog_Ratios,$aSorted_Chr_Logs);
			push (@aZ_Values,$aSorted_Chr_Zvals) if @$aSorted_Chr_Zvals;
		}
		$self->{ _x_values } = \@aLocns;
		$self->{ _y_values } = \@aLog_Ratios;
		$self->{ _reporter_names } = \@aReporters;
		$self->{ _z_values } = \@aZ_Values if @aZ_Values;
	}
	sub set_reporter_data {
		my $self = shift;
		my $hReporter_data = $self->get_reporter_data(shift,pop);	# pop chromosome name
		my $aRatios = $hReporter_data->{ ratios };
		push(@$aRatios,shift);
		$hReporter_data->{ locn } = shift;
	}
	sub get_reporter_data {
		my $self = shift;
		my $reporter = shift;
		my $chr = shift;
		my $hReporters = $self->reporters;
		unless (defined $hReporters->{ $chr }{ $reporter }){
			$hReporters->{ $chr }{ $reporter } = { ratios => [] };
		}
		$hReporters->{ $chr }{ $reporter };
	}
}
1;

__END__

=head1 NAME

Microarray::Analysis::CGH - A Perl module for analysing CGH microarray data

=head1 SYNOPSIS

	use Microarray::Analysis::CGH;

	my $oData_File = data_file->new($data_file);
	my $oCGH = genome_cgh->new($oData_File);

=head1 DESCRIPTION

Microarray::Analysis::CGH is an object-oriented Perl module for analysing CGH microarray data from a scan data file, for sorting the reporters in a single chromosome or whole genome context, and to apply smoothing.    

=head1 METHODS

=over

=item B<flip>

Set this parameter to 1 in order to invert the log ratios returned by the L<C<data_file>|Microarray::File::Data_File> object.  

=back

=head2 Genomic clone locations

=over

=item B<embedded_locns>

By setting the C<embedded_locns> parameter to 1, the module expects the reporter name to be in the 'ID' field of the data file (i.e. the C<synonym_id()> of the C<data_file> object) and the clone location to be present in the 'Name' field of the data file (i.e. the C<feature_id()> of the L<C<data_file>|Microarray::File::Data_File> object). The clone location should be of the notation 'chr1:12345..67890'. When using C<embedded_locns> a clone position file is not required. Disabled by default.

=item B<clone_locns_file>

Set a L<Microarray::File::Clone_Locns|Microarray::File::Clone_Locns> file object, from which clone locations will be determined.

=back

=head2 Data smoothing

=over

B<do_smoothing>

Set this parameter to 1 to perform data smoothing. The Log2 ratios in a window of C<$window> bp are averaged. The window moves in steps of C<$step> bp. Disabled by default. 

=item B<smooth_window>, B<smooth_step>

Set the desired window and step sizes for smoothing using these two parameters. A default window size of 500,000bp and step size of 150,000bp provide a moderate level of smoothing, removing outliers while preserving short regions of copy number change. Setting either of these parameters will invoke the smoothing process without setting C<do_smoothing>. 

=back

=head1 SEE ALSO

L<Microarray|Microarray>, L<Microarray::Analysis|Microarray::Analysis>, L<Microarray::File|Microarray::File>, L<Microarray::File::Data_File|Microarray::File::Data_File>, L<Microarray::File::Clone_Locn_File|Microarray::File::Clone_Locn_File>

=head1 AUTHOR

Christopher Jones, Gynaecological Cancer Research Laboratories, Institute for Women's Health, University College London.

L<http://www.instituteforwomenshealth.ucl.ac.uk/AcademicResearch/Cancer/trl>

c.jones@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Christopher Jones, University College London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

