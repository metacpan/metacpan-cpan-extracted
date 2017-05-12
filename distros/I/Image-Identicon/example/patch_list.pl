#! /usr/bin/perl
## ----------------------------------------------------------------------------
#  Image::Identicon/example/patch_list.pl
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2007 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: /perl/Image-Identicon/example/patch_list.pl 333 2007-02-02T12:18:34.932417Z hio  $
# -----------------------------------------------------------------------------
use strict;
use warnings; # FATAL => 'all';
#use base qw(Exporter);
#our @EXPORT_OK = qw();
#our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use lib 'lib';
use GD;
use Image::Identicon;

our $DEBUG = 0;
caller or __PACKAGE__->do_work(@ARGV);

# -----------------------------------------------------------------------------
# main.
#
sub do_work
{
	my $rpkg = 'Image::Identicon::Render';

	my $patch_size = $rpkg->_patch_size;
	my $scale = 3;
	my $patch_width = ($patch_size-1) * $scale + 2;
	my $frame_size = $patch_width+6;

	my $ch = 10; # char height.
	my $cw = 6; # char width.

	my $canvas_width  = $frame_size*8 + 6;
	my $canvas_height = $frame_size*2 + 6 + $ch*2 + $ch-1;
	$DEBUG and print STDERR "(patch_size, scale) = ($patch_size, $scale)\n";
	$DEBUG and print STDERR "frame_size = $frame_size\n";
	$DEBUG and print STDERR "canvas = ($canvas_width, $canvas_height)\n";

	# create canvas.
	my $canvas = GD::Image->new($canvas_width, $canvas_height, 1);
	my $canvas_back = $canvas->colorAllocate(255,255,255); # white.
	my $frame_color = $canvas->colorAllocate(0,0,0); # black.
	$canvas->filledRectangle(0, 0, $canvas_width, $canvas_height, $canvas_back);
	$canvas->rectangle(0, 0, $canvas_width-1, $canvas_height-1, $frame_color);

	# draw each patch.
	for my $patch (0..15)
	{
		my $image = GD::Image->new($patch_width, $patch_width, 1);
		my $back_color   = $image->colorAllocate(255,255,255); # white.
		my $stroke_color = $image->colorAllocate(0, 0, 0);     # black or red.
		my $fore_color   = $image->colorAllocate(80, 80, 80);  # dark gray.
		
		# dummy render.
		my $render = bless{
			image => $image,
			scale => $scale,
			fore_color => $fore_color,
			back_color => $back_color,
			stroke_color => $stroke_color,
		}, $rpkg;
		$render->draw({
			x => 0, y => 0,
			patch => $patch, turn => 0, invert => 0,
		});
		
		# copy to canvas.
		my $x = 3 + int($patch%8) * $frame_size + 3;
		my $y = 3 + int($patch/8) * ($frame_size +8) + 3;
		$DEBUG and print STDERR "(x, y) = ($x, $y)\n";
		$canvas->copy($render->{image}, $x, $y, 0, 0, $patch_width, $patch_width);
		
		# draw frame.
		my $x2 = $x + $patch_width;
		my $y2 = $y + $patch_width;
		$canvas->rectangle($x-1, $y-1, $x2, $y2, $frame_color);
		
		# draw number.
		my $slen = length($patch);
		my $cx = $x+($patch_width-$cw*($slen+0.5));
		$canvas->string(gdSmallFont, $cx, $y+$patch_width, $patch, $frame_color);
	}

	{
		# draw number.
		my $text = "patch list";
		my $slen = length($text);
		my $cx = $canvas_width - 2 - $cw*length($text);
		my $cy = 3 + 2 * ($frame_size +8) + 2;
		$canvas->string(gdSmallFont, $cx, $cy, $text, $frame_color);
	}

	binmode(*STDOUT);
	print $canvas->png;
}

# -----------------------------------------------------------------------------
# End of Module.
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
__END__

=encoding utf8

=for stopwords
	YAMASHINA
	Hio
	ACKNOWLEDGEMENTS
	AnnoCPAN
	CPAN
	RT

=head1 NAME

patch_list.pl - generate patch sumnail image.

=head1 SYNOPSIS

  $ perl patch_list.pl > patch_list.png


=head1 SEE ALSO

L<Image::Identicon>

=cut
