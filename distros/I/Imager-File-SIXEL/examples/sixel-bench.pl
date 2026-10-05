#!/usr/bin/env perl
# Measures SIXEL encoding speed for several image sizes and settings.
#
# Copyright (C) 2026 davenonymous.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
use v5.24;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use Getopt::Long qw(GetOptions);
use Imager;
use Imager::File::SIXEL;
use Imager::Fill;
use Imager::Fountain;
use Pod::Usage qw(pod2usage);
use Time::HiRes qw(time);

my %options = (seconds => 1, sizes => '256x256,192x128,640x480');
GetOptions(\%options, 'file=s', 'sizes=s', 'seconds=f', 'help')
	or pod2usage(2);
pod2usage(1) if $options{help};

my @settings = (
	['diffusion, adaptive' => { sixel_dither => 'diffusion', sixel_palette => 'adaptive' }],
	['ordered, adaptive'   => { sixel_dither => 'ordered',   sixel_palette => 'adaptive' }],
	['none, adaptive'      => { sixel_dither => 'none',      sixel_palette => 'adaptive' }],
	['ordered, webmap'     => { sixel_dither => 'ordered',   sixel_palette => 'webmap' }],
	['none, webmap'        => { sixel_dither => 'none',      sixel_palette => 'webmap' }],
);

# A smooth multi-color picture with a little noise, standing in for a
# photograph when no --file is given.
sub syntheticImage() {
	my $img = Imager->new(xsize => 1024, ysize => 768);
	$img->box(fill => Imager::Fill->new(
		fountain => 'radial',
		xa       => 300,
		ya       => 250,
		xb       => 1024,
		yb       => 768,
		segments => Imager::Fountain->simple(
			positions => [0, 0.3, 0.6, 1],
			colors    => [map { Imager::Color->new($_) } '#F2D7A6', '#C8553D', '#2D6A4F', '#1B263B'],
		),
	));
	return $img->filter(type => 'noise', amount => 12, subtype => 0) ? $img : die $img->errstr;
}

my $source = $options{file} ? Imager->new(file => $options{file}) : syntheticImage();
die Imager->errstr, "\n" unless $source;

printf "%-9s  %-20s  %9s  %8s  %10s\n", 'size', 'settings', 'ms/frame', 'fps', 'bytes';
foreach my $size (split /,/, $options{sizes}) {
	my ($width, $height) = $size =~ /^(\d+)x(\d+)$/ or die "invalid size '$size'\n";
	my $img = $source->scale(xpixels => $width, ypixels => $height, type => 'nonprop');

	foreach my $setting (@settings) {
		my ($label, $writeOptions) = $setting->@*;
		my ($frames, $sixel) = (0, '');
		my $start = time;
		while (time - $start < $options{seconds}) {
			$sixel = '';
			$img->write(data => \$sixel, type => 'sixel', $writeOptions->%*) or die $img->errstr, "\n";
			++$frames;
		}
		my $seconds = (time - $start) / $frames;
		printf "%-9s  %-20s  %9.2f  %8.0f  %10d\n", $size, $label, 1000 * $seconds, 1 / $seconds, length $sixel;
	}
}

__END__

=head1 NAME

sixel-bench.pl - measure SIXEL encoding speed

=head1 SYNOPSIS

  sixel-bench.pl [--file IMAGE] [--sizes WxH,...] [--seconds DURATION]

=head1 DESCRIPTION

Scales a picture to each requested size and encodes it repeatedly with
each combination of dithering and palette settings, reporting the time
per frame, the resulting frame rate and the size of the SIXEL data.
The time covers the complete C<< $img->write(data => \$buffer, type =>
'sixel') >> call.

=head1 OPTIONS

=over

=item --file IMAGE

The picture to encode. Without it a synthetic 1024 x 768 picture with
smooth gradients and noise is used.

=item --sizes WxH,...

Comma separated frame sizes, C<256x256,192x128,640x480> by default.

=item --seconds DURATION

How long to encode each combination, 1 second by default.

=back

=cut
