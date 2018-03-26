package ICC::Shared;

use strict;
use Carp;
use File::Spec;
use List::Util;
use Math::Matrix;
use POSIX qw(:math_h :float_h);
use Scalar::Util;
use Storable;
use YAML::Tiny;
use Exporter qw(import);

our $VERSION = 0.53;

# revised 2018-03-24
#
# Copyright © 2004-2018 by William B. Birkett

# this module contains common methods, constants and functions

# enable static variables
use feature 'state';

# constants
use constant D50 => [96.42, 100, 82.49]; # ICC D50 XYZ
use constant d50 => [0.9642, 1.0, 0.8249]; # ICC D50 XYZNumber
use constant d50P => [map {$_ * 32768/65535} 0.9642, 1.0, 0.8249]; # ICC D50 16-bit XYZ PCS
use constant PI => atan2(0, -1); # pi
use constant radian => 180/PI; # radian (in degrees)
use constant ln10 => log(10); # natural log of 10
use constant sin16 => sin(16/radian); # sin(16˚)
use constant cos16 => cos(16/radian); # cos(16˚)

BEGIN {
	
	# set constant vector elements to be read-only
	for (@{(D50)}) {Internals::SvREADONLY($_, 1)}
	for (@{(d50)}) {Internals::SvREADONLY($_, 1)}
	for (@{(d50P)}) {Internals::SvREADONLY($_, 1)}
	
}

# list of constants and functions to export
our @EXPORT = qw(D50 d50 d50P PI radian ln10 xyz2Lab Lab2xyz xyz2Lxyz Lxyz2xyz Lab2Lxyz Lxyz2Lab
XYZ2Lab Lab2XYZ XYZ2Lxyz Lxyz2XYZ XYZ2xyz xyz2XYZ XYZ2xyY xyY2XYZ x2L L2x dLdx dxdL XYZ2W xyz2dwv
xyz2Lab_jac Lab2xyz_jac dEab dEcmc dE94 dE00 dE99 dCh CCT CCT2 bbrad bbxy bbuv XYZ2ucs xy2ucs daylight
linear linear_matrix cspline cspline_matrix lagrange lagrange_matrix dotProduct crossProduct
flatten clip_struct round s15f162v v2s15f16 makeProfileFolder getICCPath filterPath setFile);

# add POSIX functions/constants
push(@EXPORT, @{$POSIX::EXPORT_TAGS{'math_h'}});
push(@EXPORT, @{$POSIX::EXPORT_TAGS{'float_h'}});

#----------- common methods -----------

# copy an object (using Storable)
# parameters: ([number_of_copies])
# returns: (new_object_references)
sub copy {

	# get parameters
	my ($self, $n) = @_;

	# set default to one copy
	$n = 1 if (! defined($n));

	# return empty if zero copies
	return() if ($n == 0);

	# verify number of copies is a positive integer
	(! ref($n) && $n == int($n) && $n > 0) || croak('number of copies not a positive integer');

	# verify parameter is a reference
	(ref($self)) || croak("can't copy class $self");

	# return copies
	return(wantarray ? map {Storable::dclone($self)} (1 .. $n) : Storable::dclone($self));

}

# print object contents
# format parameter is an array structure
# parameter: ([format])
# returns: (string)
sub dump {

	# get parameters
	my ($self, $format) = @_;

	# verify object has 'sdump' method
	($self->can('sdump')) || croak("object lacks 'sdump' method");

	# get string from 'sdump'
	my $s = $self->sdump($format);

	# print string
	print $s, "\n";

	# return string
	return($s);

}

#------- color encoding functions -------

# convert xyz to L*a*b*
# parameters: (input_array -or- input_structure)
# returns: (output_array -or- output_structure)
sub xyz2Lab {

	# push subroutine reference and number of parameters
	push(@_, \&_xyz2Lab);

	# convert input
	&_convert3;

}

# convert L*a*b* to xyz
# parameters: (input_array -or- input_structure)
# returns: (output_array -or- output_structure)
sub Lab2xyz {

	# push subroutine reference and number of parameters
	push(@_, \&_Lab2xyz);

	# convert input
	&_convert3;

}

# convert xyz to LxLyLz
# parameters: (input_array -or- input_structure)
# returns: (output_array -or- output_structure)
sub xyz2Lxyz {

	# push subroutine reference and number of parameters
	push(@_, \&_xyz2Lxyz);

	# convert input
	&_convert3;

}

# convert LxLyLz to xyz
# parameters: (input_array -or- input_structure)
# returns: (output_array -or- output_structure)
sub Lxyz2xyz {

	# push subroutine reference and number of parameters
	push(@_, \&_Lxyz2xyz);

	# convert input
	&_convert3;

}

# convert L*a*b* to LxLyLz
# parameters: (input_array -or- input_structure)
# returns: (output_array -or- output_structure)
sub Lab2Lxyz {

	# push subroutine reference and number of parameters
	push(@_, \&_Lab2Lxyz);

	# convert input
	&_convert3;

}

# convert LxLyLz to L*a*b*
# parameters: (input_array -or- input_structure)
# returns: (output_array -or- output_structure)
sub Lxyz2Lab {

	# push subroutine reference and number of parameters
	push(@_, \&_Lxyz2Lab);

	# convert input
	&_convert3;

}

# convert XYZ to L*a*b*
# default illuminant is D50
# parameters: (input_array -or- input_structure, [white_point_vector])
# returns: (output_array -or- output_structure)
sub XYZ2Lab {

	# push subroutine reference and number of parameters
	push(@_, \&_XYZ2Lab);

	# convert input
	&_convert4;

}

# convert L*a*b* to XYZ
# default illuminant is D50
# parameters: (input_array -or- input_structure, [white_point_vector])
# returns: (output_array -or- output_structure)
sub Lab2XYZ {

	# push subroutine reference and number of parameters
	push(@_, \&_Lab2XYZ);

	# convert input
	&_convert4;

}

# convert XYZ to LxLyLz
# default illuminant is D50
# parameters: (input_array -or- input_structure, [white_point_vector])
# returns: (output_array -or- output_structure)
sub XYZ2Lxyz {

	# push subroutine reference and number of parameters
	push(@_, \&_XYZ2Lxyz);

	# convert input
	&_convert4;

}

# convert LxLyLz to XYZ
# default illuminant is D50
# parameters: (input_array -or- input_structure, [white_point_vector])
# returns: (output_array -or- output_structure)
sub Lxyz2XYZ {

	# push subroutine reference and number of parameters
	push(@_, \&_Lxyz2XYZ);

	# convert input
	&_convert4;

}

# convert XYZ to xyz
# default illuminant is D50
# parameters: (input_array -or- input_structure, [white_point_vector])
# returns: (output_array -or- output_structure)
sub XYZ2xyz {

	# push subroutine reference and number of parameters
	push(@_, \&_XYZ2xyz);

	# convert input
	&_convert4;

}

# convert xyz to XYZ
# default illuminant is D50
# parameters: (input_array -or- input_structure, [white_point_vector])
# returns: (output_array -or- output_structure)
sub xyz2XYZ {

	# push subroutine reference and number of parameters
	push(@_, \&_xyz2XYZ);

	# convert input
	&_convert4;

}

# # convert XYZ to xyY
# parameters: (input_array -or- input_structure)
# returns: (output_array -or- output_structure)
sub XYZ2xyY {

	# push subroutine reference and number of parameters
	push(@_, \&_XYZ2xyY);

	# convert input
	&_convert3;

}

# convert xyY to XYZ
# parameters: (input_array -or- input_structure)
# returns: (output_array -or- output_structure)
sub xyY2XYZ {

	# push subroutine reference and number of parameters
	push(@_, \&_xyY2XYZ);

	# convert input
	&_convert3;

}

# convert x to L
# parameter: (x)
# returns: (L)
sub x2L {

	# return L
	return(($_[0] > 216/24389) ? 116 * $_[0]**(1/3) - 16 : $_[0] * 24389/27);

}

# convert L to x
# parameter: (L)
# returns: (x)
sub L2x {

	# return x
	return(($_[0] > 8) ? (($_[0] + 16)/116)**3 : $_[0] * 27/24389);

}

# compute dL/dx
# parameter: (x)
# returns: (dL/dx)
sub dLdx {

	# get x
	my $x = shift();

	# return dL/dx
	return(($x > 216/24389) ? 116 * $x**(-2/3)/3 : 24389/27);

}

# compute dx/dL
# parameter: (L)
# returns: (dx/dL)
sub dxdL {

	# get L
	my $L = shift();

	# return dx/dL
	return(($L > 8) ? 3 * (($L + 16)/116)**2/116 : 27/24389);

}

# compute xyz to L*a*b* Jacobian matrix
# parameters: (x, y, z)
# returns: (Jacobian_matrix)
sub xyz2Lab_jac {

	# get parameters
	my ($x, $y, $z) = @_;

	# compute ∂Lx/∂x, ∂Ly/∂y, ∂Lz/∂z values
	my $dLx = dLdx($x);
	my $dLy = dLdx($y);
	my $dLz = dLdx($z);

	# return Jacobian matrix
	return(Math::Matrix->new(
		[0, $dLy, 0],
		[$dLx * 500/116, -$dLy * 500/116, 0],
		[0, $dLy * 200/116, -$dLz * 200/116]
	));
	
}

# compute L*a*b* to xyz Jacobian matrix
# parameters: (L, a, b)
# returns: (Jacobian_matrix)
sub Lab2xyz_jac {

	# get parameters
	my ($L, $a, $b) = @_;

	# compute ∂x/∂Lx, ∂y/∂Ly, ∂z/∂Lz values
	my $dx = dxdL($L + 116 * $a/500);
	my $dy = dxdL($L);
	my $dz = dxdL($L - 116 * $b/200);

	# return Jacobian matrix
	return(Math::Matrix->new(
		[$dx, $dx * 116/500, 0],
		[$dy, 0, 0],
		[$dz, 0, -$dz * 116/200]
	));
	
}

# convert XYZ to CIE Whiteness
# parameters: (X, Y, Z, ref_to_WP_vector)
# returns: (W)
sub XYZ2W {

	# get parameters
	my ($X, $Y, $Z, $wtpt) = @_;

	# compute chromaticity values
	my @xyYs = _XYZ2xyY($X, $Y, $Z); # sample
	my @xyYw = _XYZ2xyY(@{$wtpt}); # white point

	# return Whiteness
	return($Y + 800 * ($xyYw[0] - $xyYs[0]) + 1700 * ($xyYw[1] - $xyYs[1]));

}

# convert xyz to density-weighted value
# parameters: (x, y, z)
# returns: (dw_value)
sub xyz2dwv {

	# get parameters
	my ($x, $y, $z) = @_;

	# return 0 if any parameter <= 0
	return(0) if ($x <= 0 || $y <= 0 || $x <= 0);

	# compute weight values
	my $wx = -log($x/($x + $y + $z));
	my $wy = -log($y/($x + $y + $z));
	my $wz = -log($z/($x + $y + $z));

	# return density-weighted value
	return(($wx * $x + $wy * $y + $wz * $z)/($wx + $wy + $wz));

}

#-------- color difference functions --------

# compute ∆E*ab color difference
# parameters: (L*a*b*_1, L*a*b*_2)
# returns: (∆E*ab_value)
sub dEab {

	# return ∆E*ab
	return(sqrt(($_[0] - $_[3])**2 + ($_[1] - $_[4])**2 + ($_[2] - $_[5])**2));

}

# compute CMC color difference
# note: this function is not commutative
# L*a*b*_1 is the reference, L*a*b*_2 is the sample
# optional parameters are l (lightness) and c (chroma)
# default values of optional parameters are 2:1 (l:c)
# note: this function assumes D65, 10• colorimetry
# parameters: (L*a*b*_1, L*a*b*_2, [l, c])
# returns: (∆E*cmc_value)
sub dEcmc {

	# local variables
	my ($dL, $C1, $C2, $dC, $dH2, $h1);
	my ($F, $T, $Sl, $Sc, $Sh, $l, $c);

	# compute ∆L*
	$dL = $_[0] - $_[3];

	# compute C1*
	$C1 = sqrt($_[1]**2 + $_[2]**2);

	# compute C2*
	$C2 = sqrt($_[4]**2 + $_[5]**2);

	# compute ∆C*
	$dC = $C1 - $C2;

	# compute ∆H*^2
	$dH2 = ($_[1] - $_[4])**2 + ($_[2] - $_[5])**2 - $dC**2;

	# compute h1
	$h1 = ($_[2] || $_[1]) ? radian * atan2($_[2], $_[1]) : 0;

	# adjust h1 if negative
	$h1 += 360 if ($h1 < 0);

	# compute F
	$F = sqrt($C1**4/($C1**4 + 1900));

	# compute T
	$T = ($h1 >= 164 && $h1 <= 345) ? 0.56 + abs(0.2 * cos(($h1 + 168)/radian)) : 0.36 + abs(0.4 * cos(($h1 + 35)/radian));

	# compute Sl
	$Sl = $_[0] < 16 ? 0.511 : 0.040975 * $_[0]/(1 + 0.01765 * $_[0]);

	# compute Sc
	$Sc = 0.0638 * $C1/(1 + 0.0131 * $C1) + 0.638;

	# compute Sh
	$Sh = $Sc * ($F * $T + 1 - $F);

	# get l
	$l = defined($_[6]) ? $_[6] : 2;

	# get c
	$c = defined($_[7]) ? $_[7] : 1;

	# return ∆Ecmc
	return(sqrt(($dL/($l * $Sl))**2 + ($dC/($c * $Sc))**2 + $dH2/($Sh**2)));

}

# compute ∆E*94 (graphic arts) color difference
# parameters: (L*a*b*_1, L*a*b*_2)
# returns: (∆E*94_value)
sub dE94 {

	# local variables
	my ($dL, $C1, $C2, $dC, $dH2, $dH, $Cm);

	# compute ∆L*
	$dL = $_[0] - $_[3];

	# compute C1*
	$C1 = sqrt($_[1]**2 + $_[2]**2);

	# compute C2*
	$C2 = sqrt($_[4]**2 + $_[5]**2);

	# compute ∆C*
	$dC = $C1 - $C2;

	# compute ∆H*^2
	$dH2 = ($_[1] - $_[4])**2 + ($_[2] - $_[5])**2 - $dC**2;

	# compute geometric mean C*ab (makes function commutative)
	$Cm = sqrt($C1 * $C2);

	# return ∆E*94
	return(sqrt($dL**2 + ($dC/(1 + 0.045 * $Cm))**2 + ($dH2/(1 + 0.015 * $Cm)**2)));

}

# compute ∆E*00 color difference
# parameters: (L*a*b*_1, L*a*b*_2)
# returns: (∆E*00_value)
sub dE00 {

	# local variables
	my ($dL, $C1, $C2, $Lm, $Cm, $amult, $a1p, $a2p, $C1p, $C2p, $Cmp);
	my ($dCp, $h1p, $h2p, $dhp, $dHp, $Hp, $T, $Sl, $Sc, $Sh, $Rt);

	# compute ∆L*
	$dL = $_[3] - $_[0];

	# compute mean L*
	$Lm = ($_[3] + $_[0])/2;

	# compute C1*
	$C1 = sqrt($_[1]**2 + $_[2]**2);

	# compute C2*
	$C2 = sqrt($_[4]**2 + $_[5]**2);

	# compute mean C*
	$Cm = ($C1 + $C2)/2;

	# compute a' multiplier
	$amult = (1 + (1 - sqrt($Cm**7/($Cm**7 + 6103515625)))/2);

	# compute a1'
	$a1p = $_[1] * $amult;

	# compute a2'
	$a2p = $_[4] * $amult;

	# compute C1'
	$C1p = sqrt($a1p**2 + $_[2]**2);

	# compute C2'
	$C2p = sqrt($a2p**2 + $_[5]**2);
	
	# compute mean C'
	$Cmp = ($C1p + $C2p)/2;
	
	# compute ∆C'
	$dCp = $C2p - $C1p;

	# compute h1'
	$h1p = ($_[2] || $a1p) ? radian * atan2($_[2], $a1p) : 0;

	# adjust h1' if negative
	$h1p += 360 if ($h1p < 0);

	# compute h2'
	$h2p = ($_[5] || $a2p) ? radian * atan2($_[5], $a2p) : 0;

	# adjust h2' if negative
	$h2p += 360 if ($h2p < 0);

	# abs(h1' - h2') > 180
	if (abs($h1p - $h2p) > 180) {
		
		# if h2' > h1'
		if ($h2p > $h1p) {
			
			# compute ∆h'
			$dhp = $h2p - $h1p - 360;
			
		} else {
			
			# compute ∆h'
			$dhp = $h2p - $h1p + 360;
			
		}
		
	} else {
		
		# compute ∆h'
		$dhp = $h2p - $h1p;
		
	}

	# compute ∆H'
	$dHp = 2 * sqrt($C1p * $C2p) * sin($dhp/(radian * 2));

	# if C1' or C2' is zero
	if ($C1p == 0 || $C2p == 0) {
		
		# compute H'
		$Hp = $h1p + $h2p;
		
	} else {
		
		# if abs(h1' - h2') > 180
		if (abs($h1p - $h2p) > 180) {
			
			# compute H'
			$Hp = ($h1p + $h2p + 360)/2;
			
		} else {
			
			# compute H'
			$Hp = ($h1p + $h2p)/2;
			
		}
		
	}

	# compute T
	$T = 1 - 0.17 * cos(($Hp - 30)/radian) + 0.24 * cos((2 * $Hp)/radian) + 0.32 * cos((3 * $Hp + 6)/radian) - 0.20 * cos((4 * $Hp - 63)/radian);

	# compute Sl
	$Sl = 1 + (0.015 * ($Lm - 50)**2)/sqrt(20 + ($Lm - 50)**2);

	# compute Sc
	$Sc = 1 + 0.045 * $Cmp;

	# compute Sh
	$Sh = 1 + 0.015 * $Cmp * $T;

	# compute Rt
	$Rt = -2 * sqrt($Cmp**7/($Cmp**7 + 6103515625)) * sin((60 * exp(-(($Hp - 275)/25)**2))/radian);

	# return ∆E*00 difference
	return(sqrt(($dL/$Sl)**2 + ($dCp/$Sc)**2 + ($dHp/$Sh)**2 + $Rt * ($dCp/$Sc) * ($dHp/$Sh)));

}

# compute DIN 99 color difference
# optional parameters are Ke (lightness) and Kch (chroma)
# default values of optional parameters are Ke = 1, Kch = 1
# parameters: (L*a*b*_1, L*a*b*_2, [Ke, Kch])
# returns: (DIN_99_value)
sub dE99 {

	# compute DIN 99 Lab for sample 1
	my @Lab1 = _Lab2DIN99(@_[0 .. 2, 6, 7]);

	# compute DIN 99 Lab for sample 2
	my @Lab2 = _Lab2DIN99(@_[3 .. 7]);

	# return DIN 99 color difference
	return(sqrt(($Lab1[0] - $Lab2[0])**2 + ($Lab1[1] - $Lab2[1])**2 +($Lab1[2] - $Lab2[2])**2));

}

# compute ∆Ch chroma difference (aka ∆F)
# parameters: (L*a*b*_1, L*a*b*_2)
sub dCh {

	# return chroma difference
	return(sqrt(($_[1] - $_[4])**2 + ($_[2] - $_[5])**2));

}

#--------- illuminant functions ---------

# correlated color temperature (CCT)
# minimizes the UCS u,v error value
# the error value should be less than 5E-2
# parameters: (x, y)
# returns: (CCT, error_value)
sub CCT {

	# get parameters
	my ($x, $y) = @_;

	# local variables
	my ($ut, $vt, $T, $dT, $u, $v, $err, $ux, $vx, $errx, $derv, $derv0);

	# compute target u,v values
	($ut, $vt) = xy2ucs($x, $y);

	# compute CCT using McCamy's approximation
	$T = CCT2($x, $y);

	# compute current u,v values
	($u, $v) = bbuv($T);

	# compute current error
	$err = sqrt(($u - $ut)**2 + ($v - $vt)**2);

	# compute delta values
	($ux, $vx) = bbuv($T + 1E-3);

	# compute delta error
	$errx = sqrt(($ux - $ut)**2 + ($vx - $vt)**2);

	# compute derr/dT
	$derv = ($errx - $err)/1E-3;

	# initialize delta T
	$dT = $derv > 0 ? -2 : 2;

	# optimization loop
	for (0 .. 30) {
		
		# adjust T value
		$T += $dT;
		
		# compute current u,v values
		($u, $v) = bbuv($T);
		
		# compute current error
		$err = sqrt(($u - $ut)**2 + ($v - $vt)**2);
		
		# compute delta values
		($ux, $vx) = bbuv($T + 1E-3);
		
		# compute delta error
		$errx = sqrt(($ux - $ut)**2 + ($vx - $vt)**2);
		
		# save previous derr/dT values
		$derv0 = $derv;
		
		# compute new derr/dT
		$derv = ($errx - $err)/1E-3;
		
		# quit loop if derr/dT < 1E-9
		last if (abs($derv) < 1E-9);
		
		# adjust delta T if sign of derivative changes
		$dT /= -2 if (($derv > 0) ^ ($derv0 > 0));
		
	}

	# return CCT
	return($T, $err);

}

# correlated color temperature (CCT)
# using McCamy's approximation
# parameters: (x, y)
# returns: (CCT)
sub CCT2 {

	# get parameters
	my ($x, $y) = @_;

	# compute n
	my $n = ($x - 0.3320)/($y - 0.1858);

	# return CCT
	return(-449 * $n**3 + 3525 * $n**2 - 6823.3 * $n + 5520.33);

}

# black body radiance (Planck's law)
# using constants and formula per CIE 15
# wavelength in nm, temperature in degrees Kelvin
# parameters: (wavelength, temperature)
# returns: (radiance)
sub bbrad {

	# get parameters
	my ($lambda, $T) = @_;

	# CIE constants
	my $c1 = 3.741771E-16; # 2πhc²
	my $c2 = 1.4388E-2; # hc/kB

	# convert wavelength to meters
	$lambda *= 1E-9;

	# return radiance value
	return($c1/(PI * $lambda**5 * (exp($c2/($lambda * $T)) - 1)));

}

# compute chromaticity values of black body radiator
# parameter: (temperature)
# returns: (x, y)
sub bbxy {

	# get temperature
	my $T = shift();

	# local variables
	my ($b, $X, $Y, $Z, $d);

	# load CIE color matching functions (YAML format)
	state $cmf = YAML::Tiny->read(getICCPath('Data/CIE_cmfs_360-830_x_1.yml'))->[0];

	# for each wavelength (360 - 830 nm)
	for my $i (0 .. 470) {
		
		# compute black body reflectance
		$b->[$i] = bbrad($i + 360, $T);
		
	}

	# compute colorimetry
	$X = dotProduct($cmf->{'CIE1931x'}, $b);
	$Y = dotProduct($cmf->{'CIE1931y'}, $b);
	$Z = dotProduct($cmf->{'CIE1931z'}, $b);

	# compute denominator
	($d = $X + $Y + $Z) || croak('X + Y + Z = 0 when computing chromaticity');

	# return x,y
	return($X/$d, $Y/$d);

}

# compute UCS 1960 values of black body radiator
# parameter: (temperature)
# returns: (u, v)
sub bbuv {

	# get temperature
	my $T = shift();

	# local variables
	my ($b, $X, $Y, $Z, $d);

	# load CIE color matching functions (YAML format)
	state $cmf = YAML::Tiny->read(getICCPath('Data/CIE_cmfs_360-830_x_1.yml'))->[0];

	# for each wavelength (360 - 830 nm)
	for my $i (0 .. 470) {
		
		# compute black body reflectance
		$b->[$i] = bbrad($i + 360, $T);
		
	}

	# compute colorimetry
	$X = dotProduct($cmf->{'CIE1931x'}, $b);
	$Y = dotProduct($cmf->{'CIE1931y'}, $b);
	$Z = dotProduct($cmf->{'CIE1931z'}, $b);

	# compute denominator
	($d = $X + 15 * $Y + 3 * $Z) || croak('X + 15Y + 3Z = 0 when computing UCS values');

	# return u,v
	return(4 * $X/$d, 6 * $Y/$d);

}

# convert XYZ to UCS 1960
# used to compute color differences for CCT
# parameters: (X, Y, Z)
# returns: (u, v)
sub XYZ2ucs {

	# get parameters
	my ($X, $Y, $Z) = @_;

	# compute denominator
	(my $d = $X + 15 * $Y + 3 * $Z) || croak('X + 15Y + 3Z = 0 when computing UCS values');

	# return u,v
	return(4 * $X/$d, 6 * $Y/$d);

}

# convert chromaticity to UCS 1960
# used to compute color differences for CCT
# parameters: (x, y)
# returns: (u, v)
sub xy2ucs {

	# get parameters
	my ($x, $y) = @_;

	# denominator
	(my $d = 12 * $y - 2 * $x + 3) || croak('12Y - 2X + 3 = 0 when computing UCS values');

	# return u,v
	return(4 * $x/$d, 6 * $y/$d);

}

# compute daylight SPD
# parameter: (color_temperature)
# returns: (range, SPD_vector)
sub daylight {

	# get parameter
	my $cct = shift();

	# local variables
	my ($range, $spd, $xD, $yD, $M1, $M2);
	
	# verify color temperature
	($cct >= 4000 && $cct <= 25000) || croak('CCT must be between 4000˚K and 25000˚K');

	# load CIE daylight Eigenvectors (YAML format)
	state $eigen = YAML::Tiny->read(getICCPath('Data/CIE_daylight_300-830_x_5.yml'))->[0];

	# set range
	$range = [300, 830, 5];
	
	# if CCT > 7000
	if ($cct > 7000) {
		
		# compute x value
		$xD = -2.0064e9/$cct**3 + 1.9018e6/$cct**2 + 0.24748e3/$cct + 0.23704;
		
	} else {
		
		# compute x value
		$xD = -4.6070e9/$cct**3 + 2.9678e6/$cct**2 + 0.09911e3/$cct + 0.244063;
		
	}

	# compute y value
	$yD = -3.000 * $xD**2 + 2.870 * $xD - 0.275;

	# compute M1
	$M1 = (-1.3515 - 1.7703 * $xD + 5.9114 * $yD)/(0.0241 + 0.2562 * $xD - 0.7341 * $yD);

	# compute M2
	$M2 = (0.0300 - 31.4424 * $xD + 30.0717 * $yD)/(0.0241 + 0.2562 * $xD - 0.7341 * $yD);

	# for each wavelength
	for my $i (0 .. 106) {
		
		# compute spectral power
		$spd->[$i] = $eigen->{'CIE_S0'}->[$i] + $M1 * $eigen->{'CIE_S1'}->[$i] + $M2 * $eigen->{'CIE_S2'}->[$i];
		
	}

	# return
	return($range, $spd);

}

#--------- interpolation functions ---------

# linear interpolation function
# interpolates and/or extrapolates equally spaced data
# input/output range structure: [start_nm, end_nm, increment]
# optional extrapolation method is 'copy' or 'linear', none returns zeros
# parameters: (input_vector, input_range, output_range, [extrapolation_method])
# returns: (output_vector)
sub linear {

	# get parameters
	my ($vector_in, $range_in, $range_out, $ext) = @_;

	# local variables
	my ($ix, $ox, $w, $vector_out, $t, $low);

	# verify input vector size
	(($ix = $#{$vector_in}) > 0) || croak('input vector must contain two or more elements');

	# verify input range
	(abs($ix * $range_in->[2] - $range_in->[1] + $range_in->[0]) < 1E-12 && $range_in->[2] > 0) || croak('invalid input range');

	# compute output upper index from range
	(($ox = round(($range_out->[1] - $range_out->[0])/$range_out->[2])) > 0) || croak('output upper index must be > 0');

	# verify output range
	(abs($ox * $range_out->[2] - $range_out->[1] + $range_out->[0]) < 1E-12 && $range_out->[2] > 0) || croak('invalid output range');

	# for each output vector element
	for my $i (0 .. $ox) {
		
		# compute wavelength
		$w = $range_out->[0] + $i * $range_out->[2];
		
		# if wavelength < start of source
		if ($w < $range_in->[0]) {
			
			# if extrapolation defined
			if (defined($ext)) {
				
				# if linear extrapolation
				if ($ext eq 'linear') {
					
					# compute ratio
					$t = ($w - $range_in->[0])/$range_in->[2];
					
					# extrapolate
					$vector_out->[$i] = (1 - $t) * $vector_in->[0] + $t * $vector_in->[1];
					
				# if copy extrapolation
				} elsif ('copy') {
					
					# set element to first knot
					$vector_out->[$i] = $vector_in->[0];
					
				} else {
					
					# error
					croak('invalid extrapolation type');
					
				}
				
			} else {
				
				# set element to 0
				$vector_out->[$i] = 0;
				
			}
			
		# if wavelength > end of source
		} elsif ($w > $range_in->[1]) {
			
			# if extrapolation defined
			if (defined($ext)) {
				
				# if linear extrapolation
				if ($ext eq 'linear') {
					
					# compute ratio
					$t = ($range_in->[1] - $w)/$range_in->[2];
					
					# extrapolate
					$vector_out->[$i] = (1 - $t) * $vector_in->[-1] + $t * $vector_in->[-2];
					
				# if copy extrapolation
				} elsif ('copy') {
					
					# set element to last knot
					$vector_out->[$i] = $vector_in->[-1];
					
				} else {
					
					# error
					croak('invalid extrapolation type');
					
				}
				
			} else {
				
				# set element to 0
				$vector_out->[$i] = 0;
				
			}
			
		# if wavelength == end of source
		} elsif ($w == $range_in->[1]) {
			
			# set element to last knot
			$vector_out->[$i] = $vector_in->[-1];
			
		} else {
			
			# compute ratio and lower index
			($t, $low) = POSIX::modf(($w - $range_in->[0])/$range_in->[2]);
			
			# if ratio is non-zero
			if ($t) {
				
				# interpolate value
				$vector_out->[$i] = (1 - $t) * $vector_in->[$low] + $t * $vector_in->[$low + 1];
				
			} else {
				
				# use low source value
				$vector_out->[$i] = $vector_in->[$low];
				
			}
			
		}
		
	}

	# return
	return($vector_out);

}

# compute linear interpolation matrix
# input/output range structure: [start_nm, end_nm, increment]
# optional extrapolation method is 'copy' or 'linear', none returns zeros
# parameters: (input_range, output_range, [extrapolation_method])
# returns: (interpolation_matrix)
sub linear_matrix {

	# get parameters
	my ($range_in, $range_out, $ext) = @_;

	# local variables
	my ($ix, $ox, $mat, $w, $low, $t);

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# compute input vector size from range
	$ix = round(($range_in->[1] - $range_in->[0])/$range_in->[2]);

	# verify input range
	($ix > 0 && abs($ix * $range_in->[2] - $range_in->[1] + $range_in->[0]) < 1E-12 && $range_in->[2] > 0) || croak('invalid input range');

	# compute output vector size from range
	$ox = round(($range_out->[1] - $range_out->[0])/$range_out->[2]);

	# verify output range
	($ox > 0 && abs($ox * $range_out->[2] - $range_out->[1] + $range_out->[0]) < 1E-12 && $range_out->[2] > 0) || croak('invalid output range');

	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# make matrix of zeros
		$mat = ICC::Support::Lapack::zeros($ox + 1, $ix + 1);
		
	} else {
		
		# make matrix of zeros
		$mat = [map {[(0) x ($ix + 1)]} (0 .. $ox)];
		
	}

	# for each output
	for my $i (0 .. $ox) {
		
		# compute wavelength
		$w = $range_out->[0] + $i * $range_out->[2];
		
		# if wavelength < start of source
		if ($w < $range_in->[0]) {
			
			# if extrapolation defined
			if (defined($ext)) {
				
				# if linear extrapolation
				if ($ext eq 'linear') {
					
					# compute ratio
					$t = ($w - $range_in->[0])/$range_in->[2];
					
					# set elements to ratio
					$mat->[$i][0] = 1 - $t;
					$mat->[$i][1] = $t;
					
				# if copy extrapolation
				} elsif ('copy') {
					
					# set element to first knot
					$mat->[$i][0] = 1;
					
				} else {
					
					# error
					croak('invalid extrapolation type');
					
				}
				
			}
			
		# if wavelength > end of source
		} elsif ($w > $range_in->[1]) {
			
			# if extrapolation defined
			if (defined($ext)) {
				
				# if linear extrapolation
				if ($ext eq 'linear') {
					
					# compute ratio
					$t = ($range_in->[1] - $w)/$range_in->[2];
					
					# set elements to ratio
					$mat->[$i][$ix - 1] = $t;
					$mat->[$i][$ix] = 1 - $t;
					
				# if copy extrapolation
				} elsif ('copy') {
					
					# set element to last knot
					$mat->[$i][$ix] = 1;
					
				} else {
					
					# error
					croak('invalid extrapolation type');
					
				}
				
			}
			
		# if wavelength == end of source
		} elsif ($w == $range_in->[1]) {
			
			# set element to last knot
			$mat->[$i][$ix] = 1;
			
		} else {
			
			# compute ratio and lower index
			($t, $low) = POSIX::modf(($w - $range_in->[0])/$range_in->[2]);
			
			# set elements to ratio
			$mat->[$i][$low + 1] = $t;
			$mat->[$i][$low] = 1 - $t;
			
		}
		
	}

	# return
	return(bless($mat, 'Math::Matrix'));

}

# cubic spline interpolation function
# interpolates and/or extrapolates equally spaced data
# input/output range structure: [start_nm, end_nm, increment]
# optional extrapolation method is 'copy' or 'linear', none returns zeros
# parameters: (input_vector, input_range, output_range, [extrapolation_method])
# returns: (output_vector)
sub cspline {

	# get parameters
	my ($vector_in, $range_in, $range_out, $ext) = @_;

	# local variables
	my ($ix, $ox, $mat, $derv, $info, $w, $vector_out);
	my ($low, $t, $tc, $h00, $h01, $h10, $h11);

	# verify input vector size
	(($ix = $#{$vector_in}) > 0) || croak('input vector must contain two or more elements');

	# verify input range
	(abs($ix * $range_in->[2] - $range_in->[1] + $range_in->[0]) < 1E-12 && $range_in->[2] > 0) || croak('invalid input range');

	# compute output upper index from range
	(($ox = round(($range_out->[1] - $range_out->[0])/$range_out->[2])) > 0) || croak('output upper index must be > 0');

	# verify output range
	(abs($ox * $range_out->[2] - $range_out->[1] + $range_out->[0]) < 1E-12 && $range_out->[2] > 0) || croak('invalid output range');

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# for each input element
		for my $i (0 .. $ix) {
			
			# compute rhs (3 * (y[i+1] - y[i-1]))
			$mat->[$i][0] = 3 * ($vector_in->[$i + 1 > $ix ? $ix : $i + 1] - $vector_in->[$i - 1 < 0 ? 0 : $i - 1]);
			
		}
		
		# solve for derivative matrix
		($info, $derv) = ICC::Support::Lapack::trisolve([(1) x $ix], [2, (4) x ($ix - 1), 2], [(1) x $ix], $mat);
		
	# otherwise, use Math::Matrix package (slow)
	} else {
		
		# make tri-diagonal matrix object
		$mat = Math::Matrix->tridiagonal([2, (4) x ($ix - 1), 2]);
		
		# for each input element
		for my $i (0 .. $ix) {
			
			# append rhs (3 * (y[i+1] - y[i-1]))
			$mat->[$i][$ix + 1] = 3 * ($vector_in->[$i + 1 > $ix ? $ix : $i + 1] - $vector_in->[$i - 1 < 0 ? 0 : $i - 1]);
			
		}
		
		# solve for derivative matrix
		$derv = $mat->solve();
		
	}

	# for each output vector element
	for my $i (0 .. $ox) {
		
		# compute wavelength
		$w = $range_out->[0] + $i * $range_out->[2];
		
		# if wavelength < start of source
		if ($w < $range_in->[0]) {
			
			# if extrapolation defined
			if (defined($ext)) {
				
				# if linear extrapolation
				if ($ext eq 'linear') {
					
					# set element to linear value
					$vector_out->[$i] = $vector_in->[0] + $derv->[0][0] * ($w - $range_in->[0])/$range_in->[2];
				
				# if copy extrapolation
				} elsif ('copy') {
					
					# set element to first knot
					$vector_out->[$i] = $vector_in->[0];
					
				} else {
					
					# error
					croak('invalid extrapolation type');
					
				}
				
			} else {
				
				# set element to 0
				$vector_out->[$i] = 0;
				
			}
			
		# if wavelength > end of source
		} elsif ($w > $range_in->[1]) {
			
			# if extrapolation defined
			if (defined($ext)) {
				
				# if linear extrapolation
				if ($ext eq 'linear') {
					
					# set element to linear value
					$vector_out->[$i] = $vector_in->[-1] + $derv->[-1][0] * ($w - $range_in->[1])/$range_in->[2];
				
				# if copy extrapolation
				} elsif ('copy') {
					
					# set element to last knot
					$vector_out->[$i] = $vector_in->[-1];
					
				} else {
					
					# error
					croak('invalid extrapolation type');
					
				}
				
			} else {
				
				# set element to 0
				$vector_out->[$i] = 0;
				
			}
			
		# if wavelength == end of source
		} elsif ($w == $range_in->[1]) {
			
			# set element to last knot
			$vector_out->[$i] = $vector_in->[-1];
			
		} else {
			
			# compute ratio and lower index
			($t, $low) = POSIX::modf(($w - $range_in->[0])/$range_in->[2]);
			
			# if ratio is non-zero
			if ($t) {
				
				# if ICC::Support::Lapack module is loaded
				if ($lapack) {
					
					# interpolate value
					$vector_out->[$i] = ICC::Support::Lapack::hermite($t, $vector_in->[$low], $vector_in->[$low + 1], $derv->[$low][0], $derv->[$low + 1][0]);
					
				} else {
					
					# compute Hermite coefficients
					$tc = 1 - $t;
					$h00 = (1 + 2 * $t) * $tc * $tc;
					$h01 = 1 - $h00;
					$h10 = $t * $tc * $tc;
					$h11 = -$t * $t * $tc;
					
					# interpolate value
					$vector_out->[$i] = $h00 * $vector_in->[$low] + $h01 * $vector_in->[$low + 1] + $h10 * $derv->[$low][0] + $h11 * $derv->[$low + 1][0];
					
				}
				
			} else {
				
				# use lower source value
				$vector_out->[$i] = $vector_in->[$low];
				
			}
			
		}
		
	}

	# return
	return($vector_out);

}

# compute cubic spline interpolation matrix
# input/output range structure: [start_nm, end_nm, increment]
# optional extrapolation method is 'copy' or 'linear', none returns zeros
# parameters: (input_range, output_range, [extrapolation_method])
# returns: (interpolation_matrix)
sub cspline_matrix {

	# get parameters
	my ($range_in, $range_out, $ext) = @_;

	# local variables
	my ($ix, $ox, $rhs, $info, $derv, $mat);
	my ($w, $low, $t, $tc, $h00, $h01, $h10, $h11);

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# compute input vector size from range
	$ix = round(($range_in->[1] - $range_in->[0])/$range_in->[2]);

	# verify input range
	($ix > 0 && abs($ix * $range_in->[2] - $range_in->[1] + $range_in->[0]) < 1E-12 && $range_in->[2] > 0) || croak('invalid input range');

	# compute output vector size from range
	$ox = round(($range_out->[1] - $range_out->[0])/$range_out->[2]);

	# verify output range
	($ox > 0 && abs($ox * $range_out->[2] - $range_out->[1] + $range_out->[0]) < 1E-12 && $range_out->[2] > 0) || croak('invalid output range');

	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# make rhs matrix (filled with zeros)
		$rhs = ICC::Support::Lapack::zeros($ix + 1);
		
		# for each row
		for my $i (1 .. $ix - 1) {
			
			# set diagonal values
			$rhs->[$i - 1][$i] = 3;
			$rhs->[$i + 1][$i] = -3;
			
		}
		
		# set endpoint values
		$rhs->[0][0] = -3;
		$rhs->[1][0] = -3;
		$rhs->[$ix][$ix] = 3;
		$rhs->[$ix - 1][$ix] = 3;
		
		# solve for derivative matrix
		($info, $derv) = ICC::Support::Lapack::trisolve([(1) x $ix], [2, (4) x ($ix - 1), 2], [(1) x $ix], $rhs);
		
		# make matrix of zeros
		$mat = ICC::Support::Lapack::zeros($ox + 1, $ix + 1);
		
	# otherwise, use Math::Matrix package (slow)
	} else {
		
		# make rhs matrix (fill with zeros)
		$rhs = bless([map {[(0) x ($ix + 1)]} (0 .. $ix)], 'Math::Matrix');
		
		# for each row
		for my $i (1 .. $ix - 1) {
			
			# set diagonal values
			$rhs->[$i - 1][$i] = 3;
			$rhs->[$i + 1][$i] = -3;
			
		}
		
		# set endpoint values
		$rhs->[0][0] = -3;
		$rhs->[1][0] = -3;
		$rhs->[$ix][$ix] = 3;
		$rhs->[$ix - 1][$ix] = 3;
		
		# solve for derivative matrix
		$derv = Math::Matrix->tridiagonal([2, (4) x ($ix - 1), 2])->concat($rhs)->solve();
		
		# make matrix of zeros
		$mat = [map {[(0) x ($ix + 1)]} (0 .. $ox)];
		
	}

	# for each output
	for my $i (0 .. $ox) {
		
		# compute wavelength
		$w = $range_out->[0] + $i * $range_out->[2];
		
		# if wavelength < start of source
		if ($w < $range_in->[0]) {
			
			# if extrapolation defined
			if (defined($ext)) {
				
				# if linear extrapolation
				if ($ext eq 'linear') {
					
					# compute ratio
					$t = ($w - $range_in->[0])/$range_in->[2];
					
					# for each input
					for my $j (0 .. $ix) {
						
						# set element to linear value
						$mat->[$i][$j] = ($j == 0 ? 1 : 0) + $derv->[0][$j] * $t;
						
					}
					
				# if copy extrapolation
				} elsif ('copy') {
					
					# set element to first knot
					$mat->[$i][0] = 1;
					
				} else {
					
					# error
					croak('invalid extrapolation type');
					
				}
				
			}
			
		# if wavelength > end of source
		} elsif ($w > $range_in->[1]) {
			
			# if extrapolation defined
			if (defined($ext)) {
				
				# if linear extrapolation
				if ($ext eq 'linear') {
					
					# compute ratio
					$t = ($w - $range_in->[1])/$range_in->[2];
					
					# for each input
					for my $j (0 .. $ix) {
						
						# set element to linear value
						$mat->[$i][$j] = ($j == $ix ? 1 : 0) + $derv->[-1][$j] * $t;
						
					}
					
				# if copy extrapolation
				} elsif ('copy') {
					
					# set element to last knot
					$mat->[$i][$ix] = 1;
					
				} else {
					
					# error
					croak('invalid extrapolation type');
					
				}
				
			}
			
		# if wavelength == end of source
		} elsif ($w == $range_in->[1]) {
			
			# set element to last knot
			$mat->[$i][$ix] = 1;
			
		} else {
			
			# compute ratio and lower index
			($t, $low) = POSIX::modf(($w - $range_in->[0])/$range_in->[2]);
			
			# if ratio is non-zero
			if ($t) {
				
				# if ICC::Support::Lapack module is loaded
				if ($lapack) {
					
					# for each input
					for my $j (0 .. $ix) {
						
						# interpolate value
						$mat->[$i][$j] = ICC::Support::Lapack::hermite($t, ($low == $j ? 1 : 0), ($low + 1 == $j ? 1 : 0), $derv->[$low][$j], $derv->[$low + 1][$j]);
						
					}
					
				} else {
					
					# for each input
					for my $j (0 .. $ix) {
						
						# compute Hermite coefficients
						$tc = 1 - $t;
						$h00 = (1 + 2 * $t) * $tc * $tc;
						$h01 = 1 - $h00;
						$h10 = $t * $tc * $tc;
						$h11 = -$t * $t * $tc;
						
						# interpolate partial derivative value
						$mat->[$i][$j] = $h00 * ($low == $j ? 1 : 0) + $h01 * ($low + 1 == $j ? 1 : 0) + $h10 * $derv->[$low][$j] + $h11 * $derv->[$low + 1][$j];
						
					}
					
				}
			
			} else {
				
				# set to one
				$mat->[$i][$low] = 1;
				
			}
			
		}
		
	}

	# return
	return(bless($mat, 'Math::Matrix'));

}

# Lagrange interpolation function (ASTM E 2022)
# interpolates and/or extrapolates equally spaced data
# input/output range structure: [start_nm, end_nm, increment]
# optional extrapolation method is 'copy' or 'linear', none returns zeros
# parameters: (input_vector, input_range, output_range, [extrapolation_method])
# returns: (output_vector)
sub lagrange {

	# get parameters
	my ($vector_in, $range_in, $range_out, $ext) = @_;

	# local variables
	my ($ix, $ox, $w, $vector_out, $t, $low);

	# verify input vector size
	(($ix = $#{$vector_in}) > 0) || croak('input vector must contain two or more elements');

	# verify input range
	(abs($ix * $range_in->[2] - $range_in->[1] + $range_in->[0]) < 1E-12 && $range_in->[2] > 0) || croak('invalid input range');

	# compute output upper index from range
	(($ox = round(($range_out->[1] - $range_out->[0])/$range_out->[2])) > 0) || croak('output upper index must be > 0');

	# verify output range
	(abs($ox * $range_out->[2] - $range_out->[1] + $range_out->[0]) < 1E-12 && $range_out->[2] > 0) || croak('invalid output range');

	# for each output vector element
	for my $i (0 .. $ox) {
		
		# compute wavelength
		$w = $range_out->[0] + $i * $range_out->[2];
		
		# if wavelength < start of source
		if ($w < $range_in->[0]) {
			
			# if extrapolation defined
			if (defined($ext)) {
				
				# if linear extrapolation
				if ($ext eq 'linear') {
					
					# compute ratio
					$t = ($range_in->[0] - $w)/$range_in->[2];
					
					# compute extrapolated value
					$vector_out->[$i] = (1 + 3 * $t/2) * $vector_in->[0];
					$vector_out->[$i] += -2 * $t * $vector_in->[1];
					$vector_out->[$i] += $t * $vector_in->[2]/2;
					
				# if copy extrapolation
				} elsif ('copy') {
					
					# set element to first knot
					$vector_out->[$i] = $vector_in->[0];
					
				} else {
					
					# error
					croak('invalid extrapolation type');
					
				}
				
			} else {
				
				# set element to 0
				$vector_out->[$i] = 0;
				
			}
			
		# if wavelength > end of source
		} elsif ($w > $range_in->[1]) {
			
			# if extrapolation defined
			if (defined($ext)) {
				
				# if linear extrapolation
				if ($ext eq 'linear') {
					
					# compute ratio
					$t = ($w - $range_in->[1])/$range_in->[2];
					
					# compute extrapolated value
					$vector_out->[$i] = (1 + 3 * $t/2) * $vector_in->[$ix];
					$vector_out->[$i] += -2 * $t * $vector_in->[$ix - 1];
					$vector_out->[$i] += $t * $vector_in->[$ix - 2]/2;
					
				# if copy extrapolation
				} elsif ('copy') {
					
					# set element to last knot
					$vector_out->[$i] = $vector_in->[-1];
					
				} else {
					
					# error
					croak('invalid extrapolation type');
					
				}
				
			} else {
				
				# set element to 0
				$vector_out->[$i] = 0;
				
			}
			
		# if wavelength == end of source
		} elsif ($w == $range_in->[1]) {
			
			# set element to last knot
			$vector_out->[$i] = $vector_in->[-1];
			
		} else {
			
			# compute ratio and lower index
			($t, $low) = POSIX::modf(($w - $range_in->[0])/$range_in->[2]);
			
			# if ratio is zero
			if ($t == 0) {
				
				# set element to low knot
				$vector_out->[$i] = $vector_in->[$low];
				
			# quadratic Lagrange interpolation (lower)
			} elsif ($low == 0) {
				
				# compute Lagrange quadratic interpolated value
				$vector_out->[$i] = ($t - 1) * ($t - 2) * $vector_in->[0]/2;
				$vector_out->[$i] += -$t * ($t - 2) * $vector_in->[1];
				$vector_out->[$i] += ($t - 1) * $t * $vector_in->[2]/2;
				
			# quadratic Lagrange interpolation (upper)
			} elsif ($low == $ix - 1) {
				
				# complement ratio
				$t = 1 - $t;
				
				# compute Lagrange quadratic interpolated value
				$vector_out->[$i] = ($t - 1) * ($t - 2) * $vector_in->[$ix]/2;
				$vector_out->[$i] += -$t * ($t - 2) * $vector_in->[$ix - 1];
				$vector_out->[$i] += ($t - 1) * $t * $vector_in->[$ix - 2]/2;
				
			# cubic Lagrange interpolation
			} else {
				
				# increment ratio
				$t = 1 + $t;
				
				# compute Lagrange cubic interpolated value
				$vector_out->[$i] = ($t - 1) * ($t - 2) * ($t - 3) * $vector_in->[$low - 1]/-6;
				$vector_out->[$i] += $t * ($t - 2) * ($t - 3) * $vector_in->[$low]/2;
				$vector_out->[$i] += ($t - 1) * $t * ($t - 3) * $vector_in->[$low + 1]/-2;
				$vector_out->[$i] += ($t - 1) * ($t - 2) * $t * $vector_in->[$low + 2]/6;
				
			}
			
		}
		
	}

	# return
	return($vector_out);

}

# compute Lagrange interpolation matrix (ASTM E 2022)
# input/output range structure: [start_nm, end_nm, increment]
# optional extrapolation method is 'copy' or 'linear', none returns zeros
# parameters: (input_range, output_range, [extrapolation_method])
# returns: (interpolation_matrix)
sub lagrange_matrix {

	# get parameters
	my ($range_in, $range_out, $ext) = @_;

	# local variables
	my ($ix, $ox, $mat, $w, $low, $t);

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# compute input vector size from range
	$ix = round(($range_in->[1] - $range_in->[0])/$range_in->[2]);

	# verify input range
	($ix > 0 && abs($ix * $range_in->[2] - $range_in->[1] + $range_in->[0]) < 1E-12 && $range_in->[2] > 0) || croak('invalid input range');

	# compute output vector size from range
	$ox = round(($range_out->[1] - $range_out->[0])/$range_out->[2]);

	# verify output range
	($ox > 0 && abs($ox * $range_out->[2] - $range_out->[1] + $range_out->[0]) < 1E-12 && $range_out->[2] > 0) || croak('invalid output range');

	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# make matrix of zeros
		$mat = ICC::Support::Lapack::zeros($ox + 1, $ix + 1);
		
	} else {
		
		# make matrix of zeros
		$mat = [map {[(0) x ($ix + 1)]} (0 .. $ox)];
		
	}

	# for each output
	for my $i (0 .. $ox) {
		
		# compute wavelength
		$w = $range_out->[0] + $i * $range_out->[2];
		
		# if wavelength < start of source
		if ($w < $range_in->[0]) {
			
			# if extrapolation defined
			if (defined($ext)) {
				
				# if linear extrapolation
				if ($ext eq 'linear') {
					
					# compute ratio
					$t = ($range_in->[0] - $w)/$range_in->[2];
					
					# set matrix elements
					$mat->[$i][0] = 1 + 3 * $t/2;
					$mat->[$i][1] = -2 * $t;
					$mat->[$i][2] = $t/2;
					
				# if copy extrapolation
				} elsif ('copy') {
					
					# set element to first knot
					$mat->[$i][0] = 1;
					
				} else {
					
					# error
					croak('invalid extrapolation type');
					
				}
				
			}
			
		# if wavelength > end of source
		} elsif ($w > $range_in->[1]) {
			
			# if extrapolation defined
			if (defined($ext)) {
				
				# if linear extrapolation
				if ($ext eq 'linear') {
					
					# compute ratio
					$t = ($w - $range_in->[1])/$range_in->[2];
					
					# set matrix elements
					$mat->[$i][$ix] = 1 + 3 * $t/2;
					$mat->[$i][$ix - 1] = -2 * $t;
					$mat->[$i][$ix - 2] = $t/2;
					
				# if copy extrapolation
				} elsif ('copy') {
					
					# set element to last knot
					$mat->[$i][$ix] = 1;
					
				} else {
					
					# error
					croak('invalid extrapolation type');
					
				}
				
			}
			
		# if wavelength == end of source
		} elsif ($w == $range_in->[1]) {
			
			# set element to last knot
			$mat->[$i][$ix] = 1;
			
		} else {
			
			# compute ratio and lower index
			($t, $low) = POSIX::modf(($w - $range_in->[0])/$range_in->[2]);
			
			# if ratio is zero
			if ($t == 0) {
				
				# set element to low knot
				$mat->[$i][$low] = 1;
				
			# quadratic Lagrange interpolation (lower)
			} elsif ($low == 0) {
				
				# compute Lagrange quadratic interpolation coefficients
				$mat->[$i][0] = ($t - 1) * ($t - 2)/2;
				$mat->[$i][1] = -$t * ($t - 2);
				$mat->[$i][2] = ($t - 1) * $t/2;
				
			# quadratic Lagrange interpolation (upper)
			} elsif ($low == $ix - 1) {
				
				# complement ratio
				$t = 1 - $t;
				
				# compute Lagrange quadratic interpolation coefficients
				$mat->[$i][$ix] = ($t - 1) * ($t - 2)/2;
				$mat->[$i][$ix - 1] = -$t * ($t - 2);
				$mat->[$i][$ix - 2] = ($t - 1) * $t/2;
				
			# cubic Lagrange interpolation
			} else {
				
				# increment ratio
				$t = 1 + $t;
				
				# compute Lagrange cubic interpolation coefficients
				$mat->[$i][$low - 1] = ($t - 1) * ($t - 2) * ($t - 3)/-6;
				$mat->[$i][$low] = $t * ($t - 2) * ($t - 3)/2;
				$mat->[$i][$low + 1] = ($t - 1) * $t * ($t - 3)/-2;
				$mat->[$i][$low + 2] = ($t - 1) * ($t - 2) * $t/6;
				
			}
			
		}
		
	}

	# return
	return(bless($mat, 'Math::Matrix'));

}

#--------- vector functions ---------

# compute vector dot product
# parameters: (vector_1, vector_2)
# vectors must have equal dimensions
# returns: (dot_product)
sub dotProduct {

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# return dot product
		return(ICC::Support::Lapack::dot(@_));
		
	} else {
		
		# verify vector sizes match
		($#{$_[0]} == $#{$_[1]}) || croak('vector size mismatch');
		
		# initialize sum
		my $sum = 0;
		
		# for each pair of array elements
		for (0 .. $#{$_[0]}) {
			
			# accumulate product
			$sum += $_[0][$_] * $_[1][$_];
			
		}
		
		# return dot product
		return($sum);
		
	}
	
}

# compute vector cross product
# parameters: (vector_1, vector_2)
# vectors must be three-dimensional
# returns: (cross_product_vector)
sub crossProduct {

	# verify vectors are three-dimensional
	($#{$_[0]} == 2 && $#{$_[1]} == 2) || croak('vectors not three-dimensional');

	# return cross product
	return([$_[0][1] * $_[1][2] - $_[0][2] * $_[1][1], $_[0][2] * $_[1][0] - $_[0][0] * $_[1][2], $_[0][0] * $_[1][1] - $_[0][1] * $_[1][0]]);

}

#--------- utility functions ---------

# flatten slice
# input is a reference to a structure consisting of scalars, arrays or Math::Matrix objects.
# flatten converts the structure to a reference to an array of scalars.
# parameters: (ref_to_slice_structure)
# returns: (reference_to_flattened_slice)
sub flatten {

	# local variables
	my (@out);

	# while input array
	while (@_) {
		
		# shift input value
		my $v = shift();
		
		# if undefined
		if (! defined($v)) {
			
			# warn
			carp('slice contains undefined value');
			
		# if scalar
		} elsif (! ref($v)) {
			
			# push on output
			push(@out, $v);
			
		# if array reference or Math::Matrix object
		} elsif (ref($v) eq 'ARRAY' || UNIVERSAL::isa($v, 'Math::Matrix')) {
			
			# dereference and push on input
			push(@_, @{$v});
			
		} else {
			
			# error
			croak('illegal slice structure');
			
		}
		
	}

	# return reference to flattened slice
	return(\@out);

}

# recursive clipping function
# for a structure containing scalars and arrays
# clips scalar elements < 0.0 or > 1.0
# parameter: (structure_ref)
sub clip_struct {

	# if an array reference
	if (ref($_[0]) eq 'ARRAY') {
		
		# for each array element
		for (@{$_[0]}) {
			
			# if a reference
			if (ref()) {
				
				# call myself
				clip($_)
				
			} else {
				
				# clip scalar
				$_ = 0.0 if ($_ < 0.0);
				$_ = 1.0 if ($_ > 1.0);
				
			}
			
		}
		
	} else {
		
		# error
		croak('error clipping structure');
		
	}
	
}

# round off number to nearest integer
# parameter: (numeric_value)
# returns: (integer_value)
sub round {

	# return rounded value
	$_[0] > 0 ? int($_[0] + 0.5) : int($_[0] - 0.5)

}

# convert array of s15Fixed16Number values to numeric
# parameters: (input_array)
# returns: (converted_array)
sub s15f162v {

	# get parameters
	my (@in) = @_;

	# return converted array
	return(map {($_ & 0x80000000) ? $_/65536 - 65536 : $_/65536} @in);

}

# convert array of numeric values to s15Fixed16Number
# parameters: (input_array)
# returns: (converted_array)
sub v2s15f16 {

	# get parameters
	my (@in) = @_;

	# return converted array
	return(map {($_ < 0) ? ($_ + 65536) * 65536 : $_ * 65536} @in);

}

# make profile folder
# makes '~profiles' folder, and an alias
# default alias folder is '~/Library/ColorSync/Profiles/'
# customer and/or job will be undefined if not in path
# parameters: (file/folder_path, [alias_folder_path])
# returns: (profiles_folder_path, directory_segs, customer, job)
sub makeProfileFolder {

	# get parameters
	my ($path, $alias) = @_;

	# local variables
	my ($vol, $dir, $file, @dsegs, $dref);
	my (@jobs, $i, $cust, $job, $folder, $sym);

	# verify parameter is a valid path
	(-e $path) || croak('invalid path parameter');

	# split the absolute path (note use of 'no_file' flag)
	($vol, $dir, $file) = File::Spec->splitpath(File::Spec->rel2abs($path), -d $path);

	# split directory into segments
	@dsegs = File::Spec->splitdir($dir);

	# remove any trailing path delimiters
	while (@dsegs > 1 && $dsegs[-1] eq '') {pop(@dsegs)};
	
	# make copy of directory segments array
	$dref = [@dsegs];

	# find indices of 'jobs' directory segments (if any)
	@jobs = grep {lc($dsegs[$_]) eq 'jobs'} (0 .. $#dsegs);

	# if customer directory segment exists
	if (@jobs && ($i = $jobs[0] + 1) <= $#dsegs) {
		
		# set customer
		$cust = $dsegs[$i];
		
		# replace spaces with underscores
		$cust =~ s/ /_/g;
		
	}

	# if job number directory segment exists
	if (@jobs && ($i = $jobs[0] + 2) <= $#dsegs) {
		
		# match job number
		if ($dsegs[$i] =~ m/^(\d+)/) {
			
			# set job number
			$job = $1;
			
		} else {
			
			# set job number to segment
			$job = $dsegs[$i];
			
			# replace spacer with underscores
			$job =~ s/ /_/g;
			
		}
		
		# truncate directory segments array
		splice(@dsegs, $i + 1);
		
	}

	# add '~profiles' segment
	push(@dsegs, '~profiles');

	# join directory segments
	$dir = File::Spec->catdir(@dsegs);

	# make profile folder path
	$folder = File::Spec->catpath($vol, $dir, '');

	# make profile folder
	mkdir($folder) if (! -d $folder);

	# make profile folder alias name (note colons appear as '/' in OS X paths)
	$sym = 'alias_to_' . join(':', @dsegs);

	# if alias parameter provided
	if (defined($alias)) {
		
		# verify a valid directory
		(-d $alias) || croak('invalid alias parameter');
		
		# append alias folder name
		$alias .= "/$sym";
		
	} else {
		
		# append alias folder name
		$alias =  "$ENV{'HOME'}/Library/ColorSync/Profiles/$sym";
		
	}

	# make profile folder alias (Unix symbolic link)
	symlink($folder, $alias) if (! -d $alias);

	# return
	return($folder, $dref, $cust, $job);

}

# get distribution 'ICC' path
# optional parameter is appended to path
# parameter: ([file/folder])
# returns: (path)
sub getICCPath {

	# get path to this module
	my $path = $INC{'ICC/Shared.pm'};

	# if file/folder name supplied
	if (@_) {
		
		# replace module file name
		$path =~ s/Shared.pm$/$_[0]/;
		
	} else {
		
		# remove module file name
		$path =~ s/Shared.pm$//;
		
	}

	# return path (may be invalid)
	return($path);

}

# filter file path
# converts '~' to user home
# removes '\' characters
# parameter: (file_path)
sub filterPath {

	# replace '~'
	$_[0] =~ s/^~/$ENV{'HOME'}/;

	# remove '\'
	$_[0] =~ s/\\//g;

}

# set Mac OSX file creator and type
# calls the 'SetFile' utility, if present
# parameters: (file_path, creator, type)
sub setFile {

	# get parameters
	my ($path, $creator, $type) = @_;

	# filter file path
	filterPath($path);

	# escape spaces and special characters
	$path =~ s/([^\w\-\/+.@])/\\$1/g;

	# if SetFile in /usr/bin directory
	if (-f '/usr/bin/Setfile') {
		
		# make system call
		qx(/usr/bin/Setfile -c $creator -t $type $path);
		
	# if SetFile in /Developer/usr/bin directory
	} elsif (-f '/Developer/usr/bin/SetFile') {
		
		# make system call
		qx(/Developer/usr/bin/SetFile -c $creator -t $type $path);
		
	}

}

#--------- internal functions ---------

# convert structure (3 parameters)
# parameters: (input_array -or- input_structure, subroutine_reference)
# returns: (output_array -or- output_structure)
sub _convert3 {

	# get subroutine code reference
	my ($sub) = pop();

	# if valid array input (3 scalars)
	if (@_ == 3 && 3 == grep {! ref()} @_) {
		
		# call subroutine (passing @_)
		&$sub;
		
	# if valid structure input (array_ref -or- Math::Matrix object
	} elsif (@_ == 1 && (ref($_[0]) eq 'ARRAY' || UNIVERSAL::isa($_[0], 'Math::Matrix'))) {
		
		# process structure
		_crawl($_[0], my $out = [], $sub);
		
		# bless output array if input a Math::Matrix object
		bless($out, 'Math::Matrix') if (UNIVERSAL::isa($_[0], 'Math::Matrix'));
		
		# return output
		return($out);
		
	} else {
		
		# error
		croak('invalid input structure');
		
	}
	
}

# convert structure (4 parameters)
# parameters: (input_array -or- input_structure, subroutine_reference)
# returns: (output_array -or- output_structure)
sub _convert4 {

	# get subroutine code reference
	my ($sub) = pop(@_);

	# get white point vector (input_structure)
	my $wtpt = (@_ == 2) ? pop() : D50;
	
	# push D50 white point vector, if none (input_array)
	push(@_, D50) if (@_ == 3);

	# if valid array input (3 scalars and white point vector)
	if (@_ == 4 && ref($_[3]) eq 'ARRAY' && 3 == grep {! ref()} @_) {
		
		# call subroutine (passing @_)
		&$sub;
		
	# if valid structure input (array_ref -or- Math::Matrix object)
	} elsif (@_ == 1 && (ref($_[0]) eq 'ARRAY' || UNIVERSAL::isa($_[0], 'Math::Matrix'))) {
		
		# process structure
		_crawl($_[0], my $out = [], $sub, $wtpt);
		
		# bless output array if input a Math::Matrix object
		bless($out, 'Math::Matrix') if (UNIVERSAL::isa($_[0], 'Math::Matrix'));
		
		# return output
		return($out);
		
	} else {
		
		# error
		croak('invalid input structure');
		
	}
	
}

# process structure
# recursive subroutine
# parameters: (input_structure, output_structure, subroutine_reference, [white_point_vector])
sub _crawl {

	# get parameters
	my ($in, $out, $sub, $wtpt) = @_;

	# if input a reference to an array of 3 scalars
	if (@{$in} == 3 && 3 == grep {! ref()} @{$in}) {
		
		# call subroutine
		@{$out} = &$sub(@{$in}, $wtpt);
		
	# if input a reference to an array of array references
	} elsif (@{$in} == grep {ref() eq 'ARRAY'} @{$in}) {
		
		# for each array reference
		for my $i (0 .. $#{$in}) {
			
			# process next level
			_crawl($in->[$i], $out->[$i] = [], $sub, $wtpt);
			
		}
		
	} else {
		
		# error
		croak('invalid input structure');
		
	}
	
}

# convert xyz to L*a*b*
# parameters: (x, y, z)
# returns: (L, a, b)
sub _xyz2Lab {

	# get parameters
	my ($x, $y, $z) = @_;

	# compute L* value
	my $L = x2L($y);

	# return L*a*b* values
	return($L, 500 * (x2L($x) - $L)/116, 200 * ($L - x2L($z))/116);

}

# convert L*a*b* to xyz
# parameters: (L, a, b)
# returns: (x, y, z)
sub _Lab2xyz {

	# get parameters
	my ($L, $a, $b) = @_;

	# return xyz values
	return (L2x($L + 116 * $a/500), L2x($L), L2x($L - 116 * $b/200));

}

# convert xyz to LxLyLz
# parameters: (x, y, z)
# returns: (Lx, Ly, Lz)
sub _xyz2Lxyz {

	# get parameters
	my ($x, $y, $z) = @_;

	# return LxLyLz values
	return(x2L($x), x2L($y), x2L($z));

}

# convert LxLyLz to xyz
# parameters: (Lx, Ly, Lz)
# returns: (x, y, z)
sub _Lxyz2xyz {

	# get parameters
	my ($Lx, $Ly, $Lz) = @_;

	# return xyz values
	return (L2x($Lx), L2x($Ly), L2x($Lz));

}

# convert L*a*b* to LxLyLz
# parameters: (L, a, b)
# returns: (Lx, Ly, Lz)
sub _Lab2Lxyz {

	# get parameters
	my ($L, $a, $b) = @_;

	# return LxLyLz values
	return($L + 116 * $a/500, $L, $L - 116 * $b/200);

}

# convert LxLyLz to L*a*b*
# parameters: (Lx, Ly, Lz)
# returns: (L, a, b)
sub _Lxyz2Lab {

	# get parameters
	my ($Lx, $Ly, $Lz) = @_;

	# return L*a*b* values
	return($Ly, 500 * ($Lx - $Ly)/116, 200 * ($Ly - $Lz)/116);

}

# convert XYZ to L*a*b*
# parameters: (X, Y, Z, ref_to_WP_vector)
# returns: (L, a, b)
sub _XYZ2Lab {

	# get parameters
	my ($x, $y, $z, $WPxyz) = @_;

	# compute L* value
	my $L = x2L($y/$WPxyz->[1]);

	# return L*a*b* values
	return($L, 500 * (x2L($x/$WPxyz->[0]) - $L)/116, 200 * ($L - x2L($z/$WPxyz->[2]))/116);

}

# convert L*a*b* to XYZ
# parameters: (L, a, b, ref_to_WP_vector)
# returns: (X, Y, Z)
sub _Lab2XYZ {

	# get parameters
	my ($L, $a, $b, $WPxyz) = @_;

	# return XYZ values
	return (L2x($L + 116 * $a/500) * $WPxyz->[0], L2x($L) * $WPxyz->[1], L2x($L - 116 * $b/200) * $WPxyz->[2]);

}

# convert XYZ to LxLyLz
# parameters: (X, Y, Z, ref_to_WP_vector)
# returns: (Lx, Ly, Lz)
sub _XYZ2Lxyz {

	# get parameters
	my ($x, $y, $z, $WPxyz) = @_;

	# return values
	return(x2L($x/$WPxyz->[0]), x2L($y/$WPxyz->[1]), x2L($z/$WPxyz->[2]));

}

# convert LxLyLz to XYZ
# parameters: (Lx, Ly, Lz, ref_to_WP_vector)
# returns: (X, Y, Z)
sub _Lxyz2XYZ {

	# get parameters
	my ($Lx, $Ly, $Lz, $WPxyz) = @_;

	# return values
	return (L2x($Lx) * $WPxyz->[0], L2x($Ly) * $WPxyz->[1], L2x($Lz) * $WPxyz->[2]);

}

# convert XYZ to xyz
# parameters: (X, Y, Z, ref_to_WP_vector)
# returns: (x, y, z)
sub _XYZ2xyz {

	# get parameters
	my ($x, $y, $z, $WPxyz) = @_;

	# return values
	return($x/$WPxyz->[0], $y/$WPxyz->[1], $z/$WPxyz->[2]);

}

# convert xyz to XYZ
# parameters: (x, y, z, ref_to_WP_vector)
# returns: (X, Y, Z)
sub _xyz2XYZ {

	# get parameters
	my ($x, $y, $z, $WPxyz) = @_;

	# return values
	return($x * $WPxyz->[0], $y * $WPxyz->[1], $z * $WPxyz->[2]);

}

# convert XYZ to xyY
# parameters: (X, Y, Z)
# returns: (x, y, Y)
sub _XYZ2xyY {

	# get parameters
	my ($X, $Y, $Z) = @_;

	# compute denominator
	(my $d = $X + $Y + $Z) || croak('X + Y + Z = 0 when computing chromaticity');

	# return values
	return($X/$d, $Y/$d, $Y);

}

# convert xyY to XYZ
# parameters: (x, y, Y)
# returns: (X, Y, Z)
sub _xyY2XYZ {

	# get parameters
	my ($x, $y, $Y) = @_;

	# if y is zero
	if ($y == 0) {
		
		# error
		croak('cannot compute XYZ when y = 0');
		
	} else {
		
		# return values
		return($Y * $x/$y, $Y, $Y * (1 - $x - $y)/$y);
		
	}

}

# convert L*a*b* values to DIN 99 Lab values
# optional parameters are Ke (lightness) and Kch (chroma)
# default values of optional parameters are Ke = 1, Kch = 1
# parameters: (L*a*b*, [Ke, Kch])
# returns: (DIN_99_Lab)
sub _Lab2DIN99 {

	# local variables
	my ($e, $f, $G, $h99, $C99, $Ke, $Kch);

	# compute redness
	$e = cos16 * $_[1] + sin16 * $_[2];

	# compute yellowness
	$f = 0.7 * (cos16 * $_[2] - sin16 * $_[1]);

	# compute chroma
	$G = sqrt($e**2 + $f**2);

	# compute DIN 99 hue angle
	$h99 = atan2($f, $e);

	# get Ke
	$Ke = defined($_[3]) ? $_[3] : 1;

	# get Kch
	$Kch = defined($_[4]) ? $_[4] : 1;

	# compute DIN 99 chroma
	$C99 = (log(1 + 0.045 * $G))/(0.045 * $Kch * $Ke);

	# return DIN 99 Lab
	return(105.509 * (log(1 + 0.0158 * $_[0])) * $Ke, $C99 * cos($h99), $C99 * sin($h99));

}

#--------- additional Math::Matrix methods ---------

package Math::Matrix;

# print object contents to string
# format is an array structure
# parameter: ([format])
# returns: (string)
sub sdump {

	# get parameters
	my ($self, $p) = @_;

	# local variables
	my ($s, $fmt);

	# resolve parameter to a scalar
	$p = defined($p) ? ref($p) eq 'ARRAY' ? $p->[0] : $p : '10.5f';

	# set string to object ID
	$s = sprintf("'%s' object, (0x%x)\n", ref($self), Scalar::Util::refaddr($self));

	# append string
	$s .= "matrix values\n";

	# for each row
	for my $i (0 .. $#{$self}) {
		
		# make number format from parameter
		$fmt = "  %$p" x @{$self->[$i]};
		
		# append matrix row
		$s .= sprintf("$fmt\n", @{$self->[$i]});
		
	}

	# return
	return($s);

}

# print object contents
# format parameter is an array structure
# parameter: ([format])
# returns: (string)
sub dump {

	# get parameters
	my ($self, $format) = @_;

	# get string from 'sdump'
	my $s = $self->sdump($format);

	# print string
	print $s, "\n";

	# return string
	return($s);

}

# exponentiate matrix elements
# exponent may be a scalar or a vector
# no testing, 'inf' or 'nan' values are possible
# parameter: (exponent)
# returns: (new_matrix_object)
sub power {

	# get parameters
	my ($self, $x) = @_;

	# local variables
	my ($result);

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# compute using Lapack module
		$result = ICC::Support::Lapack::power($self, $x);
		
	} else {
		
		# if exponent a scalar
		if (! ref($x)) {
		
			# verify exponent is a number
			(Scalar::Util::looks_like_number($x)) || croak('exponent must be a real number');
		
			# for each row
			for my $i (0 .. $#{$self}) {
			
				# for each column
				for my $j (0 .. $#{$self->[0]}) {
				
					# compute element
					$result->[$i][$j] = $self->[$i][$j]**$x;
				
				}
		
			}
	
		# if exponent a vector
		} elsif (ref($x) eq 'ARRAY') {
		
			# verify exponents are numbers
			(@{$x} == grep {Scalar::Util::looks_like_number($_)} @{$x}) || croak('exponents must be real numbers');
		
			# verify vector size same as column size
			($#{$x} == $#{$self->[0]}) || croak('exponent vector wrong size');
		
			# for each row
			for my $i (0 .. $#{$self}) {
			
				# for each column
				for my $j (0 .. $#{$self->[0]}) {
				
					# compute element, avoiding math overflow
					$result->[$i][$j] = $self->[$i][$j]**$x->[$j];
				
				}
		
			}
	
		} else {
		
			# error
			croak('exponent must be a scalar or vector');
		
		}
		
	}

	# return new object
	return(bless($result, 'Math::Matrix'));

}

# convert matrix working space from xyz to XYZ
# default XYZ white point is D50
# parameter: ([XYZ_white_point])
# returns: (new_matrix_object)
sub xyz2XYZ {

	# get parameters
	my ($self, $wtpt) = @_;

	# local variables
	my ($mat);

	# verify a 3x3 matrix
	(@{$self} == 3 && @{$self->[0]} == 3) || croak('must be a 3x3 matrix');

	# set white point to D50 if undefined
	$wtpt = [96.42, 100, 82.49] if (! defined($wtpt));

	# clone matrix
	$mat = Storable::dclone($self);

	# for each row
	for my $i (0 .. 2) {
		
		# for each column
		for my $j (0 .. 2) {
			
			# modify non-diagonal element
			$mat->[$i][$j] *= $wtpt->[$i]/$wtpt->[$j] if ($i != $j);
			
		}
		
	}

	# return
	return($mat);

}

# convert matrix working space from XYZ to xyz
# default XYZ white point is D50
# parameter: ([XYZ_white_point])
# returns: (new_matrix_object)
sub XYZ2xyz {

	# get parameters
	my ($self, $wtpt) = @_;

	# local variables
	my ($mat);

	# verify a 3x3 matrix
	(@{$self} == 3 && @{$self->[0]} == 3) || croak('must be a 3x3 matrix');

	# set white point to D50 if undefined
	$wtpt = [96.42, 100, 82.49] if (! defined($wtpt));

	# clone matrix
	$mat = Storable::dclone($self);

	# for each row
	for my $i (0 .. 2) {
		
		# for each column
		for my $j (0 .. 2) {
			
			# modify non-diagonal element
			$mat->[$i][$j] *= $wtpt->[$j]/$wtpt->[$i] if ($i != $j);
			
		}
		
	}

	# return
	return($mat);

}

1;