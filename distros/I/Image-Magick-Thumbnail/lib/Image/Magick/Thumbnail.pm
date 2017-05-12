package Image::Magick::Thumbnail;

use strict;
use warnings;
our $VERSION = '0.06';

use Carp;

=head1 NAME

Image::Magick::Thumbnail - Produces thumbnail images with ImageMagick

=head1 SYNOPSIS

	use Image::Magick::Thumbnail 0.06;
	# Load the source image
	my $src = Image::Magick->new;
	$src->Read('source.jpg');

	# Create the thumbnail from it, where the biggest side is 50 px
	my ($thumb, $x, $y) = Image::Magick::Thumbnail::create($src, 50);

	# Save your thumbnail
	$thumb->Write('source_thumb.jpg');

	# Create another thumb, that fits into the geometry
	my ($thumb2, $x2, $y2) = Image::Magick::Thumbnail::create($src, '60x50');

	# Create yet another thumb, fitting partial geometry
	my ($thumb3, $x3, $y3) = Image::Magick::Thumbnail::create($src, 'x50');

	__END__

=head1 DESCRIPTION

This module uses the ImageMagick library to create a thumbnail image with no side bigger than you specify.

There is no OO API, since that would seem to be over-kill. There's just C<create>.

=head2 SUBROUTINE create

	my ($im_obj, $x, $y) = Image::Magick::Thumbnail->create( $src, $maxsize_or_geometry);

It takes two arguments: the first is an ImageMagick image object,
the second is either the size in pixels you wish the longest side of the image to be,
or an C<Image::Magick>-style 'geometry' (eg C<100x120>) which the thumbnail must fit.
Missing part of the geometry is fine.

Returns an C<Imaeg::Magick> image object (the thumbnail), as well as the
number of pixels of the I<width> and I<height> of the image, as integer scalars,
and (mainly for testing) the ration used in the scaling.

=head2 WARNINGS

Will warn on bad or missing arguments if you have C<use>d C<warnings>.

=head2 PREREQUISITES

	Image::Magick

=head2 EXPORTS

None by default.

=head1 SEE ALSO

L<perl>, L<Image::Magick>, L<Image::GD::Thumbnail>,
and L<Image::Thumbnail> for the same formula for various engines.

=head1 AUTHOR

Lee Goddard <LGoddard@CPAN.org>

=head2 COPYRIGT

Copyright (C) Lee Godadrd 2001-2008. all rights reserved.
Available under the same terms as Perl itself.

=cut

use Image::Magick;
use Carp;
#use warnings::register;

sub create($$;$) {
	my ($img, $max) = (shift, shift);

	if (not $img){
        if (warnings::enabled()) {
			Carp::cluck "No image";
		}
		return undef;
	}

	if (not ref $img or ref $img ne 'Image::Magick'){
        if (warnings::enabled()) {
			Carp::cluck "Not an Image::Magick object";
		}
		return undef;
	}

	if (not $max){
        if (warnings::enabled()) {
			Carp::cluck "No size or geometry";
		}
		return undef;
	}

	my ($ox, $oy) = $img->Get('width', 'height');
	if (not $ox and not $oy){
        if (warnings::enabled()) {
			Carp::cluck "Could not get image size";
		}
		return undef;
	}

	# Version 0.05 behaviour
	# From geo, get the longest side of the box into which to fit:
	# my ($maxx, $maxy);
	# if (($maxx, $maxy) = $max =~ /^(\d+)x(\d+)$/i){
	# 	$max = ($ox>$oy)? $maxx : $maxy;
	# } else {
	# 	$maxx = $maxy = $max;
	# }
	#	$r = ($ox/$maxx) > ($oy/$maxy) ? ($ox/$maxx) : ($oy/$maxy);

	# foreach my $max (qw( 10x40 10x x40 40)){

	my $r;
	if ($max =~ /^\s*(\d+)?\s*(x)?\s*(\d+)?\s*$/i){
		# warn sprintf( "%s   %s   %s", ($1||"?"), ($2||"?"), ($3||"?") );
		if ($1 and $3){
			# warn sprintf "Got both:  %s   %s", ($ox/$1), ($oy/$3);
			$r = ($ox/$1) > ($oy/$3) ? ($ox/$1) : ($oy/$3);
		}
		elsif (not $1 or not $3){
			if (not $2){
				# warn "Got one ($max)";
				$r = ($ox/$max) > ($oy/$max) ? ($ox/$max) : ($oy/$max);
			} else {
				# warn "Got one or other";
				$r = ($1) ? ($ox/$1) : ($oy/$3);
			}
		}
		# warn $r==10;
	}

	else {
        if (warnings::enabled()) {
			warn __PACKAGE__."::create expected a second argument of a single positive integer, a valid geometry, or a one-side geometry: please see the POD.";
		}
		return undef;
	}

	my ($x, $y) = (int($ox/$r), int($oy/$r));

	$img->Thumbnail(
		width  => $x,
		height => $y
	);

	return ($img, $x, $y, $r);
}


1;

__END__

