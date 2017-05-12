package Graphics::ColorObject;

# Copyright 2003-2005 by Alex Izvorski

# Portions Copyright 2001-2003 by Alfred Reibenschuh

# $Id: ColorObject.pm,v 1.12 2005/07/19 10:11:47 ai Exp $

=head1 NAME

Graphics::ColorObject - convert between color spaces


=head1 SYNOPSIS

  use Graphics::ColorObject;
  
  # rgb to hsv
  $color = Graphics::ColorObject->new_RGB([$r, $g, $b]);
  ($h, $s, $v) = @{ $color->as_HSV() };
  
  # one rgb space to another (NTSC to PAL)
  $color = Graphics::ColorObject->new_RGB([$r, $g, $b], space=>'NTSC');
  ($r, $g, $b) = @{ $color->as_RGB(space=>'PAL') };


=head1 ABSTRACT

Use this module to convert between all the common color spaces.  As a pure Perl module, it is not very fast, and so it you want to convert entire images quickly, this is probably not what you want.  The emphasis is on completeness and accurate conversion.

Supported color spaces are: RGB (including sRGB, Apple, Adobe, CIE Rec 601, CIE Rec 709, CIE ITU, and about a dozen other RGB spaces), CMY, CMYK, HSL, HSV, XYZ, xyY, Lab, LCHab, Luv, LCHuv, YPbPr, YCbCr, YUV, YIQ, PhotoYCC.

Conversion between different RGB working spaces, and between different white-points, is fully supported.


=head1 DESCRIPTION

For any supported color space XXX, there is one constructor new_XXX that creates a color using data in that color space, and one method as_XXX that returns the current color as expressed in that color space.  For example, for RGB there is new_RGB and as_RGB.  The color data is always passed as an array reference to a three-element array (four-element in the case of CMYK).  Thus, to convert from RGB to HSL, you can use:

  $color = Graphics::ColorObject->new_RGB([$r, $g, $b]);
  ($h, $s, $l) = @{ $color->as_HSL() };

The constructor can always take a hash of optional arguments in addition to the color value, namely the working RGB space and the white point.  For example:

  $color = Graphics::ColorObject->new_RGB([$r, $g, $b], space=>'Adobe', white_point=>'D65');

For a list of all supported color spaces, call Graphics::ColorObject->list_colorspaces().  For a list of all RGB working spaces and of all white points that this module supports, call Graphics::ColorObject->list_rgb_spaces() and Graphics::ColorObject->list_white_points().

If not specified, the working RGB space will be sRGB.  Many non-RGB conversions also rely on an implicit RGB space, and passing an RGB space as an option (either to the constructor or later) will have an effect on the values.


=head1 VARIOUS NOTES AND GOTCHAS

Most conversions will return out-of-gamut values if necessary, because that way they are lossless and can be chained in calculations, or reversed to produce the original values.  Many conversion methods will take an optional boolean "clip" parameter to restrict the returned values to be within gamut:

  ($r, $g, $b) = @{ $color->as_RGB(space=>'sRGB', clip=>1) };

Currently clipping is supported in RGB, RGB-derived (HSL, CMY) and chroma-luma separated (YUV, etc) spaces, but not in XYZ-derived spaces.  The only way to check whether a value is within gamut is to convert it with and without the clip option and compare the two results.  An RGB value is within gamut simply if R, G and B are between 0 and 1, but other spaces can be much harder to check.

RGB values are non-linear (gamma-adjusted) floating-point values scaled in the range from 0 to 1.  If you want integer values in the range 0..255, use the new_RGB255/as_RGB255 functions instead.  If you want linear RGB (not gamma-adjusted) use RGB_to_linear_RGB([$r, $g, $b]).

Functions that use an angle value always express it in degrees from 0 to 360.  That includes the hue H in HSL, HSV, LCHab and LCHuv.  Use rad2deg and deg2rad from Math::Trig to convert to/from degrees if necessary.

There is some confusion in the naming of YUV and related (Y-something-something) colorspaces.  Most of the time when "YUV" or "YCC" is used in software, for example in JPEG and MPEG2, that is actually YCbCr, a chroma-luma separated space with integer values of Y in the range [16..235], Cb and Cr in [16..240].  JPEG uses a modified YCbCr with values in [0..255] (which is not implemented in this module).  As used here, YUV is a floating-point representation of the analog signal in PAL TV, YIQ is the same for NTSC TV, YPbPr is component analog video, and PhotoYCC or YCC is the Kodak PhotoCD standard.

The set_white_point() function can take arbitrary temperatures as well as the predefined standard illuminants.  The valid range of temperatures is from 4000K to 25000K.


=head1 RECOMMENDATIONS

Aside from converting from one space to another, what colorspace is the best one to use for a particular task?  This section attempts to answer that question.

For "generic" RGB values, use sRGB (which is the default).

For 2D effects filters, use Lab (or LCHab).

For adjustment of brightness, saturation and hue, use LCHab or LSHab.

For compression, use YCbCr, or use YPbPr and convert to integer values in a way that makes sense in your application.

For representing data as colors, use Lab (straight lines between points in Lab are more-or-less uniform gradients, unlike straight lines in RGB, for example).


=head1 UPGRADING FROM 0.3a2 AND OLDER VERSIONS

Version 0.4 and later are a complete rewrite from the previous major version, 0.3a2. The API is completely changed.  The old API should be emulated exactly in all cases.  Please test any code that uses this module when upgrading. If you encounter any strange behavior, please downgrade to 0.3a2 and email me a bug report.  Additionally, the exact values returned by some functions may be slightly different, this is not a bug - the new values are (more) correct.  


=head1 METHODS

=cut 

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
    RGB_to_RGB255
    RGB255_to_RGB
    RGBhex_to_RGB
    RGB_to_RGBhex
    RGB_to_XYZ
    XYZ_to_RGB
    XYZ_to_Lab
    Lab_to_XYZ
    RGB_to_Lab
    Lab_to_RGB
    XYZ_to_Luv
    Luv_to_XYZ
    Luv_to_LCHuv
    LCHuv_to_Luv
    XYZ_to_xyY
    xyY_to_XYZ
    Lab_to_LCHab
    LCHab_to_Lab
    RGB_to_linear_RGB
    linear_RGB_to_RGB
    RGB_to_YPbPr
    YPbPr_to_RGB
    RGB_to_HSV
    HSV_to_RGB
    RGB_to_HSL
    HSL_to_RGB	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.5.0';

use Carp;
use POSIX qw(pow);
use Math::Trig;

############ OO interface ##############

use vars qw(%RGB_SPACES %WHITE_POINTS %COLORNAMES);

sub new
{
	my ($pkgname, @opts) = @_;

	my $this = +{};
	bless $this, $pkgname;
	my $col = &Graphics::ColorObject::namecolor($opts[0]);
	if ($col)
	{
		shift(@opts);
		$this = new_RGB($pkgname, $col, @opts);
		return $this;
	}
	
	# check before converting to hash, even if the extra args are bogus at least it won't generate an error
	if (scalar(@opts) % 2 == 0)
	{
		my %opts = @opts;
		$this->{space} = $opts{space};
		$this->{white_point} = $opts{white_point};
	}

	return $this;
}

=head2 $color = Graphics::ColorObject->new_XYZ([$X, $Y, $Z])
=cut 

sub new_XYZ
{
	my ($pkgname, $xyz, %opts) = @_;
	my $this = &new($pkgname, %opts);
	$this->{xyz} = $xyz;
	return $this;
}

=head2 $color = Graphics::ColorObject->new_xyY([$x, $y, $Y])
=cut 

sub new_xyY
{
	my ($pkgname, $xyy, %opts) = @_;
	my $this = &new($pkgname, %opts);
	$this->{xyz} = &xyY_to_XYZ($xyy);
	return $this;
}

=head2 $color = Graphics::ColorObject->new_RGB([$R, $G, $B])
=cut 

sub new_RGB
{
	my ($pkgname, $rgb, %opts) = @_;
	my $this = &new($pkgname, %opts);
	$this->{xyz} = &RGB_to_XYZ($rgb, $this->{space});
	return $this;
}

=head2 $color = Graphics::ColorObject->new_RGB255([$R, $G, $B])
=cut 

sub new_RGB255
{
	my ($pkgname, $rgb255, %opts) = @_;
	return &new_RGB($pkgname, &RGB255_to_RGB($rgb255), %opts);
}

=head2 $color = Graphics::ColorObject->new_RGBhex($rgbhex)
=cut 

sub new_RGBhex
{
	my ($pkgname, $rgbhex, %opts) = @_;
	return &new_RGB($pkgname, &RGBhex_to_RGB($rgbhex), %opts);
}

=head2 $color = Graphics::ColorObject->new_Lab([$L, $a, $b])
=cut 

sub new_Lab
{
	my ($pkgname, $lab, %opts) = @_;
	my $this = &new($pkgname, %opts);
	$this->{xyz} = &Lab_to_XYZ($lab, $this->get_XYZ_white());
	return $this;
}

=head2 $color = Graphics::ColorObject->new_LCHab([$L, $C, $H])
=cut 

sub new_LCHab
{
	my ($pkgname, $lch, %opts) = @_;
	my $this = &new($pkgname, %opts);
	$this->{xyz} = &Lab_to_XYZ(&LCHab_to_Lab($lch), $this->get_XYZ_white());
	return $this;
}

=head2 $color = Graphics::ColorObject->new_Luv([$L, $u, $v])
=cut 

sub new_Luv
{
	my ($pkgname, $luv, %opts) = @_;
	my $this = &new($pkgname, %opts);
	$this->{xyz} = &Luv_to_XYZ($luv, $this->get_XYZ_white());
	return $this;
}

=head2 $color = Graphics::ColorObject->new_LCHuv([$L, $C, $H])
=cut 

sub new_LCHuv
{
	my ($pkgname, $lch, %opts) = @_;
	my $this = &new($pkgname, %opts);
	$this->{xyz} = &Luv_to_XYZ(&LCHuv_to_Luv($lch), $this->get_XYZ_white());
	return $this;
}

=head2 $color = Graphics::ColorObject->new_HSL([$H, $S, $L])
=cut 

sub new_HSL
{
	my ($pkgname, $hsl, %opts) = @_;
	return &new_RGB($pkgname, &HSL_to_RGB($hsl), %opts);
}

=head2 $color = Graphics::ColorObject->new_HSV([$H, $S, $V])
=cut 

sub new_HSV
{
	my ($pkgname, $hsv, %opts) = @_;
	return &new_RGB($pkgname, &HSV_to_RGB($hsv), %opts);
}

=head2 $color = Graphics::ColorObject->new_CMY([$C, $M, $Y])
=cut 

sub new_CMY
{
	my ($pkgname, $cmy, %opts) = @_;
	return &new_RGB($pkgname, &CMY_to_RGB($cmy), %opts);
}

=head2 $color = Graphics::ColorObject->new_CMYK([$C, $M, $Y])
=cut 

sub new_CMYK
{
	my ($pkgname, $cmyk, %opts) = @_;
	return &new_RGB($pkgname, &CMY_to_RGB(&CMYK_to_CMY($cmyk)), %opts);
}

=head2 $color = Graphics::ColorObject->new_YPbPr([$Y, $Pb, $Pr])
=cut 

sub new_YPbPr
{
	my ($pkgname, $ypbpr, %opts) = @_;
	return &new_RGB($pkgname, &YPbPr_to_RGB($ypbpr), space => 'NTSC'); # force NTSC
}

=head2 $color = Graphics::ColorObject->new_YCbCr([$Y, $Cb, $Cr])
=cut 

sub new_YCbCr
{
	my ($pkgname, $ycbcr, %opts) = @_;
	return &new_RGB($pkgname, &YCbCr_to_RGB($ycbcr), space => 'NTSC'); # force NTSC
}

=head2 $color = Graphics::ColorObject->new_YUV([$Y, $Cb, $Cr])
=cut 

sub new_YUV
{
	my ($pkgname, $yuv, %opts) = @_;
	return &new_RGB($pkgname, &YUV_to_RGB($yuv), space => 'NTSC'); # force NTSC
}

=head2 $color = Graphics::ColorObject->new_YIQ([$Y, $I, $Q])
=cut 

sub new_YIQ
{
	my ($pkgname, $yiq, %opts) = @_;
	return &new_RGB($pkgname, &YIQ_to_RGB($yiq), space => 'NTSC'); # force NTSC
}

=head2 $color = Graphics::ColorObject->new_PhotoYCC([$Y, $C1, $C2])
=cut 

sub new_PhotoYCC
{
	my ($pkgname, $ycc, %opts) = @_;
	return &new_RGB($pkgname, &PhotoYCC_to_RGB($ycc), space => 'sRGB'); # force sRGB
}

=head2 ($X, $Y, $Z) = @{ $color->as_XYZ() }
=cut 

sub as_XYZ
{
	my ($this, %opts) = @_;
	my $xyz = $this->{xyz};
	if ($opts{clip})
	{
		# TODO check this is correct
		my ($Xw, $Yw, $Zw) = @{ $this->get_XYZ_white() };
		$xyz = &_generic_clip($xyz, [[0,$Xw], [0,$Yw], [0,$Zw]]);
	}
	return $xyz;
}

=head2 ($R, $G, $B) = @{ $color->as_RGB() }
=cut 

sub as_RGB
{
	my ($this, %opts) = @_;
	my $space = $opts{space} || $this->{space};
	my $rgb = &XYZ_to_RGB($this->{xyz}, $space);
	if ($opts{clip}) { $rgb = &_generic_clip($rgb, [[0,1], [0,1], [0,1]]); };
	return $rgb;
}

=head2 ($R, $G, $B) = @{ $color->as_RGB255() }
=cut 

sub as_RGB255
{
	my ($this) = @_;
	# always clipped
	return &RGB_to_RGB255($this->as_RGB());
}

=head2 $hex = $color->as_RGBhex()
=cut 

sub as_RGBhex
{
	my ($this) = @_;
	# always clipped
	return &RGB_to_RGBhex($this->as_RGB());
}

=head2 ($x, $y, $Y) = @{ $color->as_xyY() }
=cut 

sub as_xyY
{
	my ($this, %opts) = @_;
	my $xyy = &XYZ_to_xyY($this->{xyz}, $this->get_XYZ_white());
	return $xyy;
}

=head2 ($L, $a, $b) = @{ $color->as_Lab() }
=cut 

sub as_Lab
{
	my ($this) = @_;
	my $lab = &XYZ_to_Lab($this->{xyz}, $this->get_XYZ_white());
	return $lab;
}

=head2 ($L, $C, $H) = @{ $color->as_LCHab() }
=cut 

sub as_LCHab
{
	my ($this) = @_;
	my $lchab = &Lab_to_LCHab( &XYZ_to_Lab($this->{xyz}, $this->get_XYZ_white()) );
	return $lchab;
}

=head2 ($L, $u, $v) = @{ $color->as_Luv() }
=cut 

sub as_Luv
{
	my ($this) = @_;
	my $luv = &XYZ_to_Luv($this->{xyz}, $this->get_XYZ_white());
	return $luv;
}

=head2 ($L, $C, $H) = @{ $color->as_LCHuv() }
=cut 

sub as_LCHuv
{
	my ($this) = @_;
	my $lchuv = &Luv_to_LCHuv( &XYZ_to_Luv($this->{xyz}, $this->get_XYZ_white()) );
	return $lchuv;
}

=head2 ($H, $S, $L) = @{ $color->as_HSL() }
=cut 

sub as_HSL
{
	my ($this, %opts) = @_;
	my $hsl = &RGB_to_HSL( $this->as_RGB() );
	if ($opts{clip}) { $hsl = &_generic_clip($hsl, [[0,360], [0,1], [0,1]]); };
	return $hsl;
}

=head2 ($H, $S, $V) = @{ $color->as_HSV() }
=cut 

sub as_HSV
{
	my ($this, %opts) = @_;
	my $hsv = &RGB_to_HSV( $this->as_RGB() );
	if ($opts{clip}) { $hsv = &_generic_clip($hsv, [[0,360], [0,1], [0,1]]); };
	return $hsv;
}

=head2 ($C, $M, $Y) = @{ $color->as_CMY() }
=cut 

sub as_CMY
{
	my ($this, %opts) = @_;
	my $cmy = &RGB_to_CMY( $this->as_RGB() );
	if ($opts{clip}) { $cmy = &_generic_clip($cmy, [[0,1], [0,1], [0,1]]); };
	return $cmy;
}

=head2 ($C, $M, $Y, $K) = @{ $color->as_CMYK() }
=cut 

sub as_CMYK
{
	my ($this) = @_;
	my $cmyk = &CMY_to_CMYK( &RGB_to_CMY( $this->as_RGB() ) );
	# TODO clip
	return $cmyk;
}

=head2 ($Y, $Pb, $Pr) = @{ $color->as_YPbPr() }
=cut 

sub as_YPbPr
{
	my ($this, %opts) = @_;
	my $ypbpr = &RGB_to_YPbPr( $this->as_RGB( space => 'NTSC' ) );
	if ($opts{clip}) { $ypbpr = &_generic_clip($ypbpr, [[0,1], [-0.5,0.5], [-0.5,0.5]]); };
	return $ypbpr;
}

=head2 ($Y, $Cb, $Cr) = @{ $color->as_YCbCr() }
=cut 

sub as_YCbCr
{
	my ($this, %opts) = @_;
	my $ycbcr = &RGB_to_YCbCr( $this->as_RGB( space => 'NTSC' ) );
	if ($opts{clip}) { $ycbcr = &_generic_clip($ycbcr, [[16,235], [16,239], [16,239]]); };
	# TODO round to integers
	return $ycbcr;
}

=head2 ($Y, $U, $V) = @{ $color->as_YUV() }
=cut 

sub as_YUV
{
	my ($this) = @_;
	my $yuv = &RGB_to_YUV( $this->as_RGB( space => 'NTSC' ) );
	return $yuv;
}

=head2 ($Y, $I, $Q) = @{ $color->as_YIQ() }
=cut 

sub as_YIQ
{
	my ($this) = @_;
	my $yiq = &RGB_to_YIQ( $this->as_RGB( space => 'NTSC' ) );
	return $yiq;
}

=head2 ($Y, $C1, $C2) = @{ $color->as_PhotoYCC() }
=cut 

sub as_PhotoYCC
{
	my ($this) = @_;
	my $ycc = &RGB_to_PhotoYCC( $this->as_RGB( space => 'sRGB' ) );
	return $ycc;
}

# returns the XYZ value of the white point actually used (always defined, default is D65)
sub get_XYZ_white
{
	my ($this, %opts) = @_;
	my $white_point = $opts{white_point} || $this->{white_point} || 
		&_get_RGB_space_by_name( $opts{space} || $this->{space} )->{white_point};

	$white_point = &_check_white_point($white_point);

	my $xy = $WHITE_POINTS{ $white_point };

	my ($x, $y) = @{ $xy };
	return &xyY_to_XYZ([$x, $y, 1.0]);
	#return &RGB_to_XYZ([1, 1, 1], $this->{space});
}

=head2 $white_point = $color->get_white_point()
Returns the name of the current white point.  Value is one of the entries returned from list_white_points, such as "D65", or a color temperature.
=cut 

# returns the name of the white point actually used
# FIXME should be always defined
sub get_white_point
{
	my ($this) = @_;
	return $this->{white_point};
}

=head2  $color->set_white_point("D65")
Sets the current white point by name.  Argument is one of the entries returned from list_white_points, or a temperature value like "6800K".  This changes the current color slightly since white-point adaptation is not completely reversible.  This does not affect the current RGB space, thus it is possible to use RGB spaces at whitepoints other than those they were defined at.
=cut 

sub set_white_point
{
	my ($this, $white_point) = @_;

	$white_point = &_check_white_point($white_point);

	if (&_check_white_point($this->{white_point}) ne $white_point)
	{
		$this->{xyz} = &XYZ_change_white_point($this->{xyz}, $this->get_XYZ_white(), $this->get_XYZ_white($white_point));
		$this->{white_point} = $white_point;
	}

	return $this;
}

=head2 $rgb_space = $color->get_rgb_space()
Returns the name of the current RGB color space.  Value is one of the entries returned from list_rgb_spaces, such as "NTSC".
=cut 

# FIXME should be always defined
sub get_rgb_space
{
	my ($this) = @_;
	return $this->{space};
}

=head2  $color->set_rgb_space("NTSC")
Sets the current RGB color space by name.  Argument is one of the entries returned from list_rgb_spaces.  This may change the current color if the old and new spaces have different white points.
=cut 

sub set_rgb_space
{
	my ($this, $space) = @_;
	my $s = &_get_RGB_space_by_name($space);
	if ($this->get_white_point() ne $s->{white_point})
	{
		$this->set_white_point($s->{white_point});
	}
	$this->{space} = $space;
	return $this;
}

=head2  $color2 = $color->copy()
Creates an exact duplicate of the current color.
=cut 

sub copy
{
	my ($this) = @_;
	my $copy = +{ 
		xyz => $this->{xyz},
		space => $this->{space},
		white_point => $this->{white_point}
	};
	bless $copy, ref $this;
	return $copy;
}


=head2  if ($color->equals($color2)) { ... }
Checks if another color is the same as this one.  Optionally takes an accuracy parameter which is the distance between the two colors as measured by the city-block metric in XYZ space (default accuracy is 0.01%).
=cut 

sub equals
{
	my ($this, $other, %opts) = @_;
	$other = $other->copy();
	$other->set_white_point($this->{white_point});
	$other->set_rgb_space($this->{space});
	my $accuracy = $opts{accuracy} || 0.0001;
	if (&_delta_v3($this->{xyz}, $other->{xyz}) < $accuracy) { return 1; }
	else { return 0; }
}

=head2  $d = $color->difference($color2)
Calculates the difference between this color and another one.  The difference measure is (approximately) perceptually uniform.
=cut 

sub difference
{
	my ($this, $other) = @_;
	return $this->difference_CIE1976($other);
}

# reference: http://www.brucelindbloom.com/index.html?Eqn_DeltaE_CIE76.html
sub difference_CIE1976
{
	my ($this, $other) = @_;
	
	my ($L1, $a1, $b1) = @{ $this->as_Lab() };
	my ($L2, $a2, $b2) = @{ $other->as_Lab() };
	
	my $deltaE = sqrt(&_sqr($L1-$L2) + &_sqr($a1-$a2) + &_sqr($b1-$b2));
	
	return $deltaE;
}

sub difference_CIE1994
{
	# TODO
}

# reference: http://www.brucelindbloom.com/index.html?Eqn_DeltaE_CMC.html
sub difference_CMC
{
	my ($this, $other, %opts) = @_;

	my $l = $opts{l} || 1;
	my $c = $opts{c} || 1;
	
	my ($L1, $a1, $b1) = @{ $this->as_Lab() };
	my ($L2, $a2, $b2) = @{ $other->as_Lab() };

	my $C1 = sqrt($a1*$a1 + $b1*$b1);
	my $C2 = sqrt($a2*$a2 + $b2*$b2);

	my $dH = sqrt(&_sqr($a1-$a2) + &_sqr($b1-$b2) - &_sqr($C1-$C2));

	my $SL = ($L1 < 16 ? 
			  0.511 : 
			  0.040975 * $L1 / ( 1 + 0.01765 * $L1)
			  );

	my $SC = 0.638 + 0.0638 * $C1 / ( 1 + 0.0131 * $C1 );

	my $F = sqrt(pow($C1, 4) / ( pow($C1, 4) + 1900 ));

	my $H1 = atan2($b1, $a1);

	my $T = ((deg2rad(164) <= $H1 && $H1 <= deg2rad(345)) ? 
			 0.56 + abs(0.2 * cos($H1 + deg2rad(168))) :
			 0.36 + abs(0.4 * cos($H1 + deg2rad(35)))
			 );

	my $SH = $SC * ($F*$T - $F + 1);
	
	my $deltaE = sqrt(&_sqr(($L1 - $L2)/($l * $SL)) + 
					  &_sqr(($C1 - $C2)/($c * $SC)) + 
					  &_sqr($dH/$SH)
					  );

	return $deltaE;
}

=head2  @colorspaces = &Graphics::ColorObject->list_colorspaces()
Returns a list of all supported colorspaces.
=cut 

sub list_colorspaces
{
	return qw(RGB XYZ xyY Lab LCHab Luv LCHuv HSL HSV CMY CMYK YCbCr YPbPr YUV YIQ); # PhotoYCC
}

=head2  @rgb_spaces = &Graphics::ColorObject->list_rgb_spaces()
Returns a list of all supported RGB spaces.  Some items are aliases, so the same space may be listed more than once under different names.
=cut 

sub list_rgb_spaces
{
	return sort keys %RGB_SPACES;
}

=head2  @white_points = &Graphics::ColorObject->list_white_points()
Returns a list of all supported white points.
=cut 

sub list_white_points
{
	return sort keys %WHITE_POINTS;
}


############# non-OO interface ###########

sub RGB_to_RGB255
{
	my ($rgb) = @_;
	my ($r, $g, $b) = @{$rgb};
	if ($r < 0) { $r = 0; } elsif ($r > 1) { $r = 1; }
	if ($g < 0) { $g = 0; } elsif ($g > 1) { $g = 1; }
	if ($b < 0) { $b = 0; } elsif ($b > 1) { $b = 1; }
	# FIXME use round, not sprintf
	return [ sprintf('%.0f', 255*$r), sprintf('%.0f', 255*$g), sprintf('%.0f', 255*$b) ];
}

sub RGB255_to_RGB
{
	my ($rgb255) = @_;
	my ($r, $g, $b) = @{$rgb255};
	return [ $r/255, $g/255, $b/255 ];
}

sub RGBhex_to_RGB
{
	my ($rgbhex) = @_;
	my ($r, $g, $b);
	if ($rgbhex =~ m!^\#([0-9a-fA-F]{6})!) { $rgbhex = $1; }
	if ($rgbhex =~ m!^[0-9a-fA-F]{6}$!)
	{
		$r=hex(substr($rgbhex,0,2));
		$g=hex(substr($rgbhex,2,2));
		$b=hex(substr($rgbhex,4,2));
	}
	return &RGB255_to_RGB([$r, $g, $b]);
	# return &RGB255_to_RGB([ unpack("C*",pack("N",hex($rgbhex)<<8)) ]);
}

sub RGB_to_RGBhex
{
	my ($rgb) = @_;
	my $rgb255 = &RGB_to_RGB255($rgb);
	return sprintf('%02X%02X%02X', @{$rgb255});
}

sub RGB_to_XYZ
{
	my ($rgb, $space) = @_;
	my $s = &_get_RGB_space_by_name($space);
	my $rgb_lin = &RGB_to_linear_RGB($rgb, $space);
	my $xyz = &_mult_v3_m33($rgb_lin, $s->{m});
	return ($xyz);
}

sub XYZ_to_RGB
{
	my ($xyz, $space) = @_;
	my $s = &_get_RGB_space_by_name($space);
	my $rgb_lin = &_mult_v3_m33($xyz, $s->{mstar});
	my $rgb = &linear_RGB_to_RGB($rgb_lin, $space);
	return ($rgb);
}

sub XYZ_to_Lab
{
	my ($xyz, $xyz_white) = @_;
	my ($X, $Y, $Z) = @{$xyz};
	my ($Xw, $Yw, $Zw) = @{$xyz_white};
	my ($L, $a, $b);

	my $epsilon =  0.008856;
	my $kappa = 903.3;

	my ($fx, $fy, $fz);
	my ($xr, $yr, $zr) = ( $X /  $Xw, 
						   $Y /  $Yw, 
						   $Z /  $Zw );

	if ($xr > $epsilon) { $fx = pow($xr, 1/3); } else { $fx = ($kappa*$xr + 16)/116; }
	if ($yr > $epsilon) { $fy = pow($yr, 1/3); } else { $fy = ($kappa*$yr + 16)/116; }
	if ($zr > $epsilon) { $fz = pow($zr, 1/3); } else { $fz = ($kappa*$zr + 16)/116; }

	$L = 116 * $fy - 16;
	$a = 500 * ($fx - $fy);
	$b = 200 * ($fy - $fz);

	return [ $L, $a, $b ];
}

sub Lab_to_XYZ
{
	my ($lab, $xyz_white) = @_;
	my ($L, $a, $b) = @{$lab};
	my ($Xw, $Yw, $Zw) = @{$xyz_white};
	my ($X, $Y, $Z);

	my $epsilon =  0.008856;
	my $kappa = 903.3;

	my ($fx, $fy, $fz);
	my ($xr, $yr, $zr);

	if ($L > $kappa*$epsilon) { $yr = pow( ($L + 16)/116, 3 ); } else { $yr = $L / $kappa; }
	if ( $yr > $epsilon ) { $fy =  ($L + 16)/116; } else { $fy  =  ($kappa*$yr + 16)/116; }

	$fx = ($a / 500) + $fy;
	$fz = $fy - ($b / 200);

	if (pow($fx, 3) > $epsilon) { $xr = pow($fx, 3); } else { $xr = (116 * $fx - 16)/$kappa; }
	if (pow($fz, 3) > $epsilon) { $zr = pow($fz, 3); } else { $zr = (116 * $fz - 16)/$kappa; }
	if ($L > $kappa*$epsilon) { $yr = pow(($L + 16)/116, 3);  } else { $yr = $L/$kappa; }

	$X = $xr * $Xw;
	$Y = $yr * $Yw;
	$Z = $zr * $Zw;
				
	return [ $X, $Y, $Z ];
}


sub RGB_to_Lab
{
	my ($rgb, $space) = @_;
	my $xyz_white = &RGB_to_XYZ([ 1.0, 1.0, 1.0 ], $space);
	my $xyz = &RGB_to_XYZ($rgb, $space);

	return &XYZ_to_Lab($xyz, $xyz_white);
}

sub Lab_to_RGB
{
	my ($lab, $space) = @_;
	my $xyz_white = &RGB_to_XYZ([ 1.0, 1.0, 1.0 ], $space);
	my $xyz = &Lab_to_XYZ($lab, $xyz_white);

	return &XYZ_to_RGB($xyz, $space);
}

sub XYZ_to_Luv
{
	my ($xyz, $xyz_white) = @_;
	my ($X, $Y, $Z) = @{$xyz};
	my ($Xw, $Yw, $Zw) = @{$xyz_white};
	my ($L, $u, $v);

	my $epsilon =  0.008856;
	my $kappa = 903.3;

	my ($yr) = ( $Y /  $Yw );

	if ($yr > $epsilon) { $L = 116 * pow($yr, 1/3) - 16; }
	else { $L = $kappa*$yr; }

	my ($up, $vp);
	my ($upw, $vpw);

	($upw, $vpw) = ( 4 * $Xw / ( $Xw + 15 * $Yw + 3 * $Zw ),
						9 * $Yw / ( $Xw + 15 * $Yw + 3 * $Zw ) );

	if (! ($X == 0 && $Y == 0 && $Z == 0))
	{
		($up, $vp) = ( 4 * $X / ( $X + 15 * $Y + 3 * $Z ),
					   9 * $Y / ( $X + 15 * $Y + 3 * $Z ) );
	}
	else
	{
		($up, $vp) = ($upw, $vpw);
	}

	($u, $v) = ( 13 * $L * ($up - $upw),
				 13 * $L * ($vp - $vpw) );

	return [ $L, $u, $v ];
}

sub Luv_to_XYZ
{
	my ($luv, $xyz_white) = @_;
	my ($L, $u, $v) = @{$luv};
	my ($Xw, $Yw, $Zw) = @{$xyz_white};
	my ($X, $Y, $Z);

	my $epsilon =  0.008856;
	my $kappa = 903.3;

	if ($L > $kappa*$epsilon) { $Y = pow( ($L + 16)/116, 3 ); } else { $Y = $L / $kappa; }

	my ($upw, $vpw) = ( 4 * $Xw / ( $Xw + 15 * $Yw + 3 * $Zw ),
						9 * $Yw / ( $Xw + 15 * $Yw + 3 * $Zw ) );

	if (! ($L == 0 && $u == 0 && $v == 0))
	{
		my $a = (1/3)*( ((52 * $L) / ($u + 13 * $L * $upw)) - 1 );
		my $b = -5 * $Y;
		my $c = -1/3;
		my $d = $Y * ( ((39 * $L) / ($v + 13 * $L * $vpw)) - 5 );
		
		$X = ($d - $b)/($a - $c);
		$Z = $X * $a + $b;
	}
	else
	{
		($X, $Z) = (0.0, 0.0);
	}

	return [ $X, $Y, $Z ];
}

sub Luv_to_LCHuv
{
	my ($luv) = @_;
	my ($L, $u, $v) = @{$luv};
	my ($C, $H);

	$C = sqrt( $u*$u + $v*$v );
	$H = atan2( $v, $u );
	$H = rad2deg($H);

	return [ $L, $C, $H ];
}

sub LCHuv_to_Luv
{
	my ($lch) = @_;
	my ($L, $C, $H) = @{$lch};
	my ($u, $v);

	$H = deg2rad($H);
	my $th = tan($H);
	$u = $C / sqrt( $th * $th + 1 );
	$v = sqrt($C*$C - $u*$u);

	#$H = $H - 2*pi*int($H / 2*pi); # convert H to 0..2*pi - this seems to be wrong
	if ($H < 0) { $H = $H + 2*pi; }
	if ($H > pi/2 && $H < 3*pi/2) { $u = - $u; }
	if ($H > pi) { $v = - $v; }

	return [ $L, $u, $v ];
}

sub XYZ_to_xyY
{
	my ($xyz, $xyz_white) = @_;
	my ($X, $Y, $Z) = @{$xyz};
	my ($Xw, $Yw, $Zw) = @{$xyz_white};
	my ($x, $y);

	if (! ($X == 0 && $Y == 0 && $Z == 0))
	{
		$x = $X / ($X + $Y + $Z);
		$y = $Y / ($X + $Y + $Z);
	}
	else
	{
		$x = $Xw / ( $Xw + $Yw + $Zw );
		$y = $Yw / ( $Xw + $Yw + $Zw );
	}
	
	return [ $x, $y, $Y ];
}

sub xyY_to_XYZ
{
	my ($xyy) = @_;
	my ($x, $y, $Y) = @{$xyy};
	my ($X, $Z);

	if (! ($y == 0))
	{
		$X = $x * $Y / $y;
		$Z = (1 - $x - $y) * $Y / $y;
	}
	else
	{
		$X = 0; $Y = 0; $Z = 0;
	}

	return [ $X, $Y, $Z ];
}


sub Lab_to_LCHab
{
	my ($lab) = @_;
	my ($L, $a, $b) = @{$lab};
	my ($C, $H);

	$C = sqrt( $a*$a + $b*$b );
	$H = atan2( $b, $a );
	$H = rad2deg($H);

	return [ $L, $C, $H ];
}


sub LCHab_to_Lab
{
	my ($lch) = @_;
	my ($L, $C, $H) = @{$lch};
	my ($a, $b);

	$H = deg2rad($H);
	my $th = tan($H);
	$a = $C / sqrt( $th * $th + 1 );
	$b = sqrt($C*$C - $a*$a);

	#$H = $H - 2*pi*int($H / 2*pi); # convert H to 0..2*pi - this seems to be wrong
	if ($H < 0) { $H = $H + 2*pi; }
	if ($H > pi/2 && $H < 3*pi/2) { $a = - $a; }
	if ($H > pi) { $b = - $b; }

	return [ $L, $a, $b ];
}

sub RGB_to_linear_RGB
{
	my ($rgb, $space) = @_;
	my ($R, $G, $B) = @{$rgb};

	my $s = &_get_RGB_space_by_name($space);
	if ($s->{gamma} eq 'sRGB') # handle special sRGB gamma curve
	{
		if ( abs($R) <= 0.04045 ) { $R = $R / 12.92; }
		else { $R = &_apow( ( $R + 0.055 ) / 1.055 , 2.4 ); }

		if ( abs($G) <= 0.04045 ) { $G = $G / 12.92; }
		else { $G = &_apow( ( $G + 0.055 ) / 1.055 , 2.4 ); }

		if ( abs($B) <= 0.04045 ) { $B = $B / 12.92; }
		else { $B = &_apow( ( $B + 0.055 ) / 1.055 , 2.4 ); }
	}
	else 
	{
		$R = &_apow($R, $s->{gamma});
		$G = &_apow($G, $s->{gamma});
		$B = &_apow($B, $s->{gamma});
	}

	return [ $R, $G, $B ];
}

sub linear_RGB_to_RGB
{
	my ($rgb, $space) = @_;
	my ($R, $G, $B) = @{$rgb};

	my $s = &_get_RGB_space_by_name($space);
	if ($s->{gamma} eq 'sRGB') # handle special sRGB gamma curve
	{
		if ( abs($R) <= 0.0031308 ) { $R = 12.92 * $R; }
		else { $R = 1.055 * &_apow($R, 1/2.4) - 0.055; };

		if ( abs($G) <= 0.0031308 ) { $G = 12.92 * $G; }
		else { $G = 1.055 * &_apow($G, 1/2.4) - 0.055; }

		if ( abs($B) <= 0.0031308 ) { $B = 12.92 * $B; }
		else { $B = 1.055 * &_apow($B, 1/2.4) - 0.055; }
	}
	else 
	{
		$R = &_apow($R, 1/$s->{gamma});
		$G = &_apow($G, 1/$s->{gamma});
		$B = &_apow($B, 1/$s->{gamma});
	}

	return [ $R, $G, $B ];
}

# reference: http://en.wikipedia.org/wiki/YIQ
sub RGB_to_YIQ
{
	my ($rgb) = @_; # input should be CIE Rec 601/NTSC non-linear rgb
	my $m     = [[0.299     ,  0.587     ,  0.114     ],
				 [0.59590059, -0.27455667, -0.32134392],
				 [0.21153661, -0.52273617,  0.31119955]];

	my $yiq = &_mult_m33_v3($m, $rgb);
	return $yiq;
}

sub YIQ_to_RGB
{
	my ($yiq) = @_;
	my $mstar = [[ 1.0     ,  0.95598634,  0.6208248 ],
				 [ 1.0     , -0.27201283, -0.64720424],
				 [ 1.0     , -1.1067402 ,  1.7042305 ]];

	my $rgb = &_mult_m33_v3($mstar, $yiq);
	return $rgb; # result is NTSC non-linear rgb
}

sub RGB_to_YUV
{
	my ($rgb) = @_; # input should be CIE Rec 601/NTSC non-linear rgb
	my $m     = [[ 0.299     ,  0.587     ,  0.114      ],
				 [-0.14714119, -0.28886916,  0.43601035 ],
				 [ 0.61497538, -0.51496512, -0.10001026 ]];

	my $yuv = &_mult_m33_v3($m, $rgb);
	return $yuv;
}

sub YUV_to_RGB
{
	my ($yuv) = @_;
	my $mstar = [[ 1.0,  0.0       ,  1.139883   ],
				 [ 1.0, -0.39464233, -0.58062185],
				 [ 1.0,  2.0320619 ,  0.0       ]];

	my $rgb = &_mult_m33_v3($mstar, $yuv);
	return $rgb; # result is NTSC non-linear rgb
}

# reference: http://www.poynton.com/notes/colour_and_gamma/ColorFAQ.txt
# Y is [0..1], Pb and Pr are [-0.5..0.5]
sub RGB_to_YPbPr
{
	my ($rgb) = @_; # input should be CIE Rec 601/NTSC non-linear rgb
	my $m     = [[ 0.299   , 0.587   , 0.114   ],
				 [-0.168736,-0.331264, 0.5     ],
				 [ 0.5     ,-0.418688,-0.081312]];

	my $ypbpr = &_mult_m33_v3($m, $rgb);
	return $ypbpr;
}

sub YPbPr_to_RGB
{
	my ($ypbpr) = @_;
	my $mstar = [[ 1.0     , 0.0     , 1.402   ],
				 [ 1.0     ,-0.344136,-0.714136],
				 [ 1.0     , 1.772   , 0.0     ]];

	my $rgb = &_mult_m33_v3($mstar, $ypbpr);
	return $rgb; # result is NTSC non-linear rgb
}

# Y is [16..235], Cb and Cr are [16..239]
sub RGB_to_YCbCr
{
	my ($rgb) = @_; # input should be NTSC non-linear rgb
	my $m = [[    65.481,   128.553,    24.966],
			 [   -37.797,   -74.203,   112.0  ],
			 [   112.0  ,   -93.786,   -18.214]];

	my $ycbcr = &_add_v3( &_mult_m33_v3($m, $rgb), [ 16, 128, 128 ] );
	return $ycbcr;
}

sub YCbCr_to_RGB
{
	my ($ycbcr) = @_;
	my $mstar = [[ 0.00456621, 0.0       , 0.00625893],
				 [ 0.00456621,-0.00153632,-0.00318811],
				 [ 0.00456621, 0.00791071, 0.0       ]];

	my $rgb = &_mult_m33_v3($mstar, &_add_v3($ycbcr, [-16, -128, -128]));
	return $rgb;
}

# reference: http://wwwde.kodak.com/global/en/professional/products/storage/pcd/techInfo/pcd-045.jhtml
sub RGB_to_PhotoYCC
{
	my ($rgb) = @_; # input should be CIE Rec 709 non-linear rgb
	my $m     = [[ 0.299     ,  0.587     ,  0.114      ],
				 [-0.299     , -0.587     ,  0.866      ],
				 [ 0.701     , -0.587     , -0.114      ]];
	my $ycc = 
		&_add_v3([0, 156, 137], 
				 &_mult_m33_v3([[255/1.402, 0, 0], [0, 111.40, 0], [0, 0, 135.64]], 
							   &_mult_m33_v3($m, $rgb)));
	return $ycc;
}

sub PhotoYCC_to_RGB
{
	my ($ycc) = @_;
	my $mstar = [[ 1.0       ,   0.0       ,   1.0       ],
				 [ 0.99603657,  -0.19817126,  -0.50936968],
				 [ 1.0204082 ,   1.0204082 ,   0.0       ]];

	my $rgb = &_mult_m33_v3($mstar, 
							&_mult_m33_v3([[1/(255/1.402), 0, 0], [0, 1/111.40, 0], [0, 0, 1/135.64]], 
										  &_add_v3([0, -156, -137], $ycc)));
	return $rgb; # result is CIE 709 non-linear rgb
}

sub RGB_to_HSV
{
	my ($rgb) = @_;
	my ($r, $g, $b)=@{$rgb};
	my ($h, $s, $v);

	my $min= &_min($r, $g, $b);
	my $max= &_max($r, $g, $b);

	$v = $max;                              
	my $delta = $max - $min;

	if( $delta != 0 )
	{
		$s = $delta / $max;
	}
	else
	{
		$s = 0;
		$h = 0;
		return [ $h, $s, $v];
	}

	if( $r == $max )
	{
		$h = ( $g - $b ) / $delta; 
	}
	elsif ( $g == $max )
	{
		$h = 2 + ( $b - $r ) / $delta; 
	}
	else # if $b == $max
	{
		$h = 4 + ( $r - $g ) / $delta;
	}

	$h *= 60;
	if( $h < 0 ) { $h += 360; }
	return [ $h, $s, $v ];
}

sub HSV_to_RGB
{
	my ($hsv) = @_;
	my ($h, $s, $v)=@{$hsv};
	my ($r, $g, $b);

	# force $h to 0 <= $h < 360
	# FIXME should not loop, looks infinite
	while ($h < 0) { $h += 360; }
	while ($h >= 360) { $h -= 360; }

	$h /= 60;                       ## sector 0 to 5
	my $i = POSIX::floor( $h );
	my $f = $h - $i;                   ## fractional part of h
	my $p = $v * ( 1 - $s );
	my $q = $v * ( 1 - $s * $f );
	my $t = $v * ( 1 - $s * ( 1 - $f ) );

	if($i == 0)
	{
		$r = $v;
		$g = $t;
		$b = $p;
	}
	elsif($i == 1)
	{
		$r = $q;
		$g = $v;
		$b = $p;
	}
	elsif($i == 2)
	{
		$r = $p;
		$g = $v;
		$b = $t;
	}
	elsif($i == 3)
	{
		$r = $p;
		$g = $q;
		$b = $v;
	}
	elsif($i == 4)
	{
		$r = $t;
		$g = $p;
		$b = $v;
	}
	else # if $i == 5
	{
		$r = $v;
		$g = $p;
		$b = $q;
	}

	return [ $r, $g, $b ];
}

sub RGB_to_HSL
{
	my ($rgb) = @_;
	my ($r,$g,$b)=@{$rgb};

	my ($h, $s, $v) = @{ &RGB_to_HSV($rgb) };

	my $min= &_min($r, $g, $b);
	my $max= &_max($r, $g, $b);
	my $delta = $max - $min;

	my $l = ($max+$min)/2.0;

	if( $delta == 0 )
	{
		return [0, 0, $l];
	}
	else
	{
		if($l <= 0.5)
		{
			$s = $delta/($max+$min); # FIXME possible divide-by-zero
		}
		else
		{
			$s = $delta/(2-$max-$min); # FIXME possible divide-by-zero
		}
	}
	return [$h, $s, $l];
}

sub HSL_to_RGB
{
	my ($hsl) = @_;
	my ($h, $s, $l) = @{$hsl};
	my ($r, $g, $b);
	my ($p1, $p2);

	if( $l <= 0.5 )
	{
		$p1 = $l * (1-$s);
		$p2 = 2*$l - $p1;
	}
	else
	{
		$p2 = $l + $s - ($l*$s);
		$p1 = 2*$l - $p2;
	}
	
	$r = &_rgbquant($p1, $p2, $h+120);
	$g = &_rgbquant($p1, $p2, $h);
	$b = &_rgbquant($p1, $p2, $h-120);
	
	return [ $r, $g, $b ];
}

sub _rgbquant {
	my ($q1, $q2, $h) = @_;

	# force $h to 0 <= $h < 360
	# FIXME should not loop, looks infinite
	while ($h < 0) { $h += 360; }
	while ($h >= 360) { $h -= 360; }

	if ($h < 60)
	{
		return ($q1 + (($q2-$q1)*$h/60) );
	}
	elsif ($h < 180)
	{
		return ($q2);
	}
	elsif ($h < 240)
	{
		return ($q1 + (($q2-$q1)*(240-$h)/60) );
	}
	else
	{
		return ($q1);
	}
}

sub RGB_to_CMY
{
	my ($rgb) = @_;
	return [ map { 1 - $_ } @{$rgb} ];
}

sub CMY_to_RGB
{
	my ($cmy) = @_;
	return [ map { 1 - $_ } @{$cmy} ];
}

sub CMY_to_CMYK
{
	my ($cmy) = @_;
	my $k = &_min(@{$cmy});
	return [ (map { $_-$k } @{$cmy}),$k ];
}

sub CMYK_to_CMY
{
	my ($cmyk) = @_;
	my ($c, $m, $y, $k) = @{$cmyk};
	return [ $c+$k, $m+$k, $y+$k ];
}

sub XYZ_change_white_point
{
	my ($xyz, $xyz_old_white_point, $xyz_new_white_point) = @_;

	# matrices for Bradford color-adaptation
	my $ma = [[ 0.8951,   -0.7502,    0.0389 ],  
			  [ 0.2664,    1.7135,   -0.0685 ], 
			  [ -0.1614,   0.0367,    1.0296 ]];

	my $ma_star =  [[ 0.986993,  0.432305, -0.008529 ],
					[-0.147054,  0.518360,  0.040043 ],
					[ 0.159963,  0.049291,  0.968487 ]];

	# cone = cone response domain value (rho, ypsilon, beta)
	my $cone_old = &_mult_v3_m33($xyz_old_white_point, $ma);
	my $cone_new = &_mult_v3_m33($xyz_new_white_point, $ma);

	my $q = [[ $cone_new->[0]/$cone_old->[0], 0, 0 ],
			 [ 0, $cone_new->[1]/$cone_old->[1], 0 ],
			 [ 0, 0, $cone_new->[2]/$cone_old->[2] ]];
			 
	my $m = &_mult_m33_m33($ma, &_mult_m33_m33($q, $ma_star));

	my $xyz_new = &_mult_v3_m33($xyz, $m);

	return $xyz_new;
}

# reference: http://www.brucelindbloom.com/index.html?Eqn_T_to_xy.html
sub white_point_from_temperature
{
	my ($temp) = @_;
	my ($x, $y);

	if ($temp < 4000 || $temp > 25000)
	{
		carp "color temperature out of range: $temp, should be between 4000 and 25000 Kelvin";
	}

	if ($temp <= 7000)
	{
		$x = -4.6070e+9 / ($temp*$temp*$temp) + 
			2.9678e+6   / ($temp*$temp) +
			0.09911e+3  / $temp +
			0.244063;
	}
	else # $temp > 7000
	{
		$x = -2.0064e+9 / ($temp*$temp*$temp) + 
			1.9018e+6   / ($temp*$temp) +
			0.24748e+3  / $temp +
			0.237040;
	}

	$y = -3.0 * $x * $x + 2.87 * $x - 0.275;

	return [ $x, $y ];
}


######### private utility functions ########

sub _get_RGB_space_by_name
{
	my ($space) = @_;
	# FIXME the logic here is a bit convoluted, this could be cleaned up a lot

	if (! defined $space)
	{
		# carp("no rgb space specified in operation that requires it, defaulting to sRGB");
		$space = 'sRGB';
	}
	elsif (! $RGB_SPACES{ $space })
	{
		carp("rgb space not found: ".$space.", defaulting to sRGB");
		$space = 'sRGB';
	}

	my $s = $RGB_SPACES{$space};
	if ($s && ! ref $s)
	{
		$s = $RGB_SPACES{$s}; # follow aliases
	}

	return $s;
}

sub _check_white_point
{
	my ($white_point) = @_;

	if (! defined $white_point)
	{
		# carp("no white point specified in operation that requires it, defaulting to D65");
		$white_point = 'D65';
	}
	elsif ($white_point =~ m!^(\d+)K$!)
	{
		my $temperature = $1;
		#$white_point = $temperature.'K'; # already in that form
		$WHITE_POINTS{ $white_point } = &white_point_from_temperature($temperature);
	}
	elsif (! $WHITE_POINTS{ $white_point })
	{
		carp("white point not found: ". $white_point.", defaulting to D65");
		$white_point = 'D65';
	}

	return $white_point;
}

sub _mult_v3_m33
{
	my ($v, $m) = @_;
	my $vout = [
				 ( $v->[0] * $m->[0]->[0] + $v->[1] * $m->[1]->[0] + $v->[2] * $m->[2]->[0] ), 
				 ( $v->[0] * $m->[0]->[1] + $v->[1] * $m->[1]->[1] + $v->[2] * $m->[2]->[1] ), 
				 ( $v->[0] * $m->[0]->[2] + $v->[1] * $m->[1]->[2] + $v->[2] * $m->[2]->[2] )
				 ];
	return $vout;
}

sub _mult_m33_v3
{
	my ($m, $v) = @_;
	my $vout = [
				 ( $v->[0] * $m->[0]->[0] + $v->[1] * $m->[0]->[1] + $v->[2] * $m->[0]->[2] ), 
				 ( $v->[0] * $m->[1]->[0] + $v->[1] * $m->[1]->[1] + $v->[2] * $m->[1]->[2] ), 
				 ( $v->[0] * $m->[2]->[0] + $v->[1] * $m->[2]->[1] + $v->[2] * $m->[2]->[2] )
				];
	return $vout;
}

sub _mult_m33_m33
{
	my ($m, $n) = @_;
	my $q = [];
	foreach my $i (0..2)
	{
		foreach my $j (0..2)
		{
			foreach my $k (0..2)
			{
				$q->[$i]->[$j] += $m->[$i]->[$k] * $n->[$k]->[$j];
			}
		}
	}
	return $q;
}

sub _add_v3
{
	my ($a, $b) = @_;
	my $c = [ $a->[0] + $b->[0],
			  $a->[1] + $b->[1],
			  $a->[2] + $b->[2] ];
	return $c;
}

sub _pow_v3
{
	my ($v3, $c) = @_;
	my $v3out = [ pow($v3->[0], $c), pow($v3->[1], $c), pow($v3->[2], $c) ];
	return $v3out;
}

sub _delta_v3
{
	my ($a3, $b3) = @_;
	return (
			abs($a3->[0] - $b3->[0]) +
			abs($a3->[1] - $b3->[1]) +
			abs($a3->[2] - $b3->[2]) );
}

sub _generic_clip
{
	my ($v3, $c32) = @_;
	if ($v3->[0] < $c32->[0]->[0]) { $v3->[0] = $c32->[0]->[0]; }
	if ($v3->[0] > $c32->[0]->[1]) { $v3->[0] = $c32->[0]->[1]; }
	if ($v3->[1] < $c32->[1]->[0]) { $v3->[1] = $c32->[1]->[0]; }
	if ($v3->[1] > $c32->[1]->[1]) { $v3->[1] = $c32->[1]->[1]; }
	if ($v3->[2] < $c32->[2]->[0]) { $v3->[2] = $c32->[2]->[0]; }
	if ($v3->[2] > $c32->[2]->[1]) { $v3->[2] = $c32->[2]->[1]; }
	return $v3;
}

sub _apow
{
	my ($v, $p) = @_;
	return ($v >= 0 ?
			pow($v, $p) : 
			-pow(-$v, $p));
}

sub _sqr
{
	my ($v) = @_;
	return $v*$v;
}

sub _is_zero
{
	my ($v) = @_;
	return (abs($v) < 0.000001);
}

sub _min { my $min = shift(@_); foreach my $v (@_) { if ($v <= $min) { $min = $v; } }; return $min; }

sub _max { my $max = shift(@_); foreach my $v (@_) { if ($v >= $max) { $max = $v; } }; return $max; }

######### colorspace tables ########

# reference: http://www.brucelindbloom.com/Eqn_RGB_XYZ_Matrix.html
# All the rgb spaces that this module knows about.
# Key is the name, value is either another name (i.e. this is an alias), or a hashref containg a white point, gamma, a conversion matrix m for rgb-to-xyz and a reverse matrix mstar for xyz-to-rgb transformations
our %RGB_SPACES = (
'Adobe' => 'Adobe RGB (1998)',
'Adobe RGB (1998)' => {
white_point => 'D65',
gamma => 2.2,
m     => [ [  0.5767001212121210,  0.2973609999999999,  0.0270328181818181 ], [  0.1855557042253521,  0.6273550000000000,  0.0706878873239437 ], [  0.1882125000000000,  0.0752850000000000,  0.9912525000000000 ] ], 
mstar => [ [  2.0414778828777158, -0.9692568708746859,  0.0134454339800522 ], [ -0.5649765261191881,  1.8759931170154693, -0.1183725462165374 ], [ -0.3447127732462102,  0.0415556248231326,  1.0152620834741313 ] ], 
},
'Apple' => 'Apple RGB',
'Apple RGB' => {
white_point => 'D65',
gamma => 1.8,
m     => [ [  0.4496948529411764,  0.2446340000000000,  0.0251829117647059 ], [  0.3162512941176471,  0.6720340000000000,  0.1411836134453782 ], [  0.1845208571428572,  0.0833320000000000,  0.9226042857142855 ] ], 
mstar => [ [  2.9517603398020569, -1.0851001264872848,  0.0854802409232915 ], [ -1.2895090072470441,  1.9908397072633022, -0.2694550155056003 ], [ -0.4738802866606785,  0.0372022452865781,  1.0911301341384845 ] ], 
},
'BestRGB' => {
white_point => 'D50',
gamma => 2.2,
m     => [ [  0.6326700260082926,  0.2284570000000000,  0.0000000000000000 ], [  0.2045557161290322,  0.7373519999999999,  0.0095142193548387 ], [  0.1269951428571429,  0.0341910000000000,  0.8156995714285713 ] ], 
mstar => [ [  1.7552588897490133, -0.5441338472581142,  0.0063467101890703 ], [ -0.4836782739368681,  1.5068795234848715, -0.0175760572028268 ], [ -0.2529998994965047,  0.0215528345168675,  1.2256901641540674 ] ], 
},
'Beta RGB' => {
white_point => 'D50',
gamma => 2.2,
m     => [ [  0.6712546349614399,  0.3032730000000001,  0.0000000000000001 ], [  0.1745833659117997,  0.6637859999999999,  0.0407009558998808 ], [  0.1183817187500000,  0.0329410000000000,  0.7845011448863635 ] ], 
mstar => [ [  1.6832246105012654, -0.7710229999344457,  0.0400016919321019 ], [ -0.4282356869228009,  1.7065573340451357, -0.0885384492378917 ], [ -0.2360181522709381,  0.0446899574535591,  1.2723768250932299 ] ], 
},
'BruceRGB' => {
white_point => 'D65',
gamma => 2.2,
m     => [ [  0.4673842424242424,  0.2409950000000000,  0.0219086363636363 ], [  0.2944540307692308,  0.6835539999999999,  0.0736135076923076 ], [  0.1886300000000000,  0.0754520000000000,  0.9934513333333335 ] ], 
mstar => [ [  2.7456543761403882, -0.9692568108426551,  0.0112706581772173 ], [ -1.1358911781912031,  1.8759930008236942, -0.1139588771251973 ], [ -0.4350565642146659,  0.0415556222493375,  1.0131069405965349 ] ], 
},
'CIE' => {
white_point => 'E',
gamma => 2.2,
m     => [ [  0.4887167547169811,  0.1762040000000000,  0.0000000000000000 ], [  0.3106804602510461,  0.8129850000000002,  0.0102048326359833 ], [  0.2006041111111111,  0.0108110000000000,  0.9898071111111111 ] ], 
mstar => [ [  2.3706802022946527, -0.5138847730830187,  0.0052981111618865 ], [ -0.9000427625776859,  1.4253030498717687, -0.0146947611471193 ], [ -0.4706349622815629,  0.0885813466699250,  1.0093845871252884 ] ], 
},
'ColorMatch' => {
white_point => 'D50',
gamma => 1.8,
m     => [ [  0.5093438823529410,  0.2748840000000000,  0.0242544705882353 ], [  0.3209073388429752,  0.6581320000000002,  0.1087821487603307 ], [  0.1339700000000000,  0.0669850000000000,  0.6921783333333333 ] ], 
mstar => [ [  2.6422872594587332, -1.1119754096457255,  0.0821692807629542 ], [ -1.2234269646206919,  2.0590166676215107, -0.2807234418494614 ], [ -0.3930142794480749,  0.0159613695164458,  1.4559774449385248 ] ], 
},
'DonRGB4' => {
white_point => 'D50',
gamma => 2.2,
m     => [ [  0.6457719999999998,  0.2783499999999999,  0.0037113333333334 ], [  0.1933510457516340,  0.6879700000000001,  0.0179861437908497 ], [  0.1250971428571429,  0.0336800000000000,  0.8035085714285716 ] ], 
mstar => [ [  1.7603878846606116, -0.7126289975811030,  0.0078207770365325 ], [ -0.4881191497764036,  1.6527436537605511, -0.0347412748629646 ], [ -0.2536122811541382,  0.0416715470705678,  1.2447804103656714 ] ], 
},
'ECI' => {
white_point => 'D50',
gamma => 1.8,
m     => [ [  0.6502045454545454,  0.3202500000000000, -0.0000000000000001 ], [  0.1780773380281691,  0.6020710000000000,  0.0678389859154930 ], [  0.1359382500000000,  0.0776790000000000,  0.7573702500000002 ] ], 
mstar => [ [  1.7827609790470664, -0.9593624312689213,  0.0859317810050046 ], [ -0.4969845184555761,  1.9477964513641737, -0.1744675553737970 ], [ -0.2690099687053119, -0.0275807381172883,  1.3228286288043098 ] ], 
},
'Ekta Space PS5' => {
white_point => 'D50',
gamma => 2.2,
m     => [ [  0.5938923114754098,  0.2606289999999999,  0.0000000000000000 ], [  0.2729799428571429,  0.7349460000000001,  0.0419969142857143 ], [  0.0973500000000000,  0.0044250000000000,  0.7832250000000001 ] ], 
mstar => [ [  2.0043787360968186, -0.7110290170493107,  0.0381257297502959 ], [ -0.7304832564783660,  1.6202136618008882, -0.0868766628736253 ], [ -0.2450047962579189,  0.0792227384931296,  1.2725243569115190 ] ], 
},
'601' => 'NTSC',
'CIE Rec 601' => 'NTSC',
'NTSC' => {
white_point => 'C',
gamma => 2.2,
m     => [ [  0.6067337272727271,  0.2988389999999999, -0.0000000000000001 ], [  0.1735638169014085,  0.5868110000000000,  0.0661195492957747 ], [  0.2001125000000000,  0.1143500000000000,  1.1149125000000002 ] ], 
mstar => [ [  1.9104909450902432, -0.9843106185066585,  0.0583742441336926 ], [ -0.5325921048972800,  1.9984488315135187, -0.1185174047562849 ], [ -0.2882837998985277, -0.0282979742694222,  0.8986095763610844 ] ], 
},
'CIE ITU' => 'PAL/SECAM',
'PAL' => 'PAL/SECAM',
'PAL/SECAM' => {
white_point => 'D65',
gamma => 2.2,
m     => [ [  0.4305861818181819,  0.2220210000000001,  0.0201837272727273 ], [  0.3415450833333333,  0.7066450000000000,  0.1295515833333333 ], [  0.1783350000000000,  0.0713340000000000,  0.9392309999999999 ] ], 
mstar => [ [  3.0631308078036081, -0.9692570313532748,  0.0678676345258901 ], [ -1.3932854294802033,  1.8759934276211896, -0.2288214781555966 ], [ -0.4757879688629482,  0.0415556317034429,  1.0691933898259074 ] ], 
},
'ProPhoto' => {
white_point => 'D50',
gamma => 1.8,
m     => [ [  0.7976742857142858,  0.2880400000000000,  0.0000000000000000 ], [  0.1351916830080914,  0.7118740000000000,  0.0000000000000000 ], [  0.0314760000000000,  0.0000860000000000,  0.8284380000000000 ] ], 
mstar => [ [  1.3459444124134017, -0.5445989438461810, -0.0000000000000000 ], [ -0.2556077203964527,  1.5081675237232912, -0.0000000000000000 ], [ -0.0511118080787822,  0.0205351443915685,  1.2070909349884964 ] ], 
},
'SMPTE' => 'SMPTE-C',
'SMPTE-C' => {
white_point => 'D65',
gamma => 2.2,
m     => [ [  0.3935554411764707,  0.2123950000000001,  0.0187407352941176 ], [  0.3652524201680672,  0.7010489999999999,  0.1119321932773109 ], [  0.1916597142857142,  0.0865560000000000,  0.9582985714285710 ] ], 
mstar => [ [  3.5056956039694129, -1.0690641158576772,  0.0563116543373650 ], [ -1.7396380462846184,  1.9778095119692913, -0.1969933651732733 ], [ -0.5440105230649496,  0.0351719640259221,  1.0500467308790999 ] ], 
},
'709' => 'sRGB',
'CIE Rec 709' => 'sRGB',
'sRGB' => {
white_point => 'D65',
gamma => 'sRGB', # 2.4,
m     => [ [  0.4124237575757575,  0.2126560000000000,  0.0193323636363636 ], [  0.3575789999999999,  0.7151579999999998,  0.1191930000000000 ], [  0.1804650000000000,  0.0721860000000000,  0.9504490000000001 ] ], 
mstar => [ [  3.2407109439941704, -0.9692581090654827,  0.0556349466243886 ], [ -1.5372603195869781,  1.8759955135292130, -0.2039948042894247 ], [ -0.4985709144606416,  0.0415556779089489,  1.0570639858633826 ] ], 
},
'WideGamut' => {
white_point => 'D50',
gamma => 2.2,
m     => [ [  0.7161035660377360,  0.2581870000000001,  0.0000000000000000 ], [  0.1009296246973366,  0.7249380000000000,  0.0517812857142858 ], [  0.1471875000000000,  0.0168750000000000,  0.7734375000000001 ] ], 
mstar => [ [  1.4628087611158722, -0.5217931929785991,  0.0349338148323482 ], [ -0.1840625990709008,  1.4472377239217746, -0.0968919015161355 ], [ -0.2743610287417160,  0.0677227300206644,  1.2883952872306403 ] ], 
}
);

# reference: http://www.aim-dtp.net/aim/technology/cie_xyz/cie_xyz.htm
# reference: Wyszecki, G. and Stiles, W. S. Color Science Concepts and Methods, Wiley (2000). ISBN 0471399183
# based on CIE1931 (2 degree FOV)
our %WHITE_POINTS = (
'A'   => [ 0.44757,  0.40745  ], # Tungsten lamp 2856K
'D50' => [ 0.34567,  0.35850  ], # Bright tungsten
'B'   => [ 0.34842,  0.35161  ], # CIE Std illuminant B
'D55' => [ 0.33242,  0.34743  ], # Cloudy daylight
'E'   => [ 0.333333, 0.333333 ], # Normalized reference source
'D65' => [ 0.312713, 0.329016 ], # Daylight 6504K
'C'   => [ 0.310063, 0.316158 ], # North daylight 6774K
'D75' => [ 0.29902,  0.31485  ], # 7500K
'D93' => [ 0.28480,  0.29320  ], # old CRT monitors
'F2'  => [ 0.37207,  0.37512  ], # Cool white fluorescent 4200K
'F7'  => [ 0.31285,  0.32918  ], # Narrow daylight fluorescent 6500K
'F11' => [ 0.38054,  0.37691  ], # Narrow white fluorescent
);


=pod

=head2 EXPORT

None by default.  The 'all' tag causes the non-object-oriented interface to be exported, and you get all the XXX_to_YYY functions, for example RGB_to_XYZ.  Please note that some of these functions need extra arguments in addition to the color value to be converted.

=head1 BUGS

Backwards compatibility with versions before 0.4 is not very well tested.

This module will produce results that are, in some cases, different from other software.  Most of the time that is not a bug in this module, but rather a case where the other software uses an approximate (trading accuracy for speed) algorithm.  That is particularly true for YUV and related conversions which are often implemented using integer-math approximations.  As far as possible, this module produces results which are exact according to the definitions in the relevant CIE/ITU or other standards.

Some color transformations are not exactly reversible.  In particular, conversions between different white points are almost but not exactly reversible.  This is not a bug.

There is no way to choose any other color-adaptation algorithm than the Bradford algorithm.  That is probably ok since the Bradford algorithm is better than other algorithms (such as Von Kries or simple scaling).

There is no way to choose a RGB space other than the built-in ones.

Support for CMYK is very basic, it relies on assumptions that completely do not work in the physical world of subtractive pigment mixtures.  If you tried to convert an image to CMYK directly for printing using these functions, the results will not be very good, to say the least.


=head1 TODO

Add clipping to gamut for every color space.

Choose between several clipping algorithms (nearest, luminance-preserving, hue-preserving).

Add a simpler way to check whether something is within gamut.

Add user-defined RGB spaces.

Calculate RGB matrices from chromaticity coordinates.

Only load non-RGB matrices once at startup.

Add colorspaces: uvw, YOZ, RYB, others?

Add RGB spaces: ROMM, others?

Convert arrays of colors efficiently (maybe someday in C).


=head1 SEE ALSO

The Color FAQ by Charles Poynton is one of the definitive references on the subject:
http://www.poynton.com/notes/colour_and_gamma/ColorFAQ.txt

Bruce Lindbloom's web site contains a tremendous amount of information on color:
http://www.brucelindbloom.com/index.html?Math.html


=head1 AUTHOR

Alex Izvorski, E<lt>izv@dslextreme.comE<gt>

Alfred Reibenschuh E<lt>alfredreibenschuh@yahoo.comE<gt> was the original author for versions up to 0.3a2.

Many thanks to:

Alfred Reibenschuh E<lt>alfredreibenschuh@yahoo.comE<gt> for the previous versions of Graphics::ColorObject, and for the HSL/HSV/CMYK code.

Bruce Lindbloom E<lt>info@brucelindbloom.comE<gt> for providing a wealth of information on color space conversion and color adaptation algorithms, and for the precalculated RGB conversion matrices.

Charles Poynton E<lt>colorfaq@poynton.comE<gt> for the Color FAQ.

Timo Autiokari E<lt>timo.autiokari@aim-dtp.netE<gt> for information on white points.


=head1 COPYRIGHT AND LICENSE

Copyright 2003-2005 by Alex Izvorski

Portions Copyright 2001-2003 by Alfred Reibenschuh

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut 

################ emulation of previous versions (pre-0.4) #################

#sub mMin {}
#sub mMax {}
sub RGBtoHSV { my (@c) = @_; return @{&RGB_to_HSV([@c])}; }
sub HSVtoRGB { my (@c) = @_; return @{&HSV_to_RGB([@c])}; }
sub RGBtoHSL { my (@c) = @_; return @{&RGB_to_HSL([@c])}; }
sub RGBquant { my (@c) = @_; return &_rgbquant(@c); }
sub HSLtoRGB { my (@c) = @_; return @{&HSL_to_RGB([@c])}; }
#sub namecolor {} # see below
#sub new {} # if given args that are not a hash, this calls namecolor
sub newRGB { my ($p, @c) = @_; return &new_RGB($p, [@c], space=>'NTSC'); }
sub newHSV { my ($p, @c) = @_; return &new_HSV($p, [@c], space=>'NTSC'); }
sub newHSL { my ($p, @c) = @_; return &new_HSL($p, [@c], space=>'NTSC'); }
sub newGrey { my ($p, @c) = @_; return &new_YPbPr($p, [$c[0], 0.0, 0.0], space=>'NTSC'); }
sub asRGB { my ($this) = @_; return @{$this->as_RGB()}; }
sub asHSV { my ($this) = @_; return @{$this->as_HSV()}; }
sub asHSL { my ($this) = @_; return @{$this->as_HSL()}; }
sub asGrey { my ($this) = @_; return $this->as_YPbPr()->[0]; }
sub asGrey2 { my ($this) = @_; return $this->asGrey(); } # slightly different results
sub asLum { my ($this) = @_; return $this->as_HSL()->[2]; }
sub asCMY { my ($this) = @_; return @{$this->as_CMY()}; }
sub asCMYK { my ($this) = @_; return @{$this->as_CMYK()}; }
sub asCMYK2 { my ($this) = @_; return @{$this->as_CMYK()}; } # slightly different results
sub asCMYK3 { my ($this) = @_; return (map { $_*0.75 } @{$this->as_CMYK()}); }
sub asHex { my ($this) = @_; return '#'.$this->as_RGBhex(); }
sub asHexCMYK { my ($this) = @_; return sprintf('%%%02X%02X%02X%02X', map {$_*255} $this->asCMYK()); }
sub asHexHSV { my ($this) = @_; return sprintf('!%02X%02X%02X', map {$_*255} $this->asHSV()); }
sub setRGB { my ($this, @c) = @_; %{$this} = %{&newRGB(ref $this, @c)}; }
sub setHSV { my ($this, @c) = @_; %{$this} = %{&newHSV(ref $this, @c)}; }
sub setHSL { my ($this, @c) = @_; %{$this} = %{&newHSL(ref $this, @c)}; }
sub setGrey { my ($this, @c) = @_; %{$this} = %{&newGrey(ref $this, @c)}; }
sub setHex { my ($this, @c) = @_; %{$this} = %{&new(ref $this, @c)}; }
sub addSaturation { my ($this, $s2) = @_; my ($h,$s,$v)=$this->asHSV; $this->setHSV($h,$s+$s2,$v); }
sub setSaturation { my ($this, $s2) = @_; my ($h,$s,$v)=$this->asHSV; $this->setHSV($h,$s2,$v); }
sub rotHue { my ($this, $h2) = @_;	my ($h,$s,$v)=$this->asHSV; $h+=$h2; $h%=360; $this->setHSV($h,$s,$v); }
sub setHue { my ($this, $h2) = @_;	my ($h,$s,$v)=$this->asHSV; $this->setHSV($h2,$s,$v); }
sub addBrightness { my ($this, $v2) = @_; my ($h,$s,$v)=$this->asHSV; $this->setHSV($h,$s,$v+$v2); }
sub setBrightness { my ($this, $v2) = @_; my ($h,$s,$v)=$this->asHSV; $this->setHSV($h,$s,$v2); }
sub addLightness { my ($this, $l2) = @_; my ($h,$s,$l)=$this->asHSL; $this->setHSL($h,$s,$l+$l2); }
sub setLightness { my ($this, $l2) = @_; my ($h,$s,$l)=$this->asHSL; $this->setHSL($h,$s,$l2); }

use Graphics::ColorNames;

our %COLORNAMES;
tie %COLORNAMES, 'Graphics::ColorNames', qw(HTML Windows Netscape X);

sub namecolor {
	my $name=lc(shift @_);
	$name=~s/[^\#!%\&a-z0-9]//g;
	my $col;
	my $opt=shift @_;
	if($name=~/^#/) {
		my ($r,$g,$b,$h);
		if(length($name)<5) {		# zb. #fa4,          #cf0
			$r=hex(substr($name,1,1))/0xf;
			$g=hex(substr($name,2,1))/0xf;
			$b=hex(substr($name,3,1))/0xf;
		} elsif(length($name)<8) {	# zb. #ffaa44,       #ccff00
			$r=hex(substr($name,1,2))/0xff;
			$g=hex(substr($name,3,2))/0xff;
			$b=hex(substr($name,5,2))/0xff;
		} elsif(length($name)<11) {	# zb. #fffaaa444,    #cccfff000
			$r=hex(substr($name,1,3))/0xfff;
			$g=hex(substr($name,4,3))/0xfff;
			$b=hex(substr($name,7,3))/0xfff;
		} else {			# zb. #ffffaaaa4444, #ccccffff0000
			$r=hex(substr($name,1,4))/0xffff;
			$g=hex(substr($name,5,4))/0xffff;
			$b=hex(substr($name,9,4))/0xffff;
		}
		$col=[$r,$g,$b];
	} elsif($name=~/^%/) {
		my ($r,$g,$b,$c,$y,$m,$k);
		if(length($name)<6) {		# zb. %cmyk
			$c=hex(substr($name,1,1))/0xf;
			$m=hex(substr($name,2,1))/0xf;
			$y=hex(substr($name,3,1))/0xf;
			$k=hex(substr($name,4,1))/0xf;
		} elsif(length($name)<10) {	# zb. %ccmmyykk
			$c=hex(substr($name,1,2))/0xff;
			$m=hex(substr($name,3,2))/0xff;
			$y=hex(substr($name,5,2))/0xff;
			$k=hex(substr($name,7,2))/0xff;
		} elsif(length($name)<14) {	# zb. %cccmmmyyykkk
			$c=hex(substr($name,1,3))/0xfff;
			$m=hex(substr($name,4,3))/0xfff;
			$y=hex(substr($name,7,3))/0xfff;
			$k=hex(substr($name,10,3))/0xfff;
		} else {			# zb. %ccccmmmmyyyykkkk
			$c=hex(substr($name,1,4))/0xffff;
			$m=hex(substr($name,5,4))/0xffff;
			$y=hex(substr($name,9,4))/0xffff;
			$k=hex(substr($name,13,4))/0xffff;
		}
		if($opt) {
			$r=1-$c-$k;
			$g=1-$m-$k;
			$b=1-$y-$k;
			$col=[$r,$g,$b];
		} else {
			$r=1-$c-$k;
			$g=1-$m-$k;
			$b=1-$y-$k;
			$col=[$r,$g,$b];
		}
	} elsif($name=~/^!/) {
		my ($r,$g,$b,$h,$s,$v);
		if(length($name)<5) {		
			$h=360*hex(substr($name,1,1))/0xf;
			$s=hex(substr($name,2,1))/0xf;
			$v=hex(substr($name,3,1))/0xf;
		} elsif(length($name)<8) {
			$h=360*hex(substr($name,1,2))/0xff;
			$s=hex(substr($name,3,2))/0xff;
			$v=hex(substr($name,5,2))/0xff;
		} elsif(length($name)<11) {	
			$h=360*hex(substr($name,1,3))/0xfff;
			$s=hex(substr($name,4,3))/0xfff;
			$v=hex(substr($name,7,3))/0xfff;
		} else {		
			$h=360*hex(substr($name,1,4))/0xffff;
			$s=hex(substr($name,5,4))/0xffff;
			$v=hex(substr($name,9,4))/0xffff;
		}
		if($opt) {
			($r,$g,$b)=HSVtoRGB($h,$s,$v);
			$col=[$r,$g,$b];
		} else {
			($r,$g,$b)=HSVtoRGB($h,$s,$v);
			$col=[$r,$g,$b];
		}
	} elsif($name=~/^&/) {
		my ($r,$g,$b,$h,$s,$l);
		if(length($name)<5) {		
			$h=360*hex(substr($name,1,1))/0xf;
			$s=hex(substr($name,2,1))/0xf;
			$l=hex(substr($name,3,1))/0xf;
		} elsif(length($name)<8) {
			$h=360*hex(substr($name,1,2))/0xff;
			$s=hex(substr($name,3,2))/0xff;
			$l=hex(substr($name,5,2))/0xff;
		} elsif(length($name)<11) {	
			$h=360*hex(substr($name,1,3))/0xfff;
			$s=hex(substr($name,4,3))/0xfff;
			$l=hex(substr($name,7,3))/0xfff;
		} else {		
			$h=360*hex(substr($name,1,4))/0xffff;
			$s=hex(substr($name,5,4))/0xffff;
			$l=hex(substr($name,9,4))/0xffff;
		}
		if($opt) {
			($r,$g,$b)=HSLtoRGB($h,$s,$l);
			$col=[$r,$g,$b];
		} else {
			($r,$g,$b)=HSLtoRGB($h,$s,$l);
			$col=[$r,$g,$b];
		}
	} else {
		if ($COLORNAMES{$name})
		{
			my ($r, $g, $b) = &Graphics::ColorNames::hex2tuple($COLORNAMES{$name});
			($r, $g, $b) = map { $_/0xff } ($r, $g, $b);
			$col=[$r,$g,$b];
		}
		else
		{
			return undef;
		}
	}
	return $col;
}

1;

__END__
