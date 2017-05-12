package Microarray::Image::QC_Plots;

use 5.008;
use strict;
use warnings;
our $VERSION = '1.5';

use Microarray::Image;
require Microarray::File;


{ package ma_plot;
  
	our @ISA = qw( plot );

	sub process_data {
		my $self = shift;
		my $aCh1 = $self->ch1_values;
		my $aCh2 = $self->ch2_values;
		my $aMvalues = [];
		my $aAvalues = [];
		for (my $i=0; $i<@$aCh1; $i++){
			my $ch1 = $aCh1->[$i];
			my $ch2 = $aCh2->[$i];
			next unless ($ch1 && $ch2);
			my $m = $self->calc_m($ch1, $ch2);
			my $a = $self->calc_a($ch1, $ch2);
			next unless ($m && $a);
			push(@$aMvalues, $m);
			push(@$aAvalues, $a);  
		}
		$self->{ _y_values } = $aMvalues;
		$self->{ _x_values } = $aAvalues;
	}
	sub plot_values {
		my $self = shift;
		my $aX = $self->x_values;
		my $aY = $self->y_values;
		my $scale  = $self->scale;
		my $middle = $self->middle;
		my ($y_min,$y_max,$y_range) = $self->data_range($aY);
		my ($x_min,$x_max,$x_range) = $self->data_range($aX);
		my $aXadjusted = [];
		my $aYadjusted = [];
		for (my $i=0; $i<@$aX; $i++){
			my $x = $aX->[$i];
			my $y = $aY->[$i];
			next unless ($x && $y);
			$x = (($x - $x_min) * $scale) + 50;
			$y = ($middle - ($y * $scale));
			push(@$aXadjusted, $x);
			push(@$aYadjusted, $y);  
		}
		$self->{ _plotx_values } = $aXadjusted;
		$self->{ _ploty_values } = $aYadjusted;
	}
	sub calc_m {
		my $self = shift;
		my $ch1  = shift;
		my $ch2  = shift;
		if (($ch1 == 0 )||($ch2 == 0)){
			return();  
		}
		return(log($ch1/$ch2)/log(2));
	}
	sub calc_a {
		my $self = shift;
		my $ch1  = shift;
		my $ch2  = shift;
		if (($ch1 == 0 )||($ch2 == 0)){
			return();  
		}
		return(log(0.5*($ch1*$ch2))/log(2));
	}
	sub default_scale {
		25; 
	}
}

{ package ri_plot;

	our @ISA = qw( ma_plot );

	sub process_data {
		my $self = shift;
		my $aCh1 = $self->ch1_values;
		my $aCh2 = $self->ch2_values;
		my $aRvalues = [];
		my $aIvalues = [];
		for (my $i=0; $i<@$aCh1; $i++){
			my $ch1 = $aCh1->[$i];
			my $ch2 = $aCh2->[$i];
			next unless ($ch1 && $ch2);
			my $r_val = $self->calc_r($ch1, $ch2);
			my $i_val = $self->calc_i($ch1, $ch2);  
			next unless ($r_val && $i_val);  
			push(@$aRvalues, $r_val);
			push(@$aIvalues, $i_val);
		}
		$self->{ _y_values } = $aRvalues;
		$self->{ _x_values } = $aIvalues;
	}
	sub calc_r {
		my $self = shift;
		my $ch1  = shift;
		my $ch2  = shift;
		if (($ch1 == 0 )||($ch2 == 0)){
			return();  
		}
		return(log($ch1/$ch2)/log(2));
	}
	sub calc_i {
		my $self = shift;
		my $ch1  = shift;
		my $ch2  = shift;
		if (($ch1 == 0 )||($ch2 == 0)){
			return();  
		}
		return(log($ch1*$ch2)/log(2));
	}
	# plot the outline of the diagram, ready for spots to be added
	sub plot_outline {
		my $self = shift;
		my $image = $self->gd_object;
		my $scale = $self->scale;
		## first allocated colour is set to background
		my $grey = $image->colorAllocate(180,180,180);
		my $aM   = $self->ploty_values;
		my $aA   = $self->plotx_values;
		my ($m_min,$m_max,$m_range) = $self->data_range($aM);
		my ($a_min,$a_max,$a_range) = $self->data_range($aA);
		my $middle = $self->middle;
		my $x_length = $self->x_length;
		my $y_length = $self->y_length;
		my $x_margin = $self->x_margin;
		my $y_margin = $self->y_margin;
		# get colours from the GD colour table 
		my $black = $image->colorExact(0,0,0);
		## x axis
		$image->filledRectangle(50,$y_length+50,$x_length+50,$y_length+50,$black);
		## y axis
		$image->filledRectangle(50,50,50,$y_length+50,$black);
		## x axis label
		my $max_label = int($a_max);
		my $min_label = int($a_min);
		$image->string(GD::Font->Giant,($x_length+50)/2,$y_length+80,"Log2(R*G)",$black);
		$image->string(GD::Font->Giant,(($a_min-$a_min)*$scale)+50,$y_length+70,"$min_label",$black);
		$image->string(GD::Font->Giant,(($a_max-$a_min)*$scale)+50,$y_length+70,"$max_label",$black);
		## y axis label
		$image->stringUp(GD::Font->Giant,10,$middle,"Log2(R/G)",$black);
		$image->stringUp(GD::Font->Giant,30,$middle - 25,"0",$black);
	}
	sub default_scale {
		25; 
	}
}
{ package intensity_scatter;

	our @ISA = qw( plot );

	sub plot_dimensions {
		my $self = shift;
		my $scale = $self->scale;
		my $aX    = $self->ch1_values;
		my $aY    = $self->ch2_values;
		my ($x_min,$x_max,$x_range) = $self->data_range($aX);
		my ($y_min,$y_max,$y_range) = $self->data_range($aY);
		my ($x,$y) = (int((65536/$scale)+1),int((65536/$scale)+1));
		if ($x_max > 65536){
			$x = int(($x_max/$scale)+1);
		}
		if ($y_max > 65536){
			$y = int(($y_max/$scale)+1);
		} 
		my $x_margin = 100;
		my $y_margin = 100;
		$self->{ _x_length } = $x;
		$self->{ _y_length } = $y;
		$self->{ _x_margin } = $x_margin;
		$self->{ _y_margin } = $y_margin;
		$self->{ _middle } = ($y + $y_margin)/2 ;
		return(($x + $x_margin), ($y + $y_margin));
	}
	sub plot_values {
		my $self = shift;
		my $aX = $self->x_values;
		my $aY = $self->y_values;
		my $scale  = $self->scale;
		my $x_length = $self->x_length;
		my $y_length = $self->y_length;
		my $x_margin = $self->x_margin;
		my $y_margin = $self->y_margin;
		my ($y_min,$y_max,$y_range) = $self->data_range($aY);
		my ($x_min,$x_max,$x_range) = $self->data_range($aX);
		my $aXadjusted = [];
		my $aYadjusted = [];
		for (my $i=0; $i<@$aX; $i++){
			my $x = $aX->[$i];
			my $y = $aY->[$i];
			next unless ($x && $y);
			$x = (($x/$scale))+50;
			$y = ($y_length-($y/$scale))+50;
			push(@$aXadjusted, $x);
			push(@$aYadjusted, $y);  
		}
		$self->{ _plotx_values } = $aXadjusted;
		$self->{ _ploty_values } = $aYadjusted;
	}
	# plot the outline of the diagram, ready for spots to be added
	sub plot_outline {
		my $self = shift;
		my $image = $self->gd_object;
		my $scale = $self->scale;
		## first allocated colour is set to background
		my $grey = $image->colorAllocate(180,180,180);
		my $aX   = $self->ch1_values;
		my $aY   = $self->ch2_values;
		my ($x_min,$x_max,$x_range) = $self->data_range($aX);
		my ($y_min,$y_max,$y_range) = $self->data_range($aY);
		my $middle = $self->middle;
		my $x_length = $self->x_length;
		my $y_length = $self->y_length;
		my $x_margin = $self->x_margin;
		my $y_margin = $self->y_margin;
		# get colours from the GD colour table 
		my $black = $image->colorExact(0,0,0);
		## x axis
		$image->line(50,$y_length+50,$x_length+50,$y_length+50,$black);
		## y axis
		$image->line(50,50,50,$y_length+50,$black);
		## x axis label
		my ($x_max_label,$y_max_label) = (65536,65536); 
		if ($x_max > 65536){
			$x_max_label = int($x_max+1);
		} 
		if ($y_max > 65536){
			$y_max_label = int($y_max+1);
		} 
		$image->string(GD::Font->Giant,($x_length+50)/2,$y_length+80,"Channel 1 Intensity",$black);
		$image->string(GD::Font->Giant,50,$y_length+50,"0",$black);
		$image->string(GD::Font->Giant,$x_length+50,$y_length+50,"$x_max_label",$black);
		## y axis label
		$image->stringUp(GD::Font->Giant,10,$middle,"Channel 2 Intensity",$black);
		$image->stringUp(GD::Font->Giant,30,$y_length+50,"0",$black);
		$image->stringUp(GD::Font->Giant,30,50,"$y_max_label",$black);
	}
	sub default_scale {
		200; 
	}
}

{ package heatmap;
  
	our @ISA = qw( plot );

	sub sort_data {
		my $self   = shift;
		my $oData  = $self->data_object;
		my $spot_count = $oData->spot_count;
		my $aCh1   = [];
		my $aCh2   = [];
		my $aXcoords = [];
		my $aYcoords = [];		
		for (my $i=0; $i<$spot_count; $i++){
			my $ch1 = $oData->channel1_signal($i);
			my $ch2 = $oData->channel2_signal($i);
			my $x_pos = $oData->x_pos($i);
			my $y_pos = $oData->y_pos($i);
			next if (($ch1 <= 0)||($ch2<=0));
			push(@$aCh1, $ch1);
			push(@$aCh2, $ch2);
			push(@$aXcoords, $x_pos);
			push(@$aYcoords, $y_pos);
		}
		$self->{ _ch1_values } = $aCh1;
		$self->{ _ch2_values } = $aCh2;
		$self->{ _x_coords }   = $aXcoords;
		$self->{ _y_coords }   = $aYcoords;
	}
	sub plot_dimensions {
		my $self  = shift;
		my $aY    = $self->y_coords;
		my $aX    = $self->x_coords;
		my ($y_min,$y_max,$y_range) = $self->data_range($aY);
		my ($x_min,$x_max,$x_range) = $self->data_range($aX);		
		my $scale = $self->calculate_scale($x_range,$y_range);  
		my $x = int((($x_max + $x_min) / $scale) +1);	# include margin, and round up 
		my $y = int((($y_max + $y_min) / $scale) +1);
		$self->{ _x_length } = $x;
		$self->{ _y_length } = $y;		
		return($x, $y);
	}
	sub plot_values {
		return;
	}
	# we dynamically set the scale to best match the array layout.
	#Êcan get the spot layout from the data file, if available 
	# or alternatively, the user can set the number of x/y spots
	# or alternatively, the default scale will be used 
	sub calculate_scale {
		my $self = shift;
		my ($x_range,$y_range) = @_;
		my $x_spots = $self->x_spots;
		my $y_spots = $self->y_spots;
		if ($x_spots && $y_spots){
			my $x_scale = $x_range/$x_spots;
			my $y_scale = $y_range/$y_spots;
			if ($x_scale < $y_scale){
				$self->scale(int($x_scale));
			} else {
				$self->scale(int($y_scale));
			}
		} 
		return $self->scale;
	}
	sub x_spots {
		my $self = shift;		
		if (@_){
			$self->{ _x_spots } = shift;
		} else {
			unless (defined $self->{ _x_spots }){
				my $oData  = $self->data_object;
				if ($oData->can('array_columns') && $oData->can('spot_columns')){
					$self->{ _x_spots } = $oData->array_columns * ($oData->spot_columns + 1);
				}
			}
			$self->{ _x_spots };
		}
	}
	sub y_spots {
		my $self = shift;		
		if (@_){
			$self->{ _y_spots } = shift;
		} else {
			unless (defined $self->{ _y_spots }){
				my $oData  = $self->data_object;
				if ($oData->can('array_rows') && $oData->can('spot_rows')){
					$self->{ _y_spots } = $oData->array_rows * ($oData->spot_rows + 1);
				}
			}
			$self->{ _y_spots };
		}
	}
	sub default_scale {
		140;
	}
}

{ package log2_heatmap;

	our @ISA = qw( heatmap );
  
	sub process_data {
		my $self = shift;
		my $aCh1 = $self->ch1_values;
		my $aCh2 = $self->ch2_values;
		my $aRatio = [];
		for (my $i=0; $i<@$aCh1; $i++){
			my $ch1 = $aCh1->[$i];
			my $ch2 = $aCh2->[$i];
			next unless ($ch1 && $ch2);
			push(@$aRatio, log($ch1/$ch2)/log(2));
		}
		$self->{ _x_values } = $aCh1;
		$self->{ _y_values } = $aCh2;
		$self->{ _ratio_values } = $aRatio;
	}
	sub plot_outline {
		my $self = shift;
		my $image = $self->gd_object;
		## first allocated colour is set to background
		my $grey = $image->colorAllocate(180,180,180);
	}
	sub plot_spots {
		my $self = shift;
		my $image = $self->gd_object;
		my $aXcoords = $self->x_coords;
		my $aYcoords = $self->y_coords;
		my $aRatio   = $self->ratio_values;
		my $scale    = $self->scale;
		$self->make_colour_grads;
		for (my $i=0; $i<@$aXcoords; $i++){
			my $x = $aXcoords->[$i];
			my $y = $aYcoords->[$i];
			my $ratio = $aRatio->[$i];
			next unless ($x && $y && $ratio);
			$x = int(($x / $scale) + 1);
			$y = int(($y / $scale) + 1);
			my $colour = $self->get_colour($ratio);
			$image->setPixel($x,$y,$colour);
		}
	}
	sub get_colour {
		my $self  = shift;
		my $ratio = shift;
		my $image = $self->gd_object;
		my $colour;
		if ($ratio <= -1.1){
			$colour = $image->colorExact(255,0,0);
		} elsif ($ratio >= 1.1){
			$colour = $image->colorExact(0,255,0); 
		} elsif ((0.1 > $ratio)&&($ratio > -0.1)) {
			$colour = $image->colorExact(255,255,0);
		} elsif ($ratio >= 0.1) {
			my $red_hue = 255 - (255 * ($ratio - 0.1));
			$colour = $image->colorClosest($red_hue,255,0);		# reducing red, closer to green
		} else {
			my $green_hue = 255 + (255 * ($ratio + 0.1));
			$colour = $image->colorClosest(255,$green_hue,0);	# reducing green, closer to red
		}
		return($colour);
	}  
	sub make_colour_grads {
		my $self  = shift;
		my $image = $self->gd_object;
		$image->colorAllocate(255,255,0);
		for (my $i = 0; $i<255; $i+=2){ 
			$image->colorAllocate($i,255,0);	## Add red -> green = yellow
			$image->colorAllocate(255,$i,0); 	## Add green -> red = yellow
		}	
	}
}

{ package intensity_heatmap;

	our @ISA = qw( heatmap );

	sub plot_outline {
		my $self = shift;
		my $image = $self->gd_object;
		## first allocated colour is set to background
		my $black = $image->colorAllocate(0,0,0);
	}
	sub plot_channel {
		my $self = shift;
		@_	?	$self->{ _plot_channel } = shift
			:	$self->{ _plot_channel };
	}
	sub plot_spots {
		my $self = shift;
		my $image = $self->gd_object;
		my $aXcoords = $self->x_coords;
		my $aYcoords = $self->y_coords;
		my $scale    = $self->scale;
		my $plot_channel;
		if ($self->plot_channel && ($self->plot_channel == 2)){
			$plot_channel = 'ch2_values';
		} else {
			$plot_channel = 'ch1_values';
		}
		my $aValues  = $self->$plot_channel;
		$self->make_colour_grads;
		for (my $i=0; $i<@$aXcoords; $i++){
			my $x = $aXcoords->[$i];
			my $y = $aYcoords->[$i];
			my $value = $aValues->[$i];
			next unless ($x && $y && $value);
			$x = int(($x / $scale) + 1);
			$y = int(($y / $scale) + 1);
			my $colour = $self->get_colour($value);
			$image->setPixel($x,$y,$colour);
		}
	}
	sub get_colour {
		my $self  = shift;
		my $value = shift;
		my $image = $self->gd_object;
		my $colour;
		if ($value == 0) {  ## if the value is 0 colour black
			$colour = $image->colorExact(0,0,0);
		} elsif ($value <= 13000) {  ## colour towards blue
			my $blue_hue = $value / 50.9;
			$colour = $image->colorClosest(0,0,$blue_hue);  
		} elsif ($value <= 26000) {  ## colour towards turquoise
			my $turquoise_hue = ($value - 13000) / 50.9;
			$colour = $image->colorClosest(0,$turquoise_hue,255);  
		} elsif ($value <= 39000) {  ## colour towards green
			my $green_hue = ($value - 26000) / 50.9;
			$colour = $image->colorClosest(0,255,255-$green_hue);  
		} elsif ($value <= 52000) {  ## colour towards yellow
			my $yellow_hue = ($value - 39000) / 50.9;
			$colour = $image->colorClosest($yellow_hue,255,0);  
		} elsif ($value < 65000) {  ## colour towards red
			my $red_hue = ($value - 52000) / 50.9;
			$colour = $image->colorClosest(255,255-$red_hue,0);  
		} elsif ($value >= 65000) {  ## if value is saturated colour white
			$colour = $image->colorExact(255,255,255);
		}
		return($colour);
	}
	# set a rainbow of graduated colours in the GD colour table, for use in the plot 
	sub make_colour_grads {
		my $self  = shift;
		my $image = $self->gd_object;
		my $count = 0;
		$image->colorAllocate(0,0,0); 
		for (my $i = 5; $i<=255; $i+=5){ 	
			$image->colorAllocate(0,0,$i);        ## Add blue up to 255 -> blue
			$image->colorAllocate(0,$i,255);      ## Add green up to 255 -> turquise
			$image->colorAllocate(0,255,255-$i);  ## Reduce blue -> green
			$image->colorAllocate($i,255,0);      ## Add red up to 255 -> yellow
			$image->colorAllocate(255,255-$i,0);  ## Reduce green -> red
		}	
	}
}


1;

__END__

=head1 NAME

Microarray::Image::QC_Plots - A Perl module for creating microarray QC/QA plots

=head1 SYNOPSIS

	use Microarray::Image::QC_Plots;
	use Microarray::File::Data;

	my $oData_File = data_file->new($data_file);
	my $oMA_Plot = ma_plot->new($oData_File);
	my $ma_plot_png = $oMA_Plot->make_plot;	

	open (PLOT,'>ma_plot.png');
	print PLOT $ma_plot_png;
	close PLOT;

=head1 DESCRIPTION

Microarray::Image::QC_Plots is an object-oriented Perl module for creating microarray QC/QA data plots from a scan data file, using the GD module and image library. A number of different plot types are supported, including MA/RI, intensity scatter, intensity heatmap and log2 heatmap. 

Mac Os X users beware - for some unknown reason, Apple's Preview application does not render the scatter or MA plots properly. 

=head1 QC/QA PLOT TYPES

There are several plots for viewing basic microarray data for QC/QA purposes. Most of the parameters for these plots are the same, and only the class name used to create the plot object differs from one plot to another.

=head2 Standard Data Plots

=over

=item B<ma_plot>

See the SYNOPSIS for all there is to know about how to create an MA plot. To create any of the other plot types, just append C<'ma_plot'> in the above example with one of the class names listed below. 

=item B<ri_plot>

An RI plot is basically identical to an MA plot - at least in appearance.

=item B<intensity_scatter>

This is a plot of channel 1 signal vs channel 2 signal.

=back

=head2 Heatmaps

=over 

=item B<intensity_heatmap>

An image of the slide, using a black->white rainbow colour gradient to indicate the signal intensity across the array. Uses channel 1 as the signal by default, but the channel can be changed by setting the C<plot_channel> parameter in the call to C<make_plot()>.

	my $oInt_Heatmap = intensity_heatmap->new($oData_File);
	my $int_heatmap_png = $oInt_Heatmap->make_plot(plot_channel=>2);

=item B<log2_heatmap>

An image of the slide using a red->yellow->green colour gradient to indicate the Log2 of the signal ratio across the array. 

=back

One difference between heatmaps and other plots is in their implementation of the plot scale. This is calculated dynamically in order to generate the best looking image of the array, and requires the dimensions of the array in terms of the number of spots in the x and y axes. If you are using a data file format that returns those values in its header information (such as a Scanarray file, using the Quantarray module) then the scale will be calculated automatically. If BlueFuse files are sorted such that the last data row has the highest block/spot row/column number, then again the scale can be calculated automatically. However, for GenePix files, you will have to pass these values to the make_plot() method (adding extra spots for block padding where appropriate);

	my $oLog2_Heatmap = log2_heatmap->new($oData_File);
	my $log_heatmap_png = $oLog2_Heatmap->make_plot(x_spots=>108, y_spots=>336);  

=head1 SEE ALSO

L<Microarray|Microarray>, L<Microarray::Image|Microarray::Image>, L<Microarray::File|Microarray::File>, L<Microarray::File::Data_File|Microarray::File::Data_File>

=head1 AUTHOR

James Morris, Gynaecological Cancer Research Laboratories, UCL EGA Institute for Women's Health, University College London.

L<http://www.instituteforwomenshealth.ucl.ac.uk/AcademicResearch/Cancer/trl>

james.morris@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by James Morris, University College London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
