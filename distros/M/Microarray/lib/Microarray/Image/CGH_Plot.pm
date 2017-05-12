package Microarray::Image::CGH_Plot;

use 5.008;
use strict;
use warnings;
our $VERSION = '1.9';

use Microarray::Image;
require Microarray::File;
use Microarray::Analysis::CGH;

{ package cgh_plot;
  	
	our @ISA = qw( chromosome_cgh plot );	# will use the Microarray::Analysis::CGH new()

	sub sort_data {
		my $self = shift;
		my $oData_File = $self->data_object;
		die "Microarray::Image ERROR: No data object provided\n" unless $oData_File;
				
		if ($oData_File->comes_sorted ){	# already sorted by seq_start, already flip_flopped - i.e. from pipeline_data
			$self->{ _x_values } = $oData_File->all_locns;
			$self->{ _y_values } = $oData_File->all_log2_ratio;
			$self->{ _reporter_names } = $oData_File->all_feature_names;
			if ($self->cgh_call_data){
				if ($self->plot_call_colours){
					$self->{ _z_values } = $self->chr_cgh_calls;
				} elsif ($self->plot_segment_colours){
					$self->{ _z_values } = $self->chr_seg_levels;
				}
			}
		} else {
			$self->sort_genome_data;
		}
		$self->{ _data_sorted } = 1;
	}
	sub plot_chromosome {
		my $self = shift;
		if (@_){
			$self->{ _plot_chromosome } = shift;
		} else {
			if (defined $self->{ _plot_chromosome }){
				$self->{ _plot_chromosome };
			} else {
				die "Microarray::Image ERROR; No plot chromosome was specified\n";
			}
		}
	}
	sub data_sorted {
		my $self = shift;
		$self->{ _data_sorted };
	}
	sub plot_centromere {
		my $self = shift;
		if (@_){
			$self->{ _plot_centromere } = shift;
		} else {
			if (defined $self->{ _plot_centromere }){
				return $self->{ _plot_centromere };
			} else {
				return 1;
			}
		}
	}
	# this is a hashref of the x/y plot values
	#Êused to avoid plotting the same values twice
	sub plotted_values {
		my $self = shift;
		@_	?	$self->{ _plotted_values } = shift
			:	$self->{ _plotted_values };
	}
	sub shift_zero {
		my $self = shift;
		@_	?	$self->{ _shift_zero } = shift
			:	$self->{ _shift_zero };
	}
	sub plot_cgh_call {
		my $self = shift;
		$self->segment_levels;
		$self->breakpoints;
		$self->call_colours;
	}
	sub segment_levels {
		my $self = shift;
		$self->{ _segment_levels }++;
	}
	sub plot_segment_levels {
		my $self = shift;
		$self->{ _segment_levels };
	}
	sub breakpoints {
		my $self = shift;
		$self->{ _breakpoints }++;
	}
	sub plot_breakpoints {
		my $self = shift;
		$self->{ _breakpoints };
	}
	sub plot_colours {
		my $self = shift;
		my $method = shift;
		$self->$method;	
	}
	sub rainbow_colours {
		my $self = shift;
		delete $self->{ _segment_colours } if (defined $self->{ _segment_colours });
		delete $self->{ _call_colours } if (defined $self->{ _call_colours });
	}
	sub call_colours {
		my $self = shift;
		# can't plot call and segment colours, so last one in wins!
		delete $self->{ _segment_colours } if (defined $self->{ _segment_colours });
		$self->{ _call_colours }++;
	}
	sub plot_call_colours {
		my $self = shift;
		$self->{ _call_colours };
	}
	sub segment_colours {
		my $self = shift;
		# can't plot call and segment colours, so last one in wins!
		delete $self->{ _call_colours } if (defined $self->{ _call_colours });
		$self->{ _segment_colours }++;
	}
	sub plot_segment_colours {
		my $self = shift;
		$self->{ _segment_colours };
	}
	sub plot_gene_locn {
		my $self = shift;
		if (@_){
			unless (defined $self->{ _plot_gene_info }){
				$self->{ _plot_gene_info } = {};
			}
			my %hGene_Info = @_;
			my $hGene_Info = $self->{ _plot_gene_info };
			%$hGene_Info = (%$hGene_Info, %hGene_Info);
		} else {
			$self->{ _plot_gene_info };
		}
	}
	sub plot_gene_names {
		my $self = shift;
		my $hGene_Info = $self->{ _plot_gene_info };
		return (keys %$hGene_Info);
	}
	sub plot_gene_chr {
		my $self = shift;
		my $gene = shift;
		my $hGene_Info = $self->{ _plot_gene_info };
		return $hGene_Info->{ $gene }{ chr };
	}
	sub plot_gene_start {
		my $self = shift;
		my $gene = shift;
		my $hGene_Info = $self->{ _plot_gene_info };
		return $hGene_Info->{ $gene }{ start };
	}
	sub plot_gene_end {
		my $self = shift;
		my $gene = shift;
		my $hGene_Info = $self->{ _plot_gene_info };
		return $hGene_Info->{ $gene }{ end };
	}
	# the call data (either CGHcall calls, or DNAcopy segments)
	# the original chr chunks for either call or segment level data
	sub z_values {
		my $self = shift;
		if (defined $self->{ _z_values }){
			return $self->{ _z_values };
		} else {
			if ($self->plot_call_colours){
				$self->chr_cgh_calls;
			} elsif ($self->plot_segment_colours){
				$self->chr_seg_levels;
			} else {
				return;
			}
		}
	}
	# the ordered linear plottable data
	sub plotz_values {
		my $self = shift;
		$self->{ _plotz_values };
	}
	# the z_value for a specific feature_id
	sub z_value {
		my $self = shift;
		if ($self->plot_call_colours){
			$self->cgh_call(shift);
		} elsif ($self->plot_segment_colours){
			$self->seg_level(shift);
		} else {
			return;
		}
	}
	sub make_plot {
		my $self  = shift;
		if (@_){
			$self->parse_args(@_);
		}
		$self->sort_data;
		my ($x, $y) = $self->plot_dimensions;
		## set the y value the same as the genome plot
		$self->{ _gd_object } = GD::Image->new($x,$y);
		$self->set_plot_background;
		$self->make_colour_grads;
		$self->make_outline($x,$y);
		if ($self->smoothing) {
			$self->smooth_data_by_location;
		}			
		$self->plot_spots;
		if ($self->plot_segment_levels || $self->plot_breakpoints){
			if ($self->cgh_call_data){
				$self->plot_cgh_smooth_data;
			} else {
				warn "Microarray::Image::CGH_Plot Could not plot DNAcopy segment levels because there was no DNAcopy data available\n";
			}
		}
		$self->return_image;
	}
	sub default_scale {
		500000;
	}
	sub y_scale {
		1;
	}
	sub plot_cgh_smooth_data {
		my $self = shift;

		my $ahCGH_Smooth = $self->all_cgh_smooth;		
		my $scale 		= $self->scale;
		my $y_scale 	= $self->y_scale;
		my $zero_shift 	= $self->shift_zero;
		
		my $image = $self->gd_object;

		for my $hSegment (@$ahCGH_Smooth){
			my $start = $hSegment->{ start };
			my $end = $hSegment->{ end };
			my $ratio = $hSegment->{ level };
			my $call = $hSegment->{ call };
			
			my $plot_start = int($start/$scale);
			my $plot_end = int($end/$scale);
			$ratio += $zero_shift if ($zero_shift);
			my $plot_log = int((225 - ($ratio * 150))*$y_scale);
			my $colour = $self->get_call_colour($call); # call, or 'smoothed' call
			$image->filledRectangle($plot_start,($plot_log-1),$plot_end,($plot_log+1),$colour);	
		}
	}
	# normalise the processed data relative to the image ready to be plotted
	sub plot_data {
		my $self = shift;
		my $aaX = $self->x_values;
		my $aaY = $self->y_values;
		my $aaZ = $self->z_values;
		
		my $aX  = $$aaX[0];
		my $aY  = $$aaY[0];
		my $aZ = $$aaZ[0] if ($aaZ && @$aaZ);
		my $scale 		= $self->scale;
		my $y_scale 	= $self->y_scale;
		my $zero_shift 	= $self->shift_zero;
		my $aLocns = [];
		my $aLog2  = [];
		my $aCall_Data = [];
		
		my %hPlot_Values = ();

		for (my $i=0; $i<@$aX; $i++ ){
			my $locn = $aX->[$i];
			my $log2 = $aY->[$i];
			next unless($locn && $log2);
			
			$locn = int($locn/$scale);
			push(@$aLocns, $locn);
			
			my $call = $aZ->[$i] if ($aZ && @$aZ);
			if ($zero_shift){
				$log2 += $zero_shift;
				$call += $zero_shift if ($aZ && @$aZ);	# can have null seg values
			} 
			## divide the y axis by 3 for a +1.5/-1.5 plot
			$log2 = int((225 - ($log2 * 150))*$y_scale);
			push(@$aLog2, $log2);
			
			$call = int((225 - ($call * 150))*$y_scale) if ($aZ && @$aZ);
			push(@$aCall_Data, $call) if ($aaZ && @$aaZ); 
			
			$hPlot_Values{"$locn,$log2"}++;	# to avoid plotting the same values twice
		}
		$self->{ _plotx_values } = $aLocns;
		$self->{ _ploty_values } = $aLog2;
		$self->{ _plotz_values } = $aCall_Data if (@$aCall_Data && ($self->plot_call_colours || $self->plot_segment_colours));
		$self->plotted_values(\%hPlot_Values);
		return($aLocns,$aLog2);
	}
	sub plot_dimensions {
		my $self = shift;
		my $scale = $self->scale;
		my $y_scale = $self->y_scale;

		my $chr_length = $self->chr_length($self->plot_chromosome);
		my $x = int(($chr_length/$scale) + 1);
		my $y = 450 * $y_scale;
		my $x_margin = 0;
		my $y_margin = 0;
		$self->{ _x_length } = $x;
		$self->{ _y_length } = $y;
		$self->{ _x_margin } = 0;
		$self->{ _y_margin } = 0;
		$self->{ _middle } = $y/2;
		
		return ($x,$y);
	}
	sub pixel_size {
		my $self = shift;
		if (defined $self->{ _pixel_size }){
			return $self->{ _pixel_size };
		} else {
			return 3;
		}
	}
	sub plot_spots {
		my $self = shift;
		
		my $image 			= $self->gd_object;
		my ($aX,$aY) 		= $self->plot_data;
		my $hPlot_Values 	= $self->plotted_values;	# hash record of "x,y" values to plot
		my $pixel_size 		= $self->pixel_size;
		
		my $aCGH_Colours = $self->plotz_values;
		if (($self->plot_call_colours || $self->plot_segment_colours) && !$aCGH_Colours) {
			warn "Microarray::Image::CGH_Plot Could not plot CGHcall or segment colours because there was no CGHcall/DNAcopy data available\n";
		}
		
		for (my $i=0; $i<@$aX; $i++){
			my $x = $aX->[$i];
			my $y = $aY->[$i];
			next unless ($x && $y);
			if (defined $hPlot_Values->{"$x,$y"}){
				delete $hPlot_Values->{"$x,$y"};	# first time we've seen this - only plot once, then throw away
			} else {
				next;	# already plotted/key deleted - no point plotting the same values twice
			}
			my $colour;
			if ($aCGH_Colours && @$aCGH_Colours){
				$colour = $self->get_colour($aCGH_Colours->[$i]); # call, or 'smoothed' call
			} else {
				$colour = $self->get_colour($y);
			}
			if ($pixel_size == 1){
				$image->setPixel($x,$y,$colour);
			} else {
				$image->filledEllipse($x,$y,3,3,$colour);
			}
		}
	}
	# plot the outline of the diagram, ready for spots to be added
	sub make_outline {	
		use GD;
		my $self = shift;
		my $x = shift;
		my $y = shift;

		my $image 	= $self->gd_object;
		my $scale 	= $self->scale;
		my $y_scale = $self->y_scale;
		my $chr 	= $self->plot_chromosome;
		
		# get colours from the GD colour table 
		my $black 	= $image->colorExact(0,0,0);
		my $red   	= $image->colorExact(255,0,0);      
		my $green 	= $image->colorExact(0,255,0);      

		# plot a gene location, if required
		if ($self->plot_gene_locn){		
			my @aGenes = $self->plot_gene_names;
			for my $gene_name (@aGenes){
				next unless ($self->plot_gene_chr($gene_name) eq $chr);
				my $gene_start = int($self->plot_gene_start($gene_name)/$scale);
				my $gene_end = int($self->plot_gene_end($gene_name)/$scale);
				my $name_length = ((length($gene_name))*6);	# pixel length of gene_name
				my $royal_blue	= $image->colorExact(51,0,255);   
				$image->filledRectangle($gene_start,0,$gene_end,$y,$royal_blue);
				my $name_start = $gene_end + 5;
				# make sure the name is withing the plot boundary
				if (($name_start + $name_length) > $x){
					$name_start = $gene_start - $name_length - 5;
				} 
				$image->string(GD::Font->Small,$name_start,($y-15),$gene_name,$royal_blue);
			}
		}

		# 3px wide log2 ratio lines
		$image->filledRectangle(0,(150*$y_scale),$x,(150*$y_scale),$red);	# +0.5
		$image->filledRectangle(0,(225*$y_scale),$x,(225*$y_scale),$green);	#  0.0
		$image->filledRectangle(0,(300*$y_scale),$x,(300*$y_scale),$red);	# -0.5
		# axis labels		
		$image->string(GD::Font->Giant,10,(150*$y_scale),'0.5',$black);
		$image->string(GD::Font->Giant,10,(225*$y_scale),'0',$black);
		$image->string(GD::Font->Giant,10,(300*$y_scale),'-0.5',$black);
		
		if ($self->plot_centromere){
			my $blue = $image->colorExact(125,125,255);
			# dashed style for centromere lines
			$image->setStyle($blue,$blue,$blue,$blue,gdTransparent,gdTransparent);
			my $cen = int($self->chr_centromere($chr)/$scale);
			$image->line($cen,0,$cen,$y,gdStyled);
		}
		
	}
	# set a rainbow of graduated colours in the GD colour table, for use in the plot 
	sub set_plot_background {
		my $self = shift;
		my $image = $self->gd_object;
		## first allocated colour is set to background
		my $grey = $image->colorAllocate(180,180,180);
	}
	sub make_colour_grads {
		my $self  = shift;
		my $image = $self->gd_object;
		$image->colorAllocate(0,0,0);
		$image->colorAllocate(125,125,255);	# centromere blue
		
		for (my $i = 0; $i<=255; $i+=3){ 
			$image->colorAllocate($i,255,0);	## Add red -> green = yellow
			$image->colorAllocate(255,$i,0); 	## Add green -> red = yellow
		}	
		$image->colorAllocate(150,150,0);	# dull yellow
		$image->colorAllocate(0,150,0);		# dull green
		$image->colorAllocate(150,0,0);		# dull red
		$image->colorAllocate(0,0,150);		# dull blue
		$image->colorAllocate(51,0,255);	# royal blue
	}
	# the colour of the segment level (average) line
	# uses the CGHcall value
	sub get_call_colour {
		my $self  = shift;
		my $call = shift;

		my $image  = $self->gd_object;
				
		if ($call eq '0'){
			return $image->colorExact(150,150,0); 
		} elsif ($call eq '1'){
			return $image->colorExact(0,150,0); 
		} elsif (($call eq '-1') || ($call eq '-2')){
			return $image->colorExact(150,0,0);      
		} else {
			return $image->colorExact(0,0,150);      
		}
	}
	
	# the (default) rainbow colour pattern for spot colouring
	# wide yellow region across log2=0
	# red below log2 =~ -0.77
	# green above log2 =~ +0.77
	# with a gradient in between 
	sub get_colour {
		my $self  = shift;
		my $ratio = shift;
		
		my $image  = $self->gd_object;
		my $y_scale = $self->y_scale;
		# get colours from the GD colour table
		my $red    = $image->colorExact(255,0,0);      
		my $green  = $image->colorExact(0,255,0);      
		my $yellow = $image->colorExact(255,255,0);      
		my $colour;
		
		# DEFAULT SCALE = 2500000 = 450 pixels in Y axis
		#  plot is 450 pixels * $y_scale
		# +0.5 is at 150
		#  0 is at 225
		# -0.5 is at 300
		# green below 110
		# red above 340
		# yellow between 190 & 260
		# have a 70 pixel yellow region across 0 
		# making a colour gradient across an 80 pixel region, 40 pixels either side of +/-0.5
		# have created 85 colours for each gradient 
		
		# 255 hues / 80 pixels = 3.1875 hues per pixel for the default
		my $factor = 255/(80 * $y_scale);
		
		if ($ratio <= (110*$y_scale)){
			$colour = $green;
		} elsif ($ratio >= (340*$y_scale)){
			$colour = $red;
		} elsif (((260*$y_scale) > $ratio)&&($ratio > (190*$y_scale))) {
			$colour = $yellow;
		} elsif ($ratio >= (260*$y_scale)) {
			# calculate how much green to remove from yellow, to create red
			my $green_hue = int(255-($factor*($ratio-(260*$y_scale))));				# factorial = 255/(low_yellow - green)
			$colour = $image->colorClosest(255,$green_hue,0);						# reducing green, closer to red
		} else {
			# calculate how much red to remove from yellow, to create green
			my $red_hue = int(255-($factor*((190*$y_scale)-$ratio)));				# factorial = 255/(high_yellow - red)
			$colour = $image->colorClosest($red_hue,255,0);							# reducing red, closer to green
		}
		return($colour);
	}
	sub image_map {
		my $self 		= shift;
		my ($aX,$aY) 	= $self->plot_data;
		
		my ($aReporters,$reporter);
		if ($self->smoothing) {
			$aReporters = $self->x_values;		# genomic location of window centre
			$reporter = 'window';
		} else {
			$aReporters = $self->reporter_names;	# bac names
			$reporter = 'clone';
		}
		
		my $map_name = 'cgh_plot';
		if (@_){
			$map_name = shift;
		}
		my $map_string = "<MAP NAME=\"$map_name\">\n";
		
		for (my $i=0; $i<@$aX; $i++){
			my $x = $aX->[$i];
			my $y = int($aY->[$i]) + 225;
			next unless (($x && $y)&&($y>0)&&($x>0));
			my $element = $aReporters->[0][$i];
			$map_string .= "<area \"[$reporter]=[$element]\" shape=\"circle\" coords=\"$x,$y,3\" />\n";
		}
		$map_string .= "</MAP>\n";
		return $map_string;
	}
	sub chr_centromere {
		my $self = shift;
		my $chr  = shift;
		my %hCentromere = (		
			1 => 124200000,  
			2 => 93400000,
			3 => 91700000,
			4 => 50900000,
			5 => 47700000,
			6 => 60500000,
			7 => 58900000,
			8 => 45200000,
			9 => 50600000,
			10 => 40300000,
			11 => 52900000,
			12 => 35400000,
			13 => 16000000,
			14 => 15600000,
			15 => 17000000,
			16 => 38200000,
			17 => 22200000,
			18 => 16100000,
			19 => 28500000,
			20 => 27100000,
			21 => 12300000,
			22 => 11800000,
			23 => 59400000,
			'X' => 59400000,
			24 => 11500000,
			'Y' => 11500000
		);
		return ($hCentromere{$chr});
	}
	sub chr_length {
		my $self = shift;
		my $chr  = shift;
		my %hChromosome = (		
			# chr length
			1 => 247249719,
			2 => 242951149,
			3 => 199501827,
			4 => 191273063,
			5 => 180857866,
			6 => 170899992,
			7 => 158821424,
			8 => 146274826,
			9 => 140273252,
			10 => 135374737,
			11 => 134452384,
			12 => 132349534,
			13 => 114142980,
			14 => 106368585,
			15 => 100338915,
			16 => 88827254,
			17 => 78774742,
			18 => 76117153,
			19 => 63811651,
			20 => 62435964,
			21 => 46944323,
			22 => 49691432,
			23 => 154913754,
			'X' => 154913754,
			24 => 57772954,
			'Y' => 57772954,
			25 => 3080419480	# END
		);
		return ($hChromosome{$chr});
	}
}
{ package genome_cgh_plot;

	# must try genome_cgh first, otherwise will move through cgh_plot to chromosome_cgh
	our @ISA = qw( genome_cgh cgh_plot );	

	sub plot_dimensions {
		my $self = shift;
		my $scale = $self->scale;
		my $y_scale = $self->y_scale;
		my $genome_length = $self->chr_length(25);	# end
		my $x = ($genome_length/$scale)+25;
		my $y = 450 * $y_scale;
		my $x_margin = 0;
		my $y_margin = 0;
		$self->{ _x_length } = $x;
		$self->{ _y_length } = $y;
		$self->{ _x_margin } = 0;
		$self->{ _y_margin } = 0;
		$self->{ _middle } = $y/2;
		
		return ($x,$y);
	}
	sub default_scale {
		## set scale for the genome plot to 2.5Mb per pixel
		2500000;
	}
	sub y_scale {
		my $self = shift;
		my $scale = $self->scale;
		my $default_scale = $self->default_scale;
		return $default_scale/$scale;
	}
	sub mini_plot {
		my $self = shift;
		$self->scale(10000000);
		$self->{ _pixel_size } = 1;
	}
	sub font_size {
		my $self = shift;
		if ($self->scale <= 2000000 ){
			return 'Giant';
		} elsif ($self->scale < 3000000 ){
			return 'Small';
		} else {
			return 'Tiny';
		}
	}
	sub plot_chromosome {
		return;
	}
	sub plot_cgh_smooth_data {
		my $self = shift;

		my $aahAll_CGH_Smooth = $self->all_cgh_smooth;
		my $scale 		= $self->scale;
		my $y_scale 	= $self->y_scale;
		my $zero_shift 	= $self->shift_zero;
		my $pixel_size	= $self->pixel_size;
		
		my $image = $self->gd_object;

		for my $chr ((0..23)){
			my $ahCGH_Smooth = $aahAll_CGH_Smooth->[$chr];
			my $chr_offset = $self->chr_offset($chr+1);
			for my $hSegment (@$ahCGH_Smooth){
				my $start = $hSegment->{ start };
				my $end = $hSegment->{ end };
				my $ratio = $hSegment->{ level };
				my $call = $hSegment->{ call };
				
				my $plot_start = int(($start/$scale) + ($chr_offset/$scale)) + 25;
				my $plot_end = int(($end/$scale) + ($chr_offset/$scale)) + 25;
				$ratio += $zero_shift if ($zero_shift);
				my $plot_log = int((225 - ($ratio * 150))*$y_scale);
				my $colour = $self->get_call_colour($call); # call, or 'smoothed' call
				if ($pixel_size == 1){
					$image->line($plot_start,$plot_log,$plot_end,$plot_log,$colour);
				} else {
					$image->filledRectangle($plot_start,($plot_log-1),$plot_end,($plot_log+1),$colour);
				}
			}
		}
	}
	sub plot_data {
		my $self = shift;
		my $scale = $self->scale;
		my $y_scale = $self->y_scale;
		my $aaX = $self->x_values;
		my $aaY = $self->y_values;
		my $aaZ = $self->z_values;
		
		my $zero_shift = $self->shift_zero;
		my $aLocns = [];
		my $aLog2  = [];
		my $aCall_Data = [];
		my %hPlot_Values = ();
		
		for my $chr ((0..23)){
			my $aX = $$aaX[$chr];
			my $aY = $$aaY[$chr];
			my $aZ = $$aaZ[$chr] if ($aaZ && @$aaZ);
			my $chr_offset = $self->chr_offset($chr+1);
			for (my $i=0; $i<@$aX; $i++ ){
				my $locn = $aX->[$i];
				my $log2 = $aY->[$i];			
				next unless($locn && $log2);
				
				$locn = int(($locn/$scale) + ($chr_offset/$scale) + 25);
				push(@$aLocns, $locn);
				
				my $call = $aZ->[$i] if ($aZ && @$aZ);
				if ($zero_shift){
					$log2 += $zero_shift;
					$call += $zero_shift if ($aZ && @$aZ);	# can have null seg values
				}
				
				## multiply the log value by a quarter of the y axis to get a +2/-2 plot 
				$log2 = int((225 - ($log2 * 150))*$y_scale);
				push(@$aLog2, $log2);
				
				$call = int((225 - ($call * 150))*$y_scale) if ($aZ && @$aZ);
				push(@$aCall_Data, $call) if ($aaZ && @$aaZ);

				$hPlot_Values{"$locn,$log2"}++;	# to avoid plotting the same values twice
			}
		}
		$self->{ _plotx_values } = $aLocns;
		$self->{ _ploty_values } = $aLog2;
		$self->{ _plotz_values } = $aCall_Data if (@$aCall_Data && ($self->plot_call_colours || $self->plot_segment_colours));
		$self->plotted_values(\%hPlot_Values);
		return($aLocns,$aLog2);
	}
	# Harcode the plot outline for the genome plot as dimensions do not change
	sub make_outline {
		use GD;
		my $self = shift;
		my $x = shift;
		my $y = shift;
		my $image = $self->gd_object;
		my $scale = $self->scale;
		my $y_scale = $self->y_scale;
		my $font = $self->font_size;
		
		# get colours from the GD colour table 
		my $black 	= $image->colorExact(0,0,0);
		my $red   	= $image->colorExact(255,0,0);      
		my $green 	= $image->colorExact(0,255,0); 
		my $blue	= $image->colorExact(125,125,255);   
		my $royal_blue	= $image->colorExact(51,0,255);   
		
		# 3px wide log2 ratio lines
		$image->filledRectangle(0,(150*$y_scale),$x,(150*$y_scale),$red);		# +0.5
		$image->filledRectangle(0,(225*$y_scale),$x,(225*$y_scale),$green);		#  0.0
		$image->filledRectangle(0,(300*$y_scale),$x,(300*$y_scale),$red);		# -0.5
		# axis labels
		$image->string(GD::Font->$font,0,(150*$y_scale),'0.5',$black);
		$image->string(GD::Font->$font,0,(225*$y_scale),'0',$black);
		$image->string(GD::Font->$font,0,(300*$y_scale),'-0.5',$black);
		$image->setStyle($blue,$blue,$blue,$blue,gdTransparent,gdTransparent);
		
		# plot chr separator lines and chr names for each chromosome
		for my $chr ((1..24)){
			my $start 	= int($self->chr_offset($chr)/$scale);
			my $end 	= int($self->chr_offset($chr+1)/$scale);
			my $middle 	= int(($start+$end)/2);
			if ($self->plot_centromere){
				# centromere
				my $cen = int(($self->chr_offset($chr)+$self->chr_centromere($chr))/$scale);
				# dashed style for centromere lines
				$image->line($cen+25,0,$cen+25,(450*$y_scale),gdStyled);
			}
			# chr buffer
			$image->filledRectangle($start+25,0,$start+25,(450*$y_scale),$black);
			# set chr names
			my $chr_name;
			if ($chr == 23){
				$chr_name = 'X';
			} elsif ($chr == 24){
				$chr_name = 'Y';
				# end line
				$image->line($end+25,0,$end+25,(450*$y_scale),$black);
			} else {
				$chr_name = $chr;
			}
			# print chr name at bottom of plot
			$image->string(GD::Font->$font,$middle+20,(420*$y_scale),$chr_name,$black);

			if ($self->plot_gene_locn){
				my @aGenes = $self->plot_gene_names;
				for my $gene_name (@aGenes){
					next unless ($self->plot_gene_chr($gene_name) eq $chr_name);
					my $gene_start = int(($self->chr_offset($chr) + $self->plot_gene_start($gene_name))/$scale);
					my $gene_end = int(($self->chr_offset($chr) + $self->plot_gene_end($gene_name))/$scale);
					$image->filledRectangle($gene_start+25,0,$gene_end+25,(450*$y_scale),$royal_blue);
				}
			}
		}
	}
	sub chr_offset {
		my $self = shift;
		my $chr  = shift;
		my %hChromosome = (		
			# start bp  		# chr length
			1 => 0,   			# 247249719
			2 => 247249720,		# 242951149
			3 => 490200869,		# 199501827
			4 => 689702696,		# 191273063
			5 => 880975759,		# 180857866
			6 => 1061833625,	# 170899992
			7 => 1232733617,	# 158821424
			8 => 1391555041,	# 146274826
			9 => 1537829867,	# 140273252
			10 => 1678103119,	# 135374737
			11 => 1813477856,	# 134452384
			12 => 1947930240,	# 132349534
			13 => 2080279774,	# 114142980
			14 => 2194422754,	# 106368585
			15 => 2300791339,	# 100338915
			16 => 2401130254,	# 88827254
			17 => 2489957508,	# 78774742
			18 => 2568732250,	# 76117153
			19 => 2644849403,	# 63811651
			20 => 2708661054,	# 62435964
			21 => 2771097018,	# 46944323
			22 => 2818041341,	# 49691432
			23 => 2867732773,	# 154913754
			'X' => 2867732773,	# 154913754
			24 => 3022646527,	# 57772954
			'Y' => 3022646527,	# 57772954
			25 => 3080419480	# END
		);
		return ($hChromosome{$chr});
	}
}

1;

__END__

=head1 NAME

Microarray::Image::CGH_Plot - A Perl module for creating CGH-microarray data plots

=head1 SYNOPSIS

	use Microarray::Image::CGH_Plot;
	use Microarray::File::Data;
	use Microarray::File::Clone_Locns;
	
	# first make your data objects
	my $oData_File = data_file->new($data_file);
	my $oClone_File = clone_locn_file->new($clone_file);
	
	# create the plot object
	my $oGenome_Image = genome_cgh_plot->new($oData_File,$oClone_File);
	my $oChrom_Image = cgh_plot->new($oData_File,$oClone_File);
	
	# make the plot image
	# several parameters can be set when calling make_plot() 
	my $genome_png = $oGenome_Image->make_plot;
	my $chrom_png = $oChrom_Image->make_plot(plot_chromosome=>1, scale=>100000);

=head1 DESCRIPTION

Microarray::Image::CGH_Plot is an object-oriented Perl module for creating CGH-microarray data plots from a scan data file, using the GD module and image library.    

There are two types of CGH plot - a single chromosome plot (C<cgh_plot>) or a whole genome plot (C<genome_cgh_plot>). CGH plots require genomic mapping data for each reporter, and this is loaded into the object using a L<C<clone_locn_file>|Microarray::File::Clone_Locn_File> object (see below), or alternatively by using information embedded in the data file by setting the C<embedded_locns> flag. 

=head1 Methods

=over

=item B<new()>

Pass the L<Microarray::File::Data|Microarray::File::Data> and (optional) L<Microarray::File::Clone_Locns|Microarray::File::Clone_Locns> file objects at initialisation.

=item B<make_plot()>

Pass hash arguments to C<make_plot()> to set various parameters (see below). The only argument required is C<plot_chromosome>, when creating a single chromosome plot using the C<cgh_plot> class

=item B<set_data()>

The C<data_file> and C<clone_locn_file> objects do not have to be passed at initialisation, but can instead be set using the C<set_data()> method. 

=back

=head2 Plot parameters

The following parameters can be set in the call to C<make_plot()>, or separately before calling C<make_plot()>.

=over

=item B<plot_chromosome>

Set this parameter to indicate which chromosome to plot. Required for single chromosome plots using the C<cgh_plot> class. Must match the chromosome name provided by the clone positions file (or embedded data). 

=item B<plot_centromere>

Set this parameter to zero to disable plotting of the centromere lines. Default is to plot the centromere locations as dashed blue lines. 

=item B<scale>

Pass an integer value to set the desired X-scale of the plot, in bp/pixel. Default for C<cgh_plot> (individual chromosome plot) is 500,000 bp per pixel; default for C<genome_cgh_plot> (whole genome plot) is 2,500,000 bp/pixel. 

=item B<shift_zero>

Set this parameter to a value by which all Log2 ratios will be adjusted. Useful to better align the plot with the zero line. 

=item B<plot_gene_locn>

Pass details of gene locations to be plotted as a 2D hash, like so;

	$oPlot->plot_gene_locn( 
		'BRCA1' => { chr => '17', start => '38449840', end=> '38530994' },
		'BRCA2' => { chr => '13', start => '31787617', end => '31871806' },
		'CBL' => { chr => '11', start => '118582200', end => '118684066' } 
	);

=back

=head3 CGHsmooth and CGHcall output

The default for colouring the CGH plot is a rainbow gradient, where log2 ratios below -0.5 are plotted red, 0 are yellow, and above +0.5 are green, with a gradient inbetween. However, if CGHsmooth or CGHcall output has been provided at initialisation (by passing a relevant data object) then you can plot the CGHsmooth segments, breakpoints, and colour code the spots/segments according to the CGHcall or DNAcopy output, by calling any combination of the following methods;

	$oPlot->segment_levels;
	$oPlot->breakpoints;
	$oPlot->call_colours;
	$oPlot->segment_colours;
	
	# or shortcut the first three calls with just one 'do it all' call
	$oPlot->plot_cgh_call;

The methods C<call_colours> and C<segment_colours> provide subtly different ways of colouring the DNAcopy segments. The output from CGHcall provides a loss, normal or gain call for each segment, and C<call_colours> paints each segment with the appropriate red/yellow/green colours for the resulting call. However, this method isn't perfect because it doesn't distinguish borderline calls from more certain calls. The C<segment_colours> method takes a different approach, and colours a segment according to the segment level (or average log2 ratio for that segment) that is output by DNAcopy. This isn't so good for very complex profiles where there is no clear 'diploid' state in the profile. Which ever method you choose, you can clearly only use one at a time - if you do happen to call both methods, then the one called last will prevail. 

=head2 Analysis methods

The cgh_plot and genome_cgh_plot classes can use methods from the L<Microarray::Analysis::CGH|Microarray::Analysis::CGH> module. Pass analysis parameters to the make_plot() method to implement L<flip()|Microarray::Analysis::CGH/"flip">, L<embedded_locns()|Microarray::Analysis::CGH/"embedded_locns">, L<do_smoothing()|Microarray::Analysis::CGH/"do_smoothing"> etc. 

=head1 SEE ALSO

L<Microarray|Microarray>, L<Microarray::Image|Microarray::Image>, L<Microarray::Analysis|Microarray::Analysis>, L<Microarray::Analysis::CGH|Microarray::Analysis::CGH>, L<Microarray::File|Microarray::File>, L<Microarray::File::Data|Microarray::File::Data>, L<Microarray::File::Clone_Locns|Microarray::File::Clone_Locns>

=head1 AUTHOR

James Morris, Gynaecological Cancer Research Laboratories, UCL EGA Institute for Women's Health, University College London.

L<http://www.instituteforwomenshealth.ucl.ac.uk/AcademicResearch/Cancer/trl>

james.morris@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by James Morris, University College London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
