package Image::ColorDetector;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.04";

use parent qw( Exporter );
our @EXPORT_OK = qw(
detect
);

use Carp ();

use Image::Magick;
use List::Util qw( max min );

sub detect {
	my ($file_path) = @_;

	Carp::croak(q{$file_path is required})
		unless (defined $file_path);

	my $hsvs_ref = _extract_hsv($file_path);
	my $color_names_ref = _allot_color_name($hsvs_ref);
	my $color_palette = _count_up_for_each_color_name($color_names_ref);
	my $color_name = _main_color_name($color_palette);

	if ($color_name) {
		return $color_name;
	}
	else {
		return;
	}
}

sub _extract_hsv {
	my ($img) = @_;
	$img or return;

	my $im = Image::Magick->new;
	open(IMAGE, $img);

	my $ret = $im->Read(file => \*IMAGE);

	if ($ret) {
		Carp::croak("$ret\ninvalid image source: $!");
	}

	close(IMAGE);

	my ($w, $h) = $im->Get('width', 'height');

	my @pixels = $im->GetPixels(
		width => $w,
		height => $h,
		x => 0,
		y => 0,
		map => 'RGB',
	);

	my @rgbs;
	my @hsvs;
	while (@pixels) {
		my %rgb_hash;
		$rgb_hash{r} = (int((shift @pixels) / 256) / 255);
		$rgb_hash{g} = (int((shift @pixels) / 256) / 255);
		$rgb_hash{b} = (int((shift @pixels) / 256) / 255);
		push @rgbs, \%rgb_hash;

		my $max = max $rgb_hash{r}, $rgb_hash{g}, $rgb_hash{b};
		my $min = min $rgb_hash{r}, $rgb_hash{g}, $rgb_hash{b};

		next if ($max <= 0);

		my %hsv_hash;
		$hsv_hash{v} = $max;
		$hsv_hash{s} = 255 * ( ($max - $min) / $max );

		if ($hsv_hash{s} == 0) {
			next;
		}
		elsif ($max == $rgb_hash{r}) {
			$hsv_hash{h} = 60 * ( ($rgb_hash{g} - $rgb_hash{b}) / ($max - $min) );
		}
		elsif ($max == $rgb_hash{g}) {
			$hsv_hash{h} = 60 * ( 2 + ($rgb_hash{b} - $rgb_hash{r}) / ($max - $min) );
		}
		elsif ($max == $rgb_hash{b}) {
			$hsv_hash{h} = 60 * ( 4 + ($rgb_hash{r} - $rgb_hash{g}) / ($max - $min) );
		}
		else {
			next;
		}
		push @hsvs, \%hsv_hash;
	}
	return \@hsvs;
}

sub _allot_color_name {
	my ($hsvs) = @_;

	return
		if (!$hsvs || ref($hsvs) ne 'ARRAY');

	my @hsv_with_color;
	for my $hsv (@$hsvs) {
		if (!$hsv->{h}) {
			next;
		}
		elsif (($hsv->{h} >= 0 && $hsv->{h} < 20) || ($hsv->{h} >= 330 && $hsv->{h} < 360)) {
			$hsv->{color} = 'RED';
		}
		elsif ($hsv->{h} >= 20 && $hsv->{h} < 50) {
			$hsv->{color} = 'ORANGE';
		}
		elsif ($hsv->{h} >= 50 && $hsv->{h} < 70) {
			$hsv->{color} = 'YELLOW';
		}
		elsif ($hsv->{h} >= 70 && $hsv->{h} < 85) {
			$hsv->{color} = 'LIME';
		}
		elsif ($hsv->{h} >= 85 && $hsv->{h} < 171) {
			$hsv->{color} = 'GREEN';
		}
		elsif ($hsv->{h} >= 171 && $hsv->{h} < 192) {
			$hsv->{color} = 'AQUA';
		}
		elsif ($hsv->{h} >= 192 && $hsv->{h} < 265) {
			$hsv->{color} = 'BLUE';
		}
		elsif ($hsv->{h} >= 265 && $hsv->{h} < 290) {
			$hsv->{color} = 'VIOLET';
		}
		elsif ($hsv->{h} >= 290 && $hsv->{h} < 330) {
			$hsv->{color} = 'PURPLE';
		}
		else {
			next;
		}
		push @hsv_with_color, $hsv;
	}
	return \@hsv_with_color;
}

sub _count_up_for_each_color_name {
	my ($hsv_with_color) = @_;

	return
		if (!$hsv_with_color || ref($hsv_with_color) ne 'ARRAY');

	my %color_palette = (
		RED		=> 0,
		ORANGE	=> 0,
		YELLOW	=> 0,
		LIME	=> 0,
		GREEN	=> 0,
		AQUA	=> 0,
		BLUE	=> 0,
		VIOLET	=> 0,
		PURPLE	=> 0,
	);

	my @colors = map { $_->{color} } @$hsv_with_color;
	for my $color (@colors) {
		for my $palette_key (keys %color_palette) {
			if ($color eq $palette_key) {
				$color_palette{$palette_key}++;
			}
		}
	}
	return \%color_palette;
}

sub _main_color_name {
	my ($color_palette_href) = @_;

	return
		if (!$color_palette_href || ref($color_palette_href) ne 'HASH');

	return 'BLACK-AND-WHITE'
		unless (grep { $_ > 0 } values %$color_palette_href);

	my @sorted_colors =
		map {
			$_->[0]
		}
			sort {
				$b->[1] <=> $a->[1]
			}
				map {
					[$_, $color_palette_href->{$_}]
				}
					keys %$color_palette_href;

	return shift @sorted_colors;
}




1;
__END__

=encoding utf-8

=head1 NAME

Image::ColorDetector - return the color name of the image file as a string

=head1 SYNOPSIS

    use Image::ColorDetector qw( detect );

    my $color_name_char = detect($path_to_image);


=head1 DESCRIPTION

Image::ColorDetector is a module which detects a color name from a image file(binary file).

=head1 LICENSE

Copyright (C) libitte.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

libitte E<lt>libitte3@gmail.comE<gt>

=cut

