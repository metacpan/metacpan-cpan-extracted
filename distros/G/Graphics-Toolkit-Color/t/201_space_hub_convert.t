#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 55;
use Graphics::Toolkit::Color::Space::Hub;

##### preparation ######################################################
my $convert    = \&Graphics::Toolkit::Color::Space::Hub::convert;
my $deconvert  = \&Graphics::Toolkit::Color::Space::Hub::deconvert;
my $RGB        =   Graphics::Toolkit::Color::Space::Hub::default_space();
my $rgb_axis   = [qw/red green blue/];
my $yuv_axis   = [qw/y u v/];
my $cmy_axis   = [qw/yellow cyan magenta/];
my $xyz_axis   = [qw/X Y Z/];
my $lab_axis   = [qw/L* a* b*/];
my $lch_axis   = [qw/luminance chroma hue/];
my $black      = [0, 0, 0];
my $white      = [1, 1, 1];

##### arg type checks ##################################################
is( ref $convert->(),                       '', 'convert needs at least one argument');
is( ref $convert->({r => 1,g => 1,b => 1}), '', 'convert only value ARRAY no HASH');
is( ref $convert->([0,0]),                  '', 'tuple has not enough values');
is( ref $convert->($black, 'Jou'),          '', 'convert needs a valid target name space');
is( ref $deconvert->(),                     '', 'deconvert needs at least one argument');
is( ref $deconvert->('JAP'),                '', 'deconvert needs a valid source space name name');
is( ref $deconvert->('RGB', {r => 1,g => 1,b => 1}), '', 'deconvert tule as ARRAY');
is( ref $deconvert->('JAP', $black),       '', 'space name bad but tuple good');

#### simple conversion #################################################
my $rgb = $convert->([0,1/255,1], 'RGB');
is_tuple( $rgb, [0, 1, 255], $rgb_axis, 'none conversion from RGB space to RGB');
$rgb = $convert->([0,1/255,1], 'RGB', 'normal');
is_tuple( $rgb, [0, 1/255, 1], $rgb_axis, 'none conversion with normalisation');

my $yuv = $convert->([.1, .2, .3], 'YUV', 'normal', [1, .1, 0] ,'YUV');
is_tuple( $yuv, [1, .1, 0], $yuv_axis, 'conversion to YUV, normal with drop in source values');
$yuv = $convert->( [.1, .2, .3], 'YUV', undef, [1, 0.1, 0] ,'YUV');
is_tuple( $yuv, [1, -0.4, -0.5], $yuv_axis, 'conversion to YUV, no normal with drop in source values');

my $cmy = $convert->([0, 0.1, 1], 'CMY');
is_tuple( $cmy, [1, 0.9, 0], $cmy_axis, 'conversion to CMY');

$rgb = $deconvert->([1, 0.9, 0], 'CMY', 'normal');
is_tuple( $rgb, [0, 0.1, 1], $rgb_axis, 'conversion back from CMY');

#### chained conversion ################################################
my $xyz = $convert->( $black, 'XYZ');
is_tuple( $RGB->round($xyz, 5), [0, 0, 0], $xyz_axis, 'convert black to XYZ (2 hop conversion)');
$rgb = $deconvert->([0, 0, 0], 'XYZ');
is_tuple( $RGB->round($rgb, 5), $black, $xyz_axis, 'convert black from XYZ (2 hop conversion)');

$xyz = $convert->($white, 'XYZ');
is_tuple( $RGB->round($xyz, [6,4,6]), [95.047, 100, 108.883], $xyz_axis, 'convert white to XYZ (2 hop conversion)');
$rgb = $deconvert->( $white, 'XYZ');
is_tuple( $RGB->round($rgb, 4), [255, 255, 255], $xyz_axis, 'deconvert white from XYZ (2 hop conversion)');

$xyz = $convert->([1, 1, 1], 'XYZ', 'normal');
is_tuple( $RGB->round($xyz, 6), [1, 1, 1], $xyz_axis, 'convert white to normal XYZ (2 hop conversion) and normalisation');
$xyz = $convert->([.1, .2, .3], 'XYZ');
is_tuple( $RGB->round($xyz, 4), [2.9187, 3.1093, 7.3739], $xyz_axis, 'convert dark blue to XYZ');

$rgb = $deconvert->([0.030707966, 0.031093, 0.067723152], 'XYZ', 'normal');
is_tuple( $RGB->round($rgb, 4), [.1, .2, .3], $xyz_axis, 'deconvert normal dark blue from XYZ (2 hop conversion)');

my $lab = $convert->([1, 1, 1], 'LAB', 'normal');
is_tuple( $RGB->round($lab, 5), [1, .5, .5], $lab_axis, 'convert white to LAB (3 hop conversion)');

$rgb = $deconvert->([1, 0.5, 0.5], 'LAB');
is_tuple( $RGB->round($rgb, 4), [255, 255, 255], $rgb_axis, 'deconvert white from LAB (3 hop conversion)');

$lab = $convert->([.1, .2, .3], 'CIELAB');
is_tuple( $RGB->round($lab, 4), [20.4762, -0.6518, -18.632], $lab_axis, 'convert dark blue to CIELAB');

$rgb = $deconvert->([.204762, 0.4993482, 0.45341975], 'CIELAB', 'normal');
is_tuple( $RGB->round($rgb, 5), [.1, .2, .3], $rgb_axis, 'deconvert white from LAB (3 hop conversion)');

my $lch = $convert->([1, 1/255, 0], 'CIELCHab');
is_tuple( $RGB->round($lch, 3), [53.264, 104.505, 40.026], $lch_axis, 'convert bright red to LCHab (4 hop conversion)');

$lch = $convert->([1, 1/255, 0], 'CIELCHab', 1);
is_tuple( $RGB->round($lch, 5), [.53264, .19389, 0.11118], $lch_axis, 'convert bright red to normalized LCHab');

$lch = $convert->([0.1, 0.2, 0.9], 'CIELCHuv');
is_tuple( $RGB->round($lch, [4,4,5]), [34.5264, 119.3958, 264.63634], $lch_axis, 'convert bright blue to LCHuv (4 hop conversion)');

$lch = $deconvert->([0.3453, 0.4575, 0.7351], 'CIELCHuv', 'normal'); # CIELCHuv > CIELUV > CIEXYZ > LinRGB > RGB
is_tuple( $RGB->round($lch, [4,4,3]), [0.1, 0.2, 0.9], $lch_axis, 'deconvert bright blue back to normal RGB');

$rgb = $deconvert->( [0, 0.5, 0.5], 'LAB' );
is_tuple( $RGB->round($rgb, 5), [0, 0, 0], $rgb_axis, 'deconvert black from LAB');

$rgb = $deconvert->( [.53264, 104.505/539, 40.026/360], 'LCH', 'normal'); 
is_tuple( $RGB->round($rgb, [5,4,5]), [1, 0.0039, 0], $rgb_axis, 'deconvert bright red from LCH');


# --- DCIP3 ---
my $dci = $convert->( [0, 0, 0], 'DCIP3'); 
is_tuple( $RGB->round($dci, [9,9,9]), [0, 0, 0], $rgb_axis, 'convert black to DCIP3');
$rgb = $deconvert->( [0, 0, 0], 'DCIP3',1); 
is_tuple( $RGB->round($rgb, [9,9,9]), [0, 0, 0], $rgb_axis, 'deconvert black from DCIP3');

$dci = $convert->( [1, 1, 1], 'DCIP3'); 
is_tuple( $RGB->round($dci, [7, 6, 7]), [1, 1, 1], $rgb_axis, 'convert white to DCIP3');
$rgb = $deconvert->( [1, 1, 1], 'DCIP3',1); 
is_tuple( $RGB->round($rgb, [7, 8, 7]), [1, 1, 1], $rgb_axis, 'deconvert white from DCIP3');

$dci = $convert->( [0.5, 0.5, 0.5], 'DCIP3'); 
is_tuple( $RGB->round($dci, [9, 9, 9]), [0.528111202, 0.528111269, 0.528111226], $rgb_axis, 'convert grey to DCIP3');
$rgb = $deconvert->( [0.5281112017, 0.5281112686, 0.5281112256], 'DCIP3', 1); 
is_tuple( $RGB->round($rgb, [7, 7, 7]), [0.5, 0.5, 0.5], $rgb_axis, 'deconvert grey from DCIP3');

$dci = $convert->( [1, 0, 0], 'DCIP3' );
is_tuple( $RGB->round($dci, [9, 9, 9]), [0.944389481, 0.234139612, 0.164010654], $rgb_axis, 'convert red to DCIP3');
$rgb = $deconvert->( [0.9443894813, 0.2341396122, 0.1640106539], 'DCIP3', 1 );
is_tuple( $RGB->round($rgb, [7, 9, 6]), [1, 0, 0], $rgb_axis, 'deconvert red from DCIP3');

$dci = $convert->( [0, 1, 0], 'DCIP3' );
is_tuple( $RGB->round($dci, [9, 9, 9]), [0.424696879, 0.984316996, 0.326557673], $rgb_axis, 'convert green to DCIP3');
$rgb = $deconvert->( [0.4246968792, 0.9843169959, 0.3265576734], 'DCIP3', 1 );
is_tuple( $RGB->round($rgb, [6, 7, 6]), [0, 1, 0], $rgb_axis, 'deconvert green from DCIP3');

$dci = $convert->( [0, 0, 1], 'DCIP3' );
is_tuple( $RGB->round($dci, [9, 9, 9]), [0.032163962, 0.066729212, 0.963347929], $rgb_axis, 'convert blue to DCIP3');
$rgb = $deconvert->( [0.0321639621, 0.0667292123, 0.9633479292], 'DCIP3', 1 );
is_tuple( $RGB->round($rgb, [5, 5, 7]), [0, 0, 1], $rgb_axis, 'deconvert blue from DCIP3');


# --- WideGamutRGB ---
my $wgrgb = $convert->( [0, 0, 0], 'WideGamutRGB' );
is_tuple( $RGB->round($wgrgb, [9,9,9]), [0, 0, 0], $rgb_axis, 'convert black to WideGamutRGB');
$rgb = $deconvert->( [0, 0, 0], 'WideGamutRGB' ); 
is_tuple( $RGB->round($rgb, [9,9,9]), [0, 0, 0], $rgb_axis, 'deconvert black from WideGamutRGB');

$wgrgb = $convert->( [1, 1, 1], 'WideGamutRGB' );
is_tuple( $RGB->round($wgrgb, [7,6,7]), [1, 1, 1], $rgb_axis, 'convert white to WideGamutRGB');
$rgb = $deconvert->( [1, 1, 1], 'WideGamutRGB', 'normal' ); 
is_tuple( $RGB->round($rgb, [7, 8, 7]), [1, 1, 1], $rgb_axis, 'deconvert white from WideGamutRGB');

$wgrgb = $convert->( [0.5, 0.5, 0.5], 'WideGamutRGB' );
is_tuple( $RGB->round($wgrgb, [9, 9, 9]), [0.4961036950, 0.496103731, 0.496103697], $rgb_axis, 'convert grey to WideGamutRGB');
$rgb = $deconvert->( [0.4961036950, 0.4961037305, 0.4961036967], 'WideGamutRGB', 1 );
is_tuple( $RGB->round($rgb, [7, 7, 7]), [0.5, 0.5, 0.5], $rgb_axis, 'deconvert grey from WideGamutRGB');

$wgrgb = $convert->( [1, 0, 0], 'WideGamutRGB' );
is_tuple( $RGB->round($wgrgb, [9, 9, 9]), [0.788578572, 0.343584924, 0.131923881], $rgb_axis, 'convert red to WideGamutRGB');
$rgb = $deconvert->( [0.7885785716, 0.3435849236, 0.1319238809], 'WideGamutRGB', 1 );
is_tuple( $RGB->round($rgb, [7, 7, 6]), [1, 0, 0], $rgb_axis, 'deconvert red from WideGamutRGB');

$wgrgb = $convert->( [0, 1, 0], 'WideGamutRGB' );
is_tuple( $RGB->round($wgrgb, [9, 9, 9]), [0.66275451, 0.925353069, 0.296693393], $rgb_axis, 'convert green to WideGamutRGB');
$rgb = $deconvert->( [0.6627545096, 0.9253530691, 0.2966933929], 'WideGamutRGB', 1 );
is_tuple( $RGB->round($rgb, [6, 7, 6]), [0, 1, 0], $rgb_axis, 'deconvert green from WideGamutRGB');

$wgrgb = $convert->( [0, 0, 1], 'WideGamutRGB' );
is_tuple( $RGB->round($wgrgb, [9, 9, 9]), [0.061892655, 0.281243877, 0.962449527], $rgb_axis, 'convert blue to WideGamutRGB');
$rgb = $deconvert->( [0.0618926553, 0.2812438774, 0.9624495267], 'WideGamutRGB', 1 );
is_tuple( $RGB->round($rgb, [5, 5, 7]), [0, 0, 1], $rgb_axis, 'deconvert blue from WideGamutRGB');

exit 0;
