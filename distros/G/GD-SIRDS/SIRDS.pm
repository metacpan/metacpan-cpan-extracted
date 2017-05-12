package GD::SIRDS;

=head1 NAME

GD::SIRDS - Create a GD image of a Single Image Random Dot Stereogram

=head1 SYNOPSIS

  use GD;
  use GD::SIRDS;

  my ($src, $dst, @colors);

  $src = GD->new("some.png");
  @colors = (
      [  0,  0,  0],  # basic black
      [204,204,204],  # a nice grey
      [  0, 51,102],  # a good dark blue-green
      [  0,102,153],  # another good blue-green
  );

  $dst = gd_sirds($src, \@colors);
  
  binmode STDOUT;
  print $dst->png;

=head1 DESCRIPTION

C<GD::SIRDS> exports a single subroutine, C<gd_sirds>, that produces a
Single Image Random Dot Stereogram (SIRDS).

=cut

use 5.006;
use strict;
use warnings;

our $VERSION = '0.02';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
	gd_sirds
);

use Carp;
use POSIX;
use GD;

use constant DEPTH_OF_FIELD => 1/3;
use constant EYE_SEPARATION => 200;

=over 4

=item gd_sirds MAP,COLORS 

=item gd_sirds MAP,COLORS,CIRCLES

=item gd_sirds MAP,COLORS,CIRCLES,EYESEP

=item gd_sirds MAP,COLORS,CIRCLES,EYESEP,FIELDDEPTH

Create a Single Image Random Dot Stereogram based on the given depth
MAP, with random dot colors selected from COLORS.

The depth map can be either an instance of GD::Image or a reference to a
two-dimensional array of numbers between 0 and 1, inclusive.  Lighter
colors (for C<GD::Image>s) and higher numbers (for arrays) stick out
more from the background.

COLORS is a reference to an array of RGB triples, each triple represented
as an array of three integers between 0 and 255, as in L<GD(3)>.

Set CIRCLES to true to put two circles at the bottom of the image
representing the amount ones eyes need to diverge.  (Aligning the
circles so that the two become three should produce the proper
divergence to see the stereogram.)

EYESEP is the separation, in pixels, of the viewer's eyes.  For a computer
monitor, the default of 200 seems to work well.

FIELDDEPTH is a bit trickier.  Assume that the three-dimensional object
displayed has an apparent distance from the viewer equal to twice the
distance from the viewer to the screen.  That is, the bottom of the object
is as far behind the screen as the viewer is in front of the screen.  In
that case, the top of the three-dimensional object is FIELDDEPTH
(default 1/3) of the way up back to the screen.

=cut

sub gd_sirds
{
	my $map = shift;			# depth map
	my $colors = shift;			# dot colors

	my $helper_circles = shift || 0;	# draw helper circles?

	my $eye = shift || EYE_SEPARATION;	# eye separation
	my $dof = shift || DEPTH_OF_FIELD;	# depth of field

	warn "GD::SIRDS::gd_sirds params loaded" if $main::GD_DEBUGGING;

	# check map for correctness and convert to a two-dimensional
	#   array if it isn't one already
	if (ref $map eq "ARRAY") {
		my $firstlen = @{$map->[0]};
		for (@$map) {
			croak "need a GD::Image or a two-dimensional array"
			    unless ref eq "ARRAY" and $firstlen == @$_;
		}
	} elsif (ref $map eq "GD::Image") {
		$map = &_image2map($map);
	} else {
		croak "need a GD::Image or a two-dimensional array";
	}

	warn "GD::SIRDS::gd_sirds map made" if $main::GD_DEBUGGING;

	my $width = @$map;
	my $height = @{$map->[0]};

	# make the destination image
	my $image = &_make_image($width, $height, $colors);

	warn "GD::SIRDS::gd_sirds destination image made" if $main::GD_DEBUGGING;

	for (my $y = 0; $y < $height; $y++) { # convert scan lines independantly
		warn "GD::SIRDS::gd_sirds drawing line $y" if $main::GD_DEBUGGING;

		my @color; # color of this pixel
		my @same;  # a pixel to the right constrained to the same color

		for (my $x = 0; $x < $width; $x++) {
			$same[$x] = $x; # each pixel intially linked with itself
		}

		for (my $x = 0; $x < $width; $x++) {
			my $depth = $map->[$x][$y];
			# stereo separation at this ($x,$y) point
			my $sep = floor(((1-$dof*$depth)*$eye / (2-$dof*$depth))+0.5);

			# pixels corresponding to left & right eyes must
			#   be the same...
			my $left = floor($x - $sep/2);
			my $right = floor($left + $sep);

			# ...except for hidden-surface removal
			if (0 <= $left && $right < $width) {
				my $visible;
				my $t = 1;
				my $zt;

				do {
					$zt = $depth + 2*(2-$dof*$depth)*$t/($dof*$eye);
					$visible =  $map->[$x-$t][$y] < $zt
					         && $map->[$x+$t][$y] < $zt;
					++$t;
				} while ($visible && $zt < 1);
				if ($visible) {
					my $l = $same[$left];
					while ($l != $left && $l != $right) {
						if ($l < $right) {
							$left = $l;
							$l = $same[$left];
						} else {
							$same[$left] = $right;
							$left = $right;
							$l = $same[$left];
							$right = $l;
						}
					}
					$same[$left] = $right;
				}
			}
		}

		# assign colors to this row
		my $num_colors = @$colors;
		for (my $x = $width-1; $x >= 0; --$x) {
			if ($same[$x] == $x) {
				$color[$x] = int rand $num_colors;
			} else {
				$color[$x] = $color[$same[$x]];
			}
			$image->setPixel($x,$y,$color[$x]);
		}
	}

	warn "GD::SIRDS::gd_sirds stereogram generated" if $main::GD_DEBUGGING;

	if ($helper_circles) {
		for (1..10) {
			$image->arc($width/2-50, $height-10, $_, $_, 0, 360, 0);
			$image->arc($width/2+50, $height-10, $_, $_, 0, 360, 0);
		}
		warn "GD::SIRDS::gd_sirds helper dots placed" if $main::GD_DEBUGGING;
	}


	return $image;
}

#=============================================================================
#  Helper subs (not exported)
#-----------------------------------------------------------------------------
# Convert an image into a depth map.
# input:  a GD::Image
# output: a reference to a 2-dimensional array representing a depth map.
#   depths are between 0 and 1
sub _image2map
{
	my $image = shift;

	croak "not a GD::Image" unless ref $image eq "GD::Image";

	# find the luminance of each color in the image
	my @grey_table;
	for my $index (0 .. $image->colorsTotal-1) {
		$grey_table[$index] = &_luminance($image->rgb($index));
	}

	my ($width, $height) = $image->getBounds;

	my @map;
	for my $x (0 .. $width-1) {
		for my $y (0 .. $height-1) {
			$map[$x][$y] = $grey_table[$image->getPixel($x,$y)];
		}
	}

	return \@map;
}

# make an image, given sizes and colors
# input:  width, height, color arrayref
# output: a GD::Image
sub _make_image
{
	my $width = shift;
	my $height = shift;
	my $colors = shift;

	my $image = GD::Image->new($width, $height);

	foreach my $rgb (@$colors) {
		$image->colorAllocate(@$rgb);
	}

	return $image;
}

# return the luminance (0 <= luminance <= 1) of an RGB triple
#   (0 <= r|g|b <= 255).
# input:  r, g, b
# output: luminance
sub _luminance
{
	my ($r, $g, $b) = map {$_ / 255} @_;  # (0 <= x <= 255) -> (0 <= x <= 1)

	# from Carey Bunks, _Grokking the GIMP_ (New Riders, 200),
	#   Section 5.5, p. 152.  Also at http://gimp-savvy.com/BOOK/
	return $r * 0.3 + $g * 0.59 + $b * 0.11;
}

'Woopa woopa woo chuck chuck!';

=back

=head1 BUGS

In some cases, GD seems to posterize (reduce the color depth) of images
when it reads them.  I don't yet know when this happens.  When it does
happen, a marked stair-step effect will occur in the generated stereogram.

=head1 AUTHOR

David "Cogent" Hand, E<lt>cogent@cpan.orgE<gt>.

Copyright (c) 2002.  All rights reserved.  This module is free software;
you may restribute and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<GD(3)>.

Thimbleby, H.W., Inglis, S., and Witten, I.H.
"Displaying 3D images: algorithms for single-image random-dot stereograms"
IEEE Computer, 27 (10) 38-48, October 1994.

N.E. Thing Enterprises, I<Magic Eye Gallery>.  Andrews McMeel Publishing, 1995.

=cut

__END__
