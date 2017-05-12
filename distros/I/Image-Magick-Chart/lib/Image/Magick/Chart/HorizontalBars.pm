package Image::Magick::Chart::HorizontalBars;

use parent Image::Magick::Chart;
use strict;
use warnings;

use Carp;

use Image::Magick::Chart;

our $VERSION = '1.07';

# -----------------------------------------------

sub draw
{
	my($self) = @_;

	$self -> draw_frame()			if ($self -> frame_option);
	$self -> draw_x_axis_ticks()	if ($self -> x_axis_ticks_option);
	$self -> draw_x_axis_labels()	if ($self -> x_axis_labels_option);
	$self -> draw_y_axis_ticks()	if ($self -> y_axis_ticks_option);
	$self -> draw_y_axis_labels()	if ($self -> y_axis_labels_option);
	$self -> draw_horizontal_bars();
	$self -> draw_title()			if ($self -> title);
	$self -> write();

}	# End of draw.

# -----------------------------------------------

1;

__END__

=head1 NAME

C<Image::Magick::Chart::HorizontalBars> - Use Image::Magick to create charts.

=head1 Synopsis

	#!/usr/bin/env perl

	use Image::Magick::Chart::HorizontalBars;

	Image::Magick::Chart::HorizontalBars -> new
	(
		antialias            => 0, # 0 => No antialias; 1 => Antialias.
		bar_width            => 8, # Pixels.
		bg_color             => 'white',
		colorspace           => 'RGB',
		depth                => 8, # Bits per channel.
		fg_color             => 'blue',
		font                 => 'Courier',
		frame_color          => 'black',
		frame_option         => 1, # 0 => None; 1 => Draw it.
		height               => 0,
		image                => '',
		output_file_name     => 'image-1.png',
		padding              => [30, 30, 30, 30], # [12 noon, 3, 6, 9].
		pointsize            => 14, # Points.
		tick_length          => 4,  # Pixels.
		title                => 'Percent (%)',
		width                => 0,
		x_axis_data          => [0, 20, 40, 60, 80, 100],
		x_axis_labels        => [0, 20, 40, 60, 80, 100],
		x_axis_labels_option => 1, # 0 => None; 1 => Draw them.
		x_axis_ticks_option  => 2, # 0 => None; 1 => Below x-axis; 2 => Across frame.
		x_data               => [15, 5, 70, 25, 45, 20, 65],
		x_data_option        => 1,
		x_pixels_per_unit    => 3, # Horizontal width of each data unit.
		y_axis_data          => [1 .. 7, 8], # 7 data points, plus 1 to make image pretty.
		y_axis_labels        => [(map{"($_)"} reverse (1 .. 7) ), ''],
		y_axis_labels_option => 1, # 0 => None; 1 => Draw them.
		y_axis_ticks_option  => 1, # 0 => None; 1 => Left of y-axis; 2 => Across frame.
		y_pixels_per_unit    => 20,
	) -> draw();

This code is part of examples/test-chart.pl.

Note: You do not need to specify all the options above, of course, but only those you
wish to differ from the defaults. I have included all options in examples/test-chart.pl
just to save you the effort of having to type them in.

=head1 Description

C<Image::Magick::Chart::HorizontalBars> is a pure Perl module.

This module uses Image::Magick to create simple charts (images consisting of horizontal bars)
with optional axes, axis labels, etc.

See examples/image-*.png for sample output, and examples/test-chart.pl for the program
which created those samples.

See the docs for C<Image::Magick::Chart> for details.

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Constructor and initialization

new(...) returns a C<Image::Magick::Chart::HorizontalBars> object.

This is the class contructor.

Usage: Image::Magick::Chart::HorizontalBars -> new().

This method takes a set of parameters.

For each parameter you wish to use, call new as new(param_1 => value_1, ...).

Any parameter which is supported by the parent class, Image::Magick::Chart, can be used
in the call the C<new()> in this class. So, see the docs for Image::Magick::Chart.

=head1 Methods

=head2 draw()

Output the chart.

=head2 new(...)

Returns a object of type C<Image::Magick::Chart::HorizontalBars>.

See above, in the section called 'Constructor and initialization' for details.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/Image-Magick-Chart>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Image-Magick-Chart>.

=head1 Author

C<Image::Magick::Chart::HorizontalBars> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2005.

L<Homepage|http://savage.net.au/>

=head1 Copyright

Australian copyright (c) 2005, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
