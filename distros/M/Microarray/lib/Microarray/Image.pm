package Microarray::Image;

use 5.008;
use strict;
use warnings;
our $VERSION = '1.27';

use GD;
use GD::Image;
use Microarray::File;

{ package plot;
  
	sub new {
		my $class = shift;
		my $self  = { };
		if (@_){
			$self->{ _data_object } = shift;
			bless $self, $class;
			$self->set_data;
		} else {
			bless $self, $class;
		}
		return $self;
	}
	sub gd_object {
		my $self = shift;
		$self->{ _gd_object };
	}
	sub parse_args {
		my $self = shift;
		my %hArgs = @_;
		while(my($arg,$val) = each %hArgs){
			if ($self->can($arg)){
				$self->$arg($val);
			} else {
				die "Microrray::Image ERROR; No parameter '$arg' is defined\n";
			}
		}
	}
	sub set_data {
		my $self = shift;
		if (@_) {
			$self->{ _data_object } = shift;
		} 
		die "Microarray::Image ERROR: No data object provided\n" unless $self->data_object;
		$self->sort_data;
		## polymorphic method to process data such as MA RI log2 etc
		$self->process_data;
	}
	## from data object the background adjusted intensity of ch1 and ch2
	## are set in the plot image object
	sub sort_data {
		my $self   = shift;
		my $oData  = $self->data_object;
		my $spot_count = $oData->spot_count;
		my $aCh1   = [];
		my $aCh2   = [];
		for (my $i=0; $i<$spot_count; $i++){
			my $ch1 = $oData->channel1_signal($i);
			my $ch2 = $oData->channel2_signal($i);
			next if (($ch1 <= 0)||($ch2<=0));
			push(@$aCh1, $ch1);
			push(@$aCh2, $ch2);
		}
		$self->{ _ch1_values } = $aCh1;
		$self->{ _ch2_values } = $aCh2;
	}
	sub process_data {
		my $self = shift;
		my $aCh1 = $self->ch1_values;
		my $aCh2 = $self->ch2_values;
		## if a process_data method is not set in plot class, simply use the raw intensity data
		$self->{ _x_values } = $aCh1;
		$self->{ _y_values } = $aCh2;
	}
	## create a GD image and draw on it the desired plot
	sub make_plot {
		my $self  = shift;
		if (@_) {
			$self->parse_args(@_);
		}
		## Get the x and y coordiantes of the plot, dynamicaly set by the size of the dataset
		my ($x, $y) = $self->plot_dimensions;
		## normalise the plot data according to the plot dimensions
		$self->plot_values;
		$self->{ _gd_object } = GD::Image->new($x,$y);	

		$self->plot_outline;
		$self->plot_spots;
		$self->return_image;
	}
	sub return_image {
		my $self = shift;
		my $image = $self->gd_object;
		$image->png;
	}
	sub plot_dimensions {
		my $self = shift;
		my $scale = $self->scale;
		my $aY   = $self->y_values;
		my $aX   = $self->x_values;
		my ($y_min,$y_max,$y_range) = $self->data_range($aY);
		my ($x_min,$x_max,$x_range) = $self->data_range($aX);
		my $x = ($x_range * $scale);
		my $y = ($y_range * $scale);
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
		## if a plot_values method is not set in plot class, simply plot the raw data
		$self->{ _plotx_values } = $aX;
		$self->{ _ploty_values } = $aY;
	}
	sub set_plot_background {
		my $self = shift;
		my $image = $self->gd_object;
		## first allocated colour is set to background
		my $grey = $image->colorAllocate(180,180,180);
	}
	# plot the outline of the diagram, ready for spots to be added
	sub plot_outline {
		my $self = shift;
		my $image = $self->gd_object;
		my $scale = $self->scale;
		$self->set_plot_background;
		my $aY   = $self->ploty_values;
		my $aX   = $self->plotx_values;
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
		$image->filledRectangle(50,$y_length+50,$x_length+50,$y_length+50,$black);
		## y axis
		$image->filledRectangle(50,50,50,$y_length+50,$black);
		## x axis label
		my $max_label = int($x_max);
		my $min_label = int($x_min);
		$image->string(GD::Font->Giant,($x_length+50)/2,$y_length+80,"(0.5)*Log2(R*G)",$black);
		$image->string(GD::Font->Giant,(($x_min-$x_min)*$scale)+50,$y_length+70,"$min_label",$black);
		$image->string(GD::Font->Giant,(($x_max-$x_min)*$scale)+50,$y_length+70,"$max_label",$black);
		## y axis label
		$image->stringUp(GD::Font->Giant,10,$middle,"Log2(R/G)",$black);
		$image->stringUp(GD::Font->Giant,30,$middle - 25,"0",$black);
	}
	## given a GD image object and X and Y data arrays this method will plot on the 
	## image each X,Y data point in black
	sub plot_spots {
		my $self = shift;
		my $image = $self->gd_object;
		my $aX   = $self->plotx_values;
		my $aY   = $self->ploty_values;
		my $black = $image->colorExact(0,0,0);
		for (my $i=0; $i<@$aX; $i++){
			my $x = $aX->[$i];
			my $y = $aY->[$i];
			next unless ($x && $y);
			$image->filledEllipse($x,$y,3,3,$black);
		}
	}
	## finds the minimum, maximum and range of an array of data 
	sub data_range {
		use Statistics::Descriptive;
		my $self = shift;
		my $aData = shift;
		my $stat = Statistics::Descriptive::Full->new();
		$stat->add_data(@$aData);
		my $min = $stat->min();
		my $max = $stat->max();
		my $range = $stat->sample_range();
		return($min,$max,$range);
	}
	## set graduated colours in the GD colour table, for use in the plot
	## from red-yellow-green 
	sub make_colour_grads {
		my $self  = shift;
		my $image = $self->gd_object;
		my $count = 0;
		for (my $i = 0; $i<=255; $i+=5){ 	
			$image->colorAllocate($i,255,0);
			$image->colorAllocate(255,$i,0);
		}	
		$image->colorAllocate(0,0,0);		
	}
	sub print_image {
		my $self = shift;
		my $image = $self->gd_object;
		if (@_) {
			$self->{ _print_location} = shift;
			$self->{ _image_name} = shift;
		}
		my $name  = $self->get_image_name;  
		my $print_location = $self->print_location;
		open FH, $print_location.$name.".png";
		binmode(FH);
		print FH $image->png;
		close(FH);
	}
	sub get_image_name {
		my $self = shift;
		unless (defined $self->{ _image_name }){
			$self->set_image_name;
		}
		$self->{ _image_name };
	}
	sub set_image_name {
		my $self = shift;
		## need to concat plot type and data source(file name/db id)
		my $image_name = 'image';
		$self->{ _image_name } = $image_name;
	}
	sub print_location {
		my $self = shift;
		if (@_)	{
			$self->{ _print_location } = shift;
		} else {
			if (defined $self->{ _print_location }){
				$self->{ _print_location };
			} else {
				die "Microarray::Image ERROR; No print destination defined\n";
			}
		}
	}
	sub file_path {
		my $self = shift;
		$self->{ _file_path };
	}
	sub microarray_file {
		my $self = shift;
		$self->{ _microarray_file };
	}
	sub ch1_values {
		my $self = shift;
		$self->{ _ch1_values };
	}
	sub ch2_values {
		my $self = shift;
		$self->{ _ch2_values };
	}
	sub middle {
		my $self = shift;
		$self->{ _middle };
	}
	sub scale {
		my $self = shift;
		if (@_){
			$self->{ _scale } = shift;
		} else {
			if (defined $self->{ _scale }){
				$self->{ _scale };
			} else {
				$self->default_scale;
			}
		}
	}
	sub x_length {
		my $self = shift;
		$self->{ _x_length };
	}
	sub y_length {
		my $self = shift;
		$self->{ _y_length };
	}
	sub x_margin {
		my $self = shift;
		$self->{ _x_margin };
	}
	sub y_margin {
		my $self = shift;
		$self->{ _y_margin };
	}
	sub x_values {
		my $self = shift;
		$self->{ _x_values };
	}
	sub y_values {
		my $self = shift;
		$self->{ _y_values };
	}
	sub plotx_values {
		my $self = shift;
		$self->{ _plotx_values };
	}
	sub ploty_values {
		my $self = shift;
		$self->{ _ploty_values };
	}
	sub ratio_values {
		my $self = shift;
		$self->{ _ratio_values };
	}
	sub x_coords {
		my $self = shift;
		$self->{ _x_coords };
	}
	sub y_coords {
		my $self = shift;
		$self->{ _y_coords };
	}
	sub data_object {
		my $self = shift;
		@_	?	$self->{ _data_object } = shift
			:	$self->{ _data_object };
	}
	sub data {
		my $self = shift;
		$self->{ _data };
	}
}


1;

__END__

=head1 NAME

Microarray::Image - A Perl module for creating microarray data plots

=head1 SYNOPSIS

	use Microarray::Image;

=head1 DESCRIPTION

Microarray::Image is an object-oriented Perl module for creating microarray data plots from a scan data file, using the GD module and image library. Currently, only the export of PNG (Portable Network Graphics - or 'PNGs Not GIFs') images is supported.   

=head1 SEE ALSO

L<Microarray|Microarray>, L<Microarray::Image::QC_Plots|Microarray::Image::QC_Plots>, L<Microarray::Image::CGH_Plot|Microarray::Image::CGH_Plot>, L<Microarray::File|Microarray::File>, L<Microarray::File::Data_File|Microarray::File::Data_File>

=head1 PREREQUISITES

This module utilises the L<GD|GD> module, which requires installation of Thomas Boutell's GD image library (L<http://www.libgd.org>). 

=head1 AUTHOR

James Morris, Gynaecological Cancer Research Laboratories, UCL EGA Institute for Women's Health, University College London.

L<http://www.instituteforwomenshealth.ucl.ac.uk/AcademicResearch/Cancer/trl>

james.morris@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by James Morris, University College London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
