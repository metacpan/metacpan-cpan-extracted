# $Id: Match.pm,v 1.4 2008/09/02 10:34:44 dk Exp $
package Image::Match;

use strict;
use warnings;
use Prima::noX11;
use Prima;
require Exporter;

our $VERSION = '1.02';
our $Y_GROWS_UPWARDS = 0;
our $DEBUG = 0;

sub match
{
        my ( $image, $subimage, %options) = @_;

	local $Y_GROWS_UPWARDS = $Y_GROWS_UPWARDS;
	mode($options{mode}) if exists $options{mode};

	$options{overlap} ||= 'some';
	die "Bad overlap mode '$options{overlap}': must be one of: none, some, all\n"
		unless $options{overlap} =~ /^(some|all|none)$/;
	my $overlap_all = $options{overlap} eq 'all';

        my $G   = $image-> data;
        my $W   = $image-> width;
        my $H   = $image-> height;
        my $w   = $subimage-> width;
        my $h   = $subimage-> height;
        my $bpp = ($image-> type & im::BPP) / 8;
	print STDERR 
		"match image ($w x $h x ",
		$subimage-> type & im::BPP, ") in ", 
		"($W x $H x ", 
		$image-> type & im::BPP, ") ", 
		"length ", length($G), "\n"
		if $DEBUG;

	# Requirements: need same bpp and same colormap.
	# Also, 1 and 4 bit images aren't supported, autoconvert
	if ( $bpp <= 1) {
		my $cm1 = join(',', $image->    colormap);
		my $cm2 = join(',', $subimage-> colormap);
		if ( $cm1 eq $cm2) {
			# good, palettes are equal. now, are types equal?
			if ( $subimage-> type != $image-> type) {
				$subimage-> type( $image-> type);
				printf STDERR ("subimage converted to type=%x\n", $image->type) if $DEBUG;
			}
		} else {
			# force convert to 24bits
			$image-> type(24);
			$subimage-> type(24);
			print STDERR "both images converted to 24 bpp\n" if $DEBUG;
		}
	}

        my $I   = $subimage-> data;
        my $gw  = int(( $W * ( $image->    type & im::BPP) + 31) / 32) * 4;
        my $iw  = int(( $w * ( $subimage-> type & im::BPP) + 31) / 32) * 4;
        my $ibw = $w * $bpp;
        my $dw  = $gw - $ibw;
	print "global=$gw, local=$iw, max=$ibw diff=$dw\n" if $DEBUG;
        
        my $rx  = join( ".{$dw}", map { quotemeta substr( $I, $_ * $iw, $ibw) } 
                (0 .. $subimage-> height - 1));
        my ( $x, $y);
	my @ret;

	pos($G) = 0;
  	study $G;
	while ( 1) {
		if ( $DEBUG) {
			my $ap = pos($G);
			my $ax = $ap % $gw / $bpp;
			my $ay = int(($ap - ($ax + $w) * $bpp) / $gw);
			$ay = $H - $ay - 1 if $Y_GROWS_UPWARDS;
			print STDERR 
				"begin match at $ap = $ax $ay, ",
				length($G) - $ap, " bytes left\n";
		}

		# match
	        unless ( $G =~ m/\G.*?$rx/gcs) {
			print STDERR "-> negative\n" if $DEBUG;
			return unless $options{multiple};
			last;
		}
		my $p = pos($G);
		$x = ($p - $w * $bpp) % $gw / $bpp;
		$y = int(($p - ( $x + $w) * $bpp) / $gw) + 1;
		$y = $y - $h;
		$y = $H - $h - $y unless $Y_GROWS_UPWARDS;
		print STDERR "-> positive at $p = $x $y\n" if $DEBUG;

		if ( $x + $w > $W) {
			print STDERR "-> scanline wrap, skipping\n" if $DEBUG;
			next;
		}
		pos($G) -= ($h - 1) * $gw;
		pos($G) -= $ibw - $bpp if $overlap_all;

		# store results
		push @ret, $x, $y;
		return $x, $y unless $options{multiple};
	}

	# filter output
	if ( $options{overlap} eq 'none') {
		my @r;
		my @ranges; # for each scanline store list of occupied pixels as x1-x2 ranges
		print STDERR "removing overlapped rectangles\n" if $DEBUG;
		RECT: for ( my $i = 0; $i < @ret; $i+=2) {
			my ( $x1, $y1) = @ret[$i, $i+1];
			my ( $x2, $y2) = ( $x1 + $w, $y1 + $h);
			print STDERR "checking ($x1,$y1)-($x2,$y2)\n" if $DEBUG;
			for ( my $y = $y1; $y < $y2; $y++) {
				$ranges[$y] ||= [];
				for my $xranges ( @{ $ranges[$y] }) {
					next if 
						$x1 >= $xranges->[1] or
						$x2 <  $xranges->[0];
					print STDERR "-> overlaps, skipping\n" if $DEBUG;
					next RECT;
				}

				# does not overlap, register
				push @{ $ranges[$y] }, [ $x1, $x2 ];
			}
			push @r, $x1, $y1;
		}
		@ret = @r;
	}

	print STDERR "return: [@ret]\n" if $DEBUG;
	return @ret;
}

sub screenshot
{
	shift if defined($_[0]) and ( ref($_[0]) or ($_[0] =~ /Image/) );

	unless ( $::application) {
		my $error = Prima::XOpenDisplay();
		die $error if defined $error;
		require Prima::Application;
		import Prima::Application;
	}

	my ( $x, $y, $w, $h) = @_;
	my @as = $::application-> size;

	$x ||= 0;
	$y ||= 0;
	$w = $as[0] unless defined $w;
	$h = $as[1] unless defined $h;

	$y = $as[1] - $h - $y unless $Y_GROWS_UPWARDS;

	return $::application-> get_image( $x, $y, $w, $h);
}

sub mode
{
	shift if defined($_[0]) and ( ref($_[0]) or ($_[0] =~ /Image/) );
	return $Y_GROWS_UPWARDS ? 'geom' : 'screen' unless @_;
	die "bad Image::Match::mode: must be 'geom' or 'screen'\n"
		unless $_[0] =~ /^(geom|screen)$/;
	$Y_GROWS_UPWARDS = $_[0] eq 'geom';
}

*Prima::Image::match = \&match;
*Prima::Image::screenshot = \&screenshot;

1;

=pod

=head1 NAME

Image::Match - locate an image inside another

=head1 DESCRIPTION

The module searches for occurencies of an image inside of a larger image.

The interesting stuff here is the image finding itself - it is done by a regex!
For all practical reasons, regexes operate on strings of bytes, and images can
be easily treated as such. For example, one needs to locate an image 2x2 in a
larger 7x7 image. The constructed regex should contain the first scanline of
the smaller image, 2 bytes, verbatim, then match 7 - 2 = 5 of any byte found,
and finally the second scanline, 2 bytes again. Of course there are some
quirks, but these explained in the API section.

The original idea was implemented in L<OCR::Naive> and L<Win32::GUIRobot>, but
this module extracts the pure matching logic, unburdened from wrappers that
were needed back then for matters at hand.

=head1 SYNOPSIS

  use strict;
  use Image::Match;

  # make screenshot
  my $big = Image::Match-> screenshot;
  # extract 70x70 image
  my $small = $big-> extract( 230, $big-> height - 70 - 230, 70, 70);
  # save
  $small-> save('1.png');
  # load
  $small = Prima::Image-> load('1.png') or die "Can't load: $@";
  # find again
  my ( $x, $y) = $big-> match( $small);
  print defined($x) ? "found at $x:$y\n" : "not found\n";

=head1 API

=over

=item match $IMAGE, $SUBIMAGE, %OPTIONS

Locates a $SUBIMAGE in $IMAGE, returns one or many matches, depending on
C<$OPTIONS{multiple}>.  If single match is requested, stops on the first match,
and returns a single pair of (X,Y) coordinates. If C<$OPTIONS{multiple}> is 1,
returns array of (X,Y) pairs. In both modes, returns empty list if nothing was
found.

C<$OPTIONS{mode}> overrides global C<mode()>.

C<$OPTIONS{overlap}> can be set to one of three values: I<none>, I<some>,
I<all>, to determine how the overlapping matches are reported when
C<$OPTIONS{multiple}> is set.  I<None> will never report overlapping rectanges,
and I<all> report all possible occurencies of C<$SUBIMAGE> in C<$IMAGE>.
I<some> is similar to I<all>, but is a bit faster, and will not report
overlapping rectangles that begin on the same scanline. I<some> is also the
default overlapping mode.

=item screenshot [ $X = 0, $Y = 0, $W = screen width, $H = screen height ]

Returns a new C<Prima::Image> object with a screen shot, taken at
given coordinates.

=item mode $MODE = 'screen'

The module uses L<Prima> for imaging storage and manipulations. Note that Prima
uses coordinate system where Y axis grows upwards. This module however can use
both geometrical (Y grows upwards, C<mode('geom')>) and screen-based (Y grows
downwards, C<mode('screen')>) modes. The latter mode is the default.

=back

=head1 NOTES

On unix, C<Prima> by default will start X11. The module changes that behavior,
so X11 connection is not needed. If your code though needs X11 connection, 
change that by adding

   use Prima;

before invoking

   use Image::Match

See L<Prima::X11> for more information.

If you need to use other image backends than Prima, that can be done too.
There is L<Prima::Image::Magick> that brings together Prima and ImageMagick,
and there is L<Prima::Image::PDL>, that does the same for PDL. GD, Imglib2, and
Imager, those we can't deal much with, except for saving to and loading from png
files.

=head1 SEE ALSO

L<Prima::Image>, L<OCR::Naive>, L<Win32::GUIRobot>

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=cut
