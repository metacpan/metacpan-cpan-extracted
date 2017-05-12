#!/usr/bin/env perl

use strict;
use warnings;

use Image::Magick::Chart::HorizontalBars;

# -----------------------

Image::Magick::Chart::HorizontalBars -> new
(
	antialias				=> 0,	# 0 => No antialias; 1 => Antialias.
	bar_width				=> 8,	# Pixels.
	bg_color				=> 'white',
	colorspace				=> 'RGB',
	depth					=> 8,	# Bits per channel.
	fg_color				=> 'blue',
	font					=> 'Courier',
	frame_color				=> 'black',
	frame_option			=> 1,	# 0 => None; 1 => Draw it.
	height					=> 0,
	image					=> '',
	output_file_name		=> 'image-1.png',
	padding					=> [30, 30, 30, 30],	# [12 noon, 3, 6, 9].
	pointsize				=> 14,	# Points.
	tick_length				=> 4,	# Pixels.
	title					=> 'Percent (%)',
	width					=> 0,
	x_axis_data				=> [0, 20, 40, 60, 80, 100],
	x_axis_labels			=> [0, 20, 40, 60, 80, 100],
	x_axis_labels_option	=> 1,	# 0 => None; 1 => Draw them.
	x_axis_ticks_option		=> 2,	# 0 => None; 1 => Below x-axis; 2 => Across frame.
	x_data					=> [15, 5, 70, 25, 45, 20, 65],
	x_data_option			=> 1,
	x_pixels_per_unit		=> 3,	# Horizontal width of each data unit.
	y_axis_data				=> [1 .. 7, 8], # 7 data points, plus 1 to make result pretty.
	y_axis_labels			=> [(map{"($_)"} reverse (1 .. 7) ), ''],
	y_axis_labels_option	=> 1,	# 0 => None; 1 => Draw them.
	y_axis_ticks_option		=> 1,	# 0 => None; 1 => Left of y-axis; 2 => Across frame.
	y_pixels_per_unit		=> 20,
) -> draw();

Image::Magick::Chart::HorizontalBars -> new
(
	antialias				=> 0,	# 0 => No antialias; 1 => Antialias.
	bar_width				=> 8,	# Pixels.
	bg_color				=> 'white',
	colorspace				=> 'RGB',
	depth					=> 8,	# Bits per channel.
	fg_color				=> 'blue',
	font					=> 'Courier',
	frame_color				=> 'black',
	frame_option			=> 1,	# 0 => None; 1 => Draw it.
	height					=> 0,
	image					=> '',
	output_file_name		=> 'image-2.png',
	padding					=> [30, 30, 30, 30],	# [12 noon, 3, 6, 9].
	pointsize				=> 14,	# Points.
	tick_length				=> 4,	# Pixels.
	title					=> 'Mean',
	width					=> 0,
	x_axis_data				=> [0 .. 5],
	x_axis_labels			=> [0 .. 5],
	x_axis_labels_option	=> 1,	# 0 => None; 1 => Draw them.
	x_axis_ticks_option		=> 2,	# 0 => None; 1 => Below x-axis; 2 => Across frame.
	x_data					=> [4.0, 3.5, 4.0, 4.6, 3.9, 4.0, 3.0, 3.0, 3.8, 4.0, 3.5],
	x_data_option			=> 1,
	x_pixels_per_unit		=> 60,	# Horizontal width of each data unit.
	y_axis_data				=> [1 .. 11, 12], # 11 data points, plus 1 to make result pretty.
	y_axis_labels			=> [reverse (1 .. 11), ''],
	y_axis_labels_option	=> 1,	# 0 => None; 1 => Draw them.
	y_axis_ticks_option		=> 1,	# 0 => None; 1 => Left of y-axis; 2 => Across frame.
	y_pixels_per_unit		=> 20,
) -> draw();
