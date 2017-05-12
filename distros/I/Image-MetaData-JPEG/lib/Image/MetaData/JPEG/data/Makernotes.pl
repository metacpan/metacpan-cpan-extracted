###########################################################
# A Perl package for showing/modifying JPEG (meta)data.   #
# Copyright (C) 2004,2005,2006 Stefano Bettelli           #
# See the COPYING and LICENSE files for license terms.    #
###########################################################

#============================================================================#
# NOTE: This file MUST be included by Tables.pm.                             #
#============================================================================#
# The following hash contains information concerning MakerNotes; each entry  #
# corresponds to an anonymous hash containing information for parsing:       #
# 'signature'   the MakerNote signature (a regular expression)               #
# 'maker'       the Maker signature (i.e., its name, no regex)               #
# 'tags'        a reference to a hash for tag translations                   #
# 'mkntstart'   if set, offsets are counted from the maker note start        #
# 'mkntTIFF'    if set, offsets are counted from the internal TIFF header    #
# 'ignore'      if set, the format is to be ignored                          #
# 'nonext'      if set, the maker note IFD does not have a next_link         #
# 'endianness'  if set, the byte order is fixed to this value                #
# 'nonIFD'      if set, the maker note is not IFD-like                       #
#============================================================================#
# Tests [entries following a (p) are personal tests]:                        #
# Canon: A50, EOS-D30 (p) DIG.IXUS 300, PowerShot A10,A20,G2,S30,S40,S330    #
# Casio: QV2000, QV8000 (p) QV-3000EX, QV-4000, QV-2000UX, QV-8000SX         #
# Fujifilm: Finepix1400, 4700, 4900Z, 2400Zoom (p) 1400Zoom, 6800ZOOM, 40i   #
# Kodak: (p) DX3900, DX4900                                                  #
# Minolta: (p) DiMAGE X, 7Hi, S404                                           #
# Nikon: E700, E900S, E910, D1, E5400, SQ,                                   #
#        (p) E800, E900, E950, E990, E995, D70, D100, D2H                    #
# Olympus: [C920Z,D450Z], [C40Z,D40Z], [C960Z,D460Z], [C100,D370]            #
#          (p) (some tags added) E-10, E-20, E-20N, E-20P                    #
# Panasonic: DMC-FZ10 (p) DMC-FZ15, DMC-FZ3                                  #
# Pentax: (p) Optio 330, 430                                                 #
# Ricoh: (p) DC-3Z, RDC-5000, RDC-5300, Caplio RR30                          #
# Sanyo: DSC-MZ2 (p) SR662, SR6, SX113                                       #
# Sigma: (p) SD9, SD10                                                       #
# Sony: (p) Cybershot                                                        #
#============================================================================#
my $HASH_MAKERNOTES = {                                                      #
    Agfa        => {signature => "^(AGFA \000\001)",                         #
		    maker     => 'AGFA' },                                   #
    Canon       => {signature => "^()",					     #
		    maker     => 'Canon' },				     #
    Casio_1     => {signature => "^()[^Q]",				     #
		    maker     => 'CASIO' },				     #
    Casio_2     => {signature => "^(QVC\000{3})",			     #
		    maker     => 'CASIO' },				     #
    Epson       => {signature => "^(EPSON\000\001\000)",		     #
		    maker     => 'EPSON' },				     #
    Foveon      => {signature => "^(FOVEON\000{2}\001\000)",		     #
		    maker     => 'FOVEON' },				     #
    Fujifilm    => {signature => "^(FUJIFILM\014\000{3})",		     #
		    maker     => 'FUJIFILM',				     #
		    mkntstart => 1 },					     #
    HPackard    => {signature => "^(HP)",				     #
		    maker     => 'Hewlett-Packard',			     #
		    ignore    => 1 },					     #
    Kyocera     => {signature => "^(KYOCERA {12}\000{3})",		     #
		    maker     => 'KYOCERA',				     #
		    mkntstart => 1,					     #
		    nonext    => 1 },					     #
    Kodak       => {signature  => "^(KDK INFO[a-zA-Z0-9]*  )",		     #
		    maker      => 'KODAK',				     #
		    endianness => $BIG_ENDIAN,				     #
		    nonIFD     => 1 },					     #
    Minolta_1   => {signature => "^().{10}MLT0",			     #
		    maker     => 'MINOLTA' },				     #
    Minolta_2   => {signature => "^().{10}MLT0",			     #
		    maker     => 'Minolta' },				     #
    Konica      => {signature => '^((MLY|KC|(\+M){4})|\001\000{5}\004)',     #
		    maker     => '(Minolta|KONICA)',			     #
		    ignore    => 1 },					     #
    Nikon_1     => {signature => "^(Nikon\000\001\000)",		     #
		    maker     => 'NIKON' },				     #
    Nikon_2     => {signature => "^()[^N]",                                  #
		    maker     => 'NIKON' },				     #
    Nikon_3     => {signature => "^(Nikon\000\002[\020\000]\000{2})",	     #
		    maker     => 'NIKON',				     #
		    mkntTIFF  => 1 },					     #
    Olympus     => {signature => "^(OLYMP\000[\001\002]\000)",		     #
		    maker     => 'OLYMPUS' },				     #
    Panasonic_1 => {signature => "^(Panasonic\000{3})",			     #
		    maker     => 'Panasonic',				     #
		    nonext    => 1 },					     #
    Panasonic_2 => {signature => "^(MKED)",				     #
		    maker     => 'Panasonic',				     #
		    nonext    => 1,					     #
		    ignore    => 1 },					     #
    Pentax_1    => {signature => "^()[^A]",				     #
		    maker     => 'Asahi',				     #
		    mkntstart => 1 },					     #
    Pentax_2    => {signature => "^(AOC\000..)",			     #
		    maker     => 'Asahi',				     #
		    mkntstart => 1,					     #
		    nonext    => 1 },					     #
    Ricoh_1     => {signature => "^(Rv|Rev)",				     #
		    maker     => 'RICOH',				     #
		    ignore    => 1 },					     #
    Ricoh_2     => {signature => "^(\000)",				     #
		    maker     => 'RICOH',				     #
		    ignore    => 1 },					     #
    Ricoh_3     => {signature => "^((Ricoh|RICOH)\000{3})",		     #
		    maker     => 'RICOH'},				     #
    Sanyo       => {signature => "^(SANYO\000\001\000)",		     #
		    maker     => 'SANYO' },				     #
    Sigma       => {signature => "^(SIGMA\000{3}\001\000)",		     #
		    maker     => 'SIGMA' },				     #
    Sony        => {signature => "^(SONY (CAM|DSC) \000{3})",		     #
		    maker     => 'SONY',                                     #
		    nonext    => 1 },                                        #
    Toshiba     => {signature => "^()",                                      #
		    maker     => 'TOSHIBA',                                  #
		    ignore    => 1 },                                        #
    unknown     => {signature => '^()', # catch-all rule                     #
		    maker     => '.',                                        #
		    nonIFD    => 1 }, };                                     #
#--- Special screen rules ---------------------------------------------------#
# an ISO setting record often consists of a pair of $SHORT numbers:          #
# the first number is always zero, the second one gives the ISO setting.     #
my $SSR_ISOsetting  = sub { die if $_[0] != 0; die if $_[1] !~ /\d*00/; };   #
#----------------------------------------------------------------------------#
$$HASH_MAKERNOTES{'Canon'}{'tags'} =                                         #
{ 0x0000 => ['Placeholder',        $SHORT, undef, '0'                     ], #
  0x0001 => ['CameraSettings',     $SHORT, undef, $IFD_integer            ], #
  0x0002 => [ undef,               $SHORT,     4, undef                   ], #
  0x0003 => [ undef,               $SHORT,     4, undef                   ], #
  0x0004 => ['ShotInfo',           $SHORT, undef, undef                   ], #
  0x0005 => [ undef,               $SHORT,     6, undef                   ], #
  0x0006 => ['ImageType',          $ASCII,    32, $IFD_Cstring            ], #
  0x0007 => ['FirmwareVersion',    $ASCII,    24, $IFD_Cstring            ], #
  0x0008 => ['ImageNumber',        $LONG,      1, $IFD_integer            ], #
  0x0009 => ['OwnerName',          $ASCII,    32, $IFD_Cstring            ], #
  0x000a => ['Settings-1D',        $SHORT, undef, undef                   ], #
  0x000c => ['CameraSerialNumber', $LONG,      1, $IFD_integer            ], #
  0x000d => [ undef,               $SHORT, undef, undef                   ], #
  0x000e => ['FileLength',         undef,  undef, undef                   ], #
  0x000f => ['CustomFunctions',    $SHORT, undef, undef                   ], #
  0x0010 => [ undef,               $LONG,      1, undef                   ], #
  0x0012 => ['PictureInfo',        undef,  undef, undef                   ], #
  0x0090 => ['CustomFunctions-1D', undef,  undef, undef                   ], #
  0x00a0 => ['Canon-A0Tag',        undef,  undef, undef                   ], #
  0x00b6 => ['PreviewImageInfo',   undef,  undef, undef                ], }; #
#----------------------------------------------------------------------------#
$$HASH_MAKERNOTES{'Casio_1'}{'tags'} =				             #
{ 0x0001 => ['RecordingMode',      $SHORT,     1, '[1-5]'                 ], #
  0x0002 => ['Quality',            $SHORT,     1, '[123]'                 ], #
  0x0003 => ['FocusingMode',       $SHORT,     1, '[2-57]'                ], #
  0x0004 => ['FlashMode',          $SHORT,     1, '[1-5]'                 ], #
  0x0005 => ['FlashIntensity',     $SHORT,     1, '1[135]'                ], #
  0x0006 => ['ObjectDistance',     $LONG,      1, $IFD_integer            ], #
  0x0007 => ['WhiteBalance',       $SHORT,     1, '([1-5]|129)'           ], #
  0x0008 => [ undef,               $SHORT,     1, '[1-4]'                 ], #
  0x0009 => [ undef,               $SHORT,     1, '[12]'                  ], #
  0x000a => ['DigitalZoom',        $LONG,      1, '(65536|65537|131072)'  ], #
  0x000b => ['Sharpness',          $SHORT,     1, '([012]|16)'            ], #
  0x000c => ['Contrast',           $SHORT,     1, '([012]|16)'            ], #
  0x000d => ['Saturation',         $SHORT,     1, '([012]|16)'            ], #
  0x000e => [ undef,               $SHORT,     1, '[0]'                   ], #
  0x000f => [ undef,               $SHORT,     1, $IFD_integer            ], #
  0x0010 => [ undef,               $SHORT,     1, '[01]'                  ], #
  0x0011 => [ undef,               $LONG,      1, $IFD_integer            ], #
  0x0012 => [ undef,               $SHORT,     1, '(16|18|24)'            ], #
  0x0013 => [ undef,               $SHORT,     1, '(6|1[567])'            ], #
  0x0014 => ['CCDSensitivity',     $SHORT,     1,'(64|80|100|125|244|250)'], #
  0x0015 => [ undef,               $ASCII, undef, $IFD_Cstring            ], #
  0x0016 => [ undef,               $SHORT,     1, '[1]'                   ], #
  0x0017 => [ undef,               $SHORT,     1, '[1]'                   ], #
  0x0018 => [ undef,               $SHORT,     1, '(13)'                  ], #
  0x0019 => ['WhiteBalance',       $SHORT,     1, '[0-5]'                 ], #
  0x001a => [ undef,               $UNDEF, undef, undef                   ], #
  0x001c => [ undef,               $SHORT,     1, '[5]'                   ], #
  0x001d => ['FocalLength',        $SHORT,     1, $IFD_integer            ], #
  0x001e => [ undef,               $SHORT,     1, '[1]'                   ], #
  0x0e00 => ['PrintIM_Data',       $UNDEF, undef, undef                ], }; # 
#----------------------------------------------------------------------------#
$$HASH_MAKERNOTES{'Casio_2'}{'tags'} =				             #
{ 0x0002 => ['PreviewThumbDim',    $SHORT,     2, $IFD_integer            ], #
  0x0003 => ['PreviewThumbSize',   $LONG,      1, $IFD_integer            ], #
  0x0004 => ['PreviewThumbOffset', $LONG,      1, $IFD_integer            ], #
  0x0008 => ['QualityMode',        $SHORT,     1, '[12]'                  ], #
  0x0009 => ['ImageSize',          $SHORT,     1, '([045]|2[012]|36)'     ], #
  0x000d => ['FocusMode',          $SHORT,     1, '[01]'                  ], #
  0x0014 => ['CCDSensitivity',     $SHORT,     1, '[3469]'                ], #
  0x0019 => ['WhiteBalance',       $SHORT,     1, '[0-5]'                 ], #
  0x001d => ['FocalLength',        $SHORT,     1, $IFD_integer            ], #
  0x001f => ['Saturation',         $SHORT,     1, '[0-2]'                 ], #
  0x0020 => ['Contrast',           $SHORT,     1, '[0-2]'                 ], #
  0x0021 => ['Sharpness',          $SHORT,     1, '[0-2]'                 ], #
  0x0e00 => ['PrintIM_Data',       $UNDEF, undef, undef                   ], # 
  0x2000 => ['PreviewThumbnail',   $UNDEF, undef, '\377\330\377.*'        ], #
  0x2001 => [ undef,               $ASCII, undef, undef                   ], #
  0x2002 => [ undef,               $ASCII, undef, undef                   ], #
  0x2003 => [ undef,               $UNDEF, undef, undef                   ], #
  0x2011 => ['WhiteBalanceBias',   $SHORT,     2, undef                   ], #
  0x2012 => ['WhiteBalance',       $SHORT,     1, '(12|[014])'            ], #
  0x2013 => [ undef,               $SHORT,     1, undef                   ], #
  0x2021 => [ undef,               $SHORT,     4, '65535'                 ], #
  0x2022 => ['ObjectDistance',     $LONG,      1, $IFD_integer            ], #
  0x2023 => [ undef,               $SHORT,     1, undef                   ], #
  0x2031 => [ undef,               $UNDEF,     2, undef                   ], #
  0x2032 => [ undef,               $UNDEF,     2, undef                   ], #
  0x2033 => [ undef,               $SHORT,     1, undef                   ], #
  0x2034 => ['FlashDistance',      $SHORT,     1, $IFD_integer            ], #
  0x3000 => ['RecordMode',         $SHORT,     1, '[2]'                   ], #
  0x3001 => ['SelfTimer',          $SHORT,     1, '[1]'                   ], #
  0x3002 => ['Quality',            $SHORT,     1, '[23]'                  ], #
  0x3003 => ['FocusMode',          $SHORT,     1, '[136]'                 ], #
  0x3005 => [ undef,               $SHORT,     1, undef                   ], #
  0x3006 => ['TimeZone',           $ASCII, undef, $IFD_Cstring            ], #
  0x3007 => ['BestshotMode',       $SHORT,     1, '[01]'                  ], #
  0x3011 => [ undef,               $UNDEF,     2, undef                   ], #
  0x3012 => [ undef,               $UNDEF,     2, undef                   ], #
  0x3013 => [ undef,               $UNDEF,     1, undef                   ], #
  0x3014 => ['CCDSensitivity',     $SHORT,     1, '[0]'                   ], #
  0x3015 => ['ColourMode',         $SHORT,     1, '[0]'                   ], #
  0x3016 => ['Enhancement',        $SHORT,     1, '[0]'                   ], #
  0x3017 => ['Filter',             $SHORT,     1, '[0]'                   ], #
  0x3018 => [ undef,               $SHORT,     1, '[0]'                ], }; #
#----------------------------------------------------------------------------#
$$HASH_MAKERNOTES{'Fujifilm'}{'tags'} =                                      #
{ 0x0000 => ['Version',            $UNDEF,     4, '0130'                  ], #
  0x1000 => ['Quality',            $ASCII,     8, '(BASIC|NORMAL|FINE)'   ], #
  0x1001 => ['Sharpness',          $SHORT,     1, '[1-5]'                 ], #
  0x1002 => ['WhiteBalance',       $SHORT,     1, '(0|256|512|76[89]|770)'], #
  0x1003 => ['ColorSaturation',    $SHORT,     1, '(0|256|512)'           ], #
  0x1004 => ['ToneContrast',       $SHORT,     1, '(0|256|512)'           ], #
  0x1010 => ['FlashMode',          $SHORT,     1, '[0-3]'                 ], #
  0x1011 => ['FlashStrength',      $SRATIONAL, 1, $IFD_signed             ], #
  0x1020 => ['MacroMode',          $SHORT,     1, '[01]'                  ], #
  0x1021 => ['FocusMode',          $SHORT,     1, '[01]'                  ], #
  0x1030 => ['SlowSync',           $SHORT,     1, '[01]'                  ], #
  0x1031 => ['PictureMode',        $SHORT,     1, '([0-24-6]|256|512|768)'], #
  0x1032 => [ undef,               $SHORT,     1, undef                   ], #
  0x1100 => ['ContTake/Bracket',   $SHORT,     1, '[01]'                  ], #
  0x1200 => [ undef,               $SHORT,     1, undef                   ], #
  0x1300 => ['BlurWarning',        $SHORT,     1, '[01]'                  ], #
  0x1301 => ['Focuswarning',       $SHORT,     1, '[01]'                  ], #
  0x1302 => ['AutoExposureWarning',$SHORT,     1, '[01]'               ], }; #
#----------------------------------------------------------------------------#
$$HASH_MAKERNOTES{'Kodak'}{'tags'} =                                         #
{ 0x0001 => ['---0x0001',          $BYTE,      1, undef                   ], #
  0x0002 => ['Compression',        $BYTE,      1, '[12]'                  ], #
  0x0003 => ['BurstMode',          $BYTE,      1, '[01]'                  ], #
  0x0004 => ['MacroMode',          $BYTE,      1, '[01]'                  ], #
  0x0005 => ['PixelXDimension',    $SHORT,     1, '(2160|1800|1536|1080)' ], #
  0x0007 => ['PixelYDimension',    $SHORT,     1, '(1440|1200|1024|720)'  ], #
  0x0009 => ['Year',               $SHORT,     1, $re_year                ], #
  0x000a => ['Month',              $BYTE,      1, $re_month               ], #
  0x000b => ['Day',                $BYTE,      1, $re_day                 ], #
  0x000c => ['Hour',               $BYTE,      1, $re_hour                ], #
  0x000d => ['Minute',             $BYTE,      1, $re_minute              ], #
  0x000e => ['Second',             $BYTE,      1, $re_second              ], #
  0x000f => ['SubSecond',          $BYTE,      1, $re_integer             ], #
  0x0010 => ['---BurstMode_2',     $SHORT,     1, undef                   ], #
  0x0012 => ['---0x0012',          $BYTE,      1, undef                   ], #
  0x0013 => ['ShutterMode',        $BYTE,      1, '(0|32)'                ], #
  0x0014 => ['MeteringMode',       $BYTE,      1, '[012]'                 ], #
  0x0015 => ['BurstSequenceIndex', $BYTE,      1, '[0-8]'                 ], #
  0x0016 => ['FNumber',            $SHORT,     1, undef                   ], #
  0x0018 => ['ExposureTime',       $LONG,      1, $re_integer             ], #
  0x001c => ['ExposureBiasValue',  $SSHORT,    1, '(0|-?(5|10|15|20)00)'  ], #
  0x001e => ['---VariousModes_2',  $SHORT,     1, undef                   ], #
  0x0020 => ['---Distance_1',      $LONG,      1, undef                   ], #
  0x0024 => ['---Distance_2',      $LONG,      1, undef                   ], #
  0x0028 => ['---Distance_3',      $LONG,      1, undef                   ], #
  0x002c => ['---Distance_4',      $LONG,      1, undef                   ], #
  0x0030 => ['FocusMode',          $BYTE,      1, '[023]'                 ], #
  0x0031 => ['---0x0031',          $BYTE,      1, undef                   ], #
  0x0032 => ['---VariousModes_3',  $SHORT,     1, undef                   ], #
  0x0034 => ['PanoramaMode',       $SSHORT,    1, '(0|-1)'                ], #
  0x0036 => ['SubjectDistance',    $SHORT,     1, $re_integer             ], #
  0x0038 => ['WhiteBalance',       $BYTE,      1, '[0-3]'                 ], #
  0x0039 => ['---0x0039',          $UNDEF,    27, undef                   ], #
#  0x0039 => ['---0x0039',          $BYTE,      1, undef                   ], #
#  0x003a => ['---0x003a',          $SHORT,     1, undef                   ], #
#  0x003c => ['---0x003c',          $LONG,      1, undef                   ], #
#  0x0040 => ['---0x0040',          $SHORT,     1, undef                   ], #
#  0x0042 => ['---0x0042',          $SHORT,     1, undef                   ], #
#  0x0044 => ['---0x0044',          $SHORT,     1, undef                   ], #
#  0x0046 => ['---0x0046',          $SHORT,     1, undef                   ], #
#  0x0048 => ['---0x0048',          $SHORT,     1, undef                   ], #
#  0x004a => ['---0x004a',          $SHORT,     1, undef                   ], #
#  0x004c => ['---0x004c',          $SHORT,     1, undef                   ], #
#  0x004e => ['---0x004e',          $SHORT,     1, undef                   ], #
#  0x0050 => ['---0x0050',          $SHORT,     1, undef                   ], #
#  0x0052 => ['---0x0052',          $BYTE,      1, undef                   ], #
#  0x0053 => ['---0x0053',          $BYTE,      1, undef                   ], #
  0x0054 => ['FlashMode',          $BYTE,      1, '[0-3]'                 ], #
  0x0055 => ['FlashFired',         $BYTE,      1, '[01]'                  ], #
  0x0056 => ['ISOSpeedMode',       $SHORT,     1, '(0|[124]00)'           ], #
  0x0058 => ['---ISOSpeedExposureIndex', $SHORT,     1, undef             ], #
  0x005a => ['TotalZoomFactor',    $SHORT,     1, $re_integer             ], #
  0x005c => ['DateTimeStampMode',  $SHORT,     1, '[0-6]'                 ], #
  0x005e => ['ColourMode',         $SHORT,     1, '(1|2|32)'              ], #
  0x0060 => ['DigitalZoomFactor',  $SHORT,     1, $re_integer             ], #
  0x0062 => ['---0x0062',          $BYTE,      1, undef                   ], #
  0x0063 => ['Sharpness',          $SBYTE,     1, '(-1|0|1)'              ], #
  0x0064 => ['binary',              $UNDEF,   808, undef                   ], #
#  0x0064 => ['---0x0064',          $SHORT,     1, undef                   ], #
#  0x0066 => ['---0x0066',          $SHORT,     1, undef                   ], #
#  0x0068 => ['---0x0068',          $SHORT,     1, undef                   ], #
#  0x006a => ['---0x006a',          $SHORT,     1, undef                   ], #
#  0x006c => ['---0x006c',          $SHORT,     1, undef                   ], #
#  0x006e => ['---0x006e',          $SHORT,     1, undef                   ], #
#  0x0070 => ['---0x0070',          $SHORT,     1, undef                   ], #
#  0x0072 => ['---0x0072',          $SHORT,     1, undef                   ], #
#  0x0074 => ['---0x0074',          $SHORT,     1, undef                   ], #
#  0x0076 => ['---0x0076',          $SHORT,     1, undef                   ], #
#  0x0078 => ['---0x0078',          $SHORT,     1, undef                   ], #
#  0x007a => ['---0x007a',          $SHORT,     1, undef                   ], #
#  0x007c => ['---0x007c',          $SHORT,     1, undef                   ], #
#  0x007e => ['---0x007e',          $SHORT,     1, undef                   ], #
#  0x0080 => ['---0x0080',          $SHORT,     1, undef                   ], #
#  0x0082 => ['---0x0082',          $SHORT,     1, undef                   ], #
#  0x0084 => ['---0x0084',          $SHORT,     1, undef                   ], #
#  0x0086 => ['---0x0086',          $SHORT,     1, undef                   ], #
#  0x0088 => ['---0x0088',          $SHORT,     1, undef                   ], #
#  0x008a => ['---0x008a',          $SHORT,     1, undef                   ], #
#  0x008c => ['---0x008c',          $SHORT,     1, undef                   ], #
#  0x008e => ['---0x008e',          $SHORT,     1, undef                   ], #
#  0x0090 => ['---0x0090',          $SHORT,     1, undef                   ], #
#  0x0092 => ['---0x0092',          $SHORT,     1, undef                   ], #
#  0x0094 => ['---0x0094',          $SHORT,     1, undef                   ], #
#  0x0096 => ['---0x0096',          $SHORT,     1, undef                   ], #
#  0x0098 => ['---0x0098',          $SHORT,     1, undef                   ], #
#  0x009a => ['---0x009a',          $SHORT,     1, undef                   ], #
#  0x009c => ['rest',               $UNDEF,   752, undef                   ], #
};
#----------------------------------------------------------------------------#
$$HASH_MAKERNOTES{'Kyocera'}{'tags'} =                                       #
{ 0x0001 => ['Thumbnail',          $UNDEF, undef, undef                   ], #
  0x0e00 => ['PrintIM_Data',       $UNDEF, undef, undef                ], }; # 
#----------------------------------------------------------------------------#
$$HASH_MAKERNOTES{'Minolta_1'}{'tags'} =				     #
{ 0x0000 => ['MakerNoteVersion',   $UNDEF,     4, 'MLT0'                  ], #
  0x0200 => ['SpecialMode',        $LONG,      3, $IFD_integer            ], #
  0x0201 => ['Quality',            $SHORT,     3, undef                   ], #
  0x0202 => ['MacroMode',          $SHORT,     1, '[012]'                 ], #
  0x0203 => [ undef,               $SHORT,     1, undef                   ], #
  0x0204 => ['DigitalZoom',        $RATIONAL,  1, $IFD_integer            ], #
  0x020e => [ undef,               $SHORT,     1, undef                   ], #
  0x020f => [ undef,               $SHORT,     1, undef                   ], #
  0x0210 => [ undef,               $SHORT,     1, undef                   ], #
  0x0211 => [ undef,               $SHORT,     1, undef                   ], #
  0x0212 => [ undef,               $SHORT,     1, undef                   ], #
  0x0213 => [ undef,               $SHORT,     1, undef                   ], #
  0x0214 => [ undef,               $SHORT,     1, undef                   ], #
  0x0215 => [ undef,               $SHORT,     1, undef                   ], #
  0x0216 => [ undef,               $SHORT,     1, undef                   ], #
  0x0217 => [ undef,               $SHORT,     1, undef                   ], #
  0x0218 => [ undef,               $SHORT,     1, undef                   ], #
  0x0219 => [ undef,               $SHORT,     1, undef                   ], #
  0x021a => [ undef,               $SHORT,     1, undef                   ], #
  0x021b => [ undef,               $SHORT,     1, undef                   ], #
  0x021c => [ undef,               $SHORT,     1, undef                   ], #
  0x021d => ['ManualWhiteBalance', $SHORT,     1, undef                   ], #
  0x021e => [ undef,               $SHORT,     1, undef                   ], #
  0x021f => [ undef,               $SHORT,     1, undef                   ], #
  0x0e00 => ['PrintIM_Data',       $UNDEF, undef, undef                   ], # 
  0x0f00 => ['DataDump',           $UNDEF, undef, undef                ], }; #
#----------------------------------------------------------------------------#
$$HASH_MAKERNOTES{'Minolta_2'}{'tags'} =				     #
{ 0x0000 => ['MakerNoteVersion',   $UNDEF,     4, 'MLT0'                  ], #
  0x0001 => ['CameraSettingsOld',  $UNDEF, undef, '.*'                    ], #
  0x0003 => ['CameraSettingsNew',  $UNDEF, undef, '.*'                    ], #
  0x0010 => [ undef,               $UNDEF, undef, '.*'                    ], #
  0x0020 => [ undef,               $UNDEF, undef, '.*'                    ], #
  0x0040 => ['CompressedImageSize',$LONG,      1, $IFD_integer            ], #
  0x0081 => ['Thumbnail',          $UNDEF, undef, '.*'                    ], #
  0x0088 => ['ThumbnailOffset',    $LONG,      1, $IFD_integer            ], #
  0x0089 => ['ThumbnailLength',    $LONG,      1, $IFD_integer            ], #
  0x0100 => [ undef,               $LONG,      1, $IFD_integer            ], #
  0x0101 => ['ColourMode',         $LONG,      1, '[0-4]'                 ], #
  0x0102 => ['ImageQuality_1',     $LONG,      1, '[0-35]'                ], #
  0x0103 => ['ImageQuality_2',     $LONG,      1, '[0-35]'                ], #
  0x0e00 => ['PrintIM_Data',       $UNDEF, undef, undef                   ], # 
  0x0f00 => [ undef,               $UNDEF, undef, undef                ], }; #
#----------------------------------------------------------------------------#
$$HASH_MAKERNOTES{'Nikon_1'}{'tags'} =				             #
{ 0x0002 => [ undef,               $ASCII,     6, '(09\.41|08\.00)\000'   ], #
  0x0003 => ['Quality',            $SHORT,     1, '([1-9]|1[0-2])'        ], #
  0x0004 => ['ColorMode',          $SHORT,     1, '[12]'                  ], #
  0x0005 => ['ImageAdjustment',    $SHORT,     1, '[0-4]'                 ], #
  0x0006 => ['CCDSensitivity',     $SHORT,     1, '[0245]'                ], #
  0x0007 => ['WhiteBalance',       $SHORT,     1, '[0-6]'                 ], #
  0x0008 => ['Focus',              $RATIONAL,  1, $IFD_integer            ], #
  0x0009 => [ undef,               $ASCII,    20, $IFD_Cstring            ], #
  0x000a => ['DigitalZoom',        $RATIONAL,  1, $IFD_integer            ], #
  0x000b => ['Converter',          $SHORT,     1, '[01]'                  ], #
  0x0f00 => [ undef,               $LONG,  undef, $IFD_integer         ], }; #
#----------------------------------------------------------------------------#
$$HASH_MAKERNOTES{'Nikon_2'}{'tags'} =                                       #
{ 0x0001 => ['MakerNoteVersion',   $UNDEF,     4, '\000\001\000{2}'       ], #
  0x0002 => ['ISOSetting',         $SHORT,     2, $IFD_integer            ], #
  0x0003 => ['ColourMode',         $ASCII, undef, '(COLOR|B&W)\000'       ], #
  0x0004 => ['Quality',            $ASCII, undef,'(NORMAL|FINE|BASIC)\000'], #
  0x0005 => ['WhiteBalance',       $ASCII, undef,'(AUTO|WHITE PRESET)\000'], #
  0x0006 => ['ImageSharpening',    $ASCII, undef, '(AUTO|HIGH)\000'       ], #
  0x0007 => ['FocusMode',          $ASCII, undef, '(AF-S|AF-C)\000'       ], #
  0x0008 => ['FlashSetting',       $ASCII, undef, '(NORMAL|RED-EYE)\000'  ], #
  0x0009 => ['AutoFlashMode',      $ASCII, undef, $IFD_Cstring            ], #
  0x000a => [ undef,               $RATIONAL,  1, undef                   ], #
  0x000b => ['WhiteBalanceBias',   $SHORT,     2, undef                   ], #
  0x000c => ['WhiteBalanceRedBlue',$SHORT,     2, undef                   ], #
  0x000f => ['ISOSelection',       $ASCII, undef, '(MANUAL|AUTO)\000'     ], #
  0x0010 => ['DataDump',           $UNDEF,   174, undef                   ], #
  0x0011 => [ undef,               $LONG,      1, $IFD_integer            ], #
  0x0012 => ['FlashCompensation',  $SSHORT,    1, $IFD_signed             ], #
  0x0013 => ['ISOSpeedRequested',  $SHORT,     2, undef                   ], #
  0x0016 => ['PhotoCornerCoord',   $SHORT,     4, $IFD_integer            ], #
  0x0018 => ['FlashBracketComp',   $SSHORT,    1, $IFD_signed             ], #
  0x0019 => ['AEBracketComp',      $SHORT,     1, undef                   ], #
  0x0080 => ['ImageAdjustment',    $ASCII, undef, '(AUTO|NORMAL)\000'     ], #
  0x0081 => ['ToneContrast',       $ASCII, undef, $IFD_Cstring            ], #
  0x0082 => ['Adapter',            $ASCII, undef, '(OFF|WIDE ADAPTER)'    ], #
  0x0083 => ['LensType',           $ASCII, undef, $IFD_Cstring            ], #
  0x0084 => ['MaxAperture',        $ASCII, undef, $IFD_Cstring            ], #
  0x0085 => ['ManualFocusDistance',$RATIONAL,  1, $IFD_integer            ], #
  0x0086 => ['DigitalZoom',        $RATIONAL,  1, $IFD_integer            ], #
  0x0087 => ['FlashUsed',          $SHORT,     1, '[09]'                  ], #
  0x0088 => ['AFFocusPosition',    $UNDEF,    4,'[\000-\002][\000-\004]..'], #
  0x0089 => ['BracketShotMode',    $BYTE,      1, undef                   ], #
  0x008d => ['ColourMode2',        $ASCII, undef, '(1a|2|3a)\000'         ], #
  0x008e => ['SceneMode',          $SHORT,     1, undef                   ], #
  0x008f => ['LightingType',       $ASCII, undef, $IFD_Cstring            ], #
  0x0092 => ['HueAdjustment',      $SHORT,     1, undef                   ], #
  0x0094 => ['Saturation',         $SSHORT,    1, '(-[1-3]|[0-2])'        ], #
  0x0095 => ['NoiseReduction',     $ASCII, undef, '(FPNR)\000'            ], #
  0x00a7 => ['ShutterReleases',    $SHORT,     1, $IFD_integer            ], #
  0x00a9 => ['ImageOptimisation',  $ASCII, undef, $IFD_Cstring            ], #
  0x00aa => ['Saturation',         $ASCII, undef, $IFD_Cstring            ], #
  0x00ab => ['DigitalVariProgram', $ASCII, undef, undef                   ], #
  0x0e00 => ['PrintIM_Data',       $UNDEF, undef, undef                   ], #
  0x0e10 => [ undef,               $LONG,      1, $IFD_integer         ], }; # 
#----------------------------------------------------------------------------#
$$HASH_MAKERNOTES{'Nikon_3'}{'tags'} =                                       #
{ 0x0001 => ['MakerNoteVersion',   $UNDEF,     4, '0200'                  ], #
  0x0002 => ['ISOSetting',         $SHORT,     2, $SSR_ISOsetting,        ], #
  0x0004 => ['WhiteBalance',       $ASCII, undef, '(AUTO|CLOUDY|...)'     ], #
  0x0005 => ['Sharpness',          $ASCII, undef, '(AUTO|LOW|MED.L|...)'  ], #
  0x0006 => ['FocusMode',          $ASCII, undef, '(MANUAL|AF-S|AF-C)\000'], #
  0x0007 => ['FlashMode',          $ASCII, undef, '(NORMAL|RED-EYE|...)'  ], #
  0x0008 => ['AutomaticISO ?',     $ASCII, undef, undef                   ], #
  0x0009 => ['FlashMetering',      $ASCII, undef, undef                   ], #
  0x000b => [ undef,               $SSHORT,    1, undef                   ], #
  0x000c => [ undef,               $RATIONAL,  4, $IFD_integer            ], #
  0x000d => [ undef,               $UNDEF,     4, undef                   ], #
  0x000e => [ undef,               $UNDEF,     4, undef                   ], #
  0x0011 => [ undef,               $LONG,      1, $IFD_integer            ], #
  0x0012 => ['FlashBias ?',        $UNDEF,     4, undef                   ], #
  0x0013 => ['ISOSettingStart ?',  $SHORT,     2, $SSR_ISOsetting         ], #
  0x0016 => [ undef,               $SHORT,     4, $IFD_integer            ], #
  0x0017 => [ undef,               $UNDEF,     4, undef                   ], #
  0x0018 => [ undef,               $UNDEF,     4, undef                   ], #
  0x0019 => ['Contrast',           $SRATIONAL, 1, $IFD_integer            ], #
  0x0081 => [ undef,               $ASCII, undef, undef                   ], #
  0x0083 => [ undef,               $BYTE,      1, undef                   ], #
  0x0084 => ['Lens',               $RATIONAL,  4, undef                   ], #
  0x0087 => ['Flash 2 ?',          $BYTE,      1, undef                   ], #
  0x0088 => ['ActiveAFSensor',     $UNDEF,     4, undef                   ], #
  0x0089 => [ undef,               $BYTE,      1, undef                   ], #
  0x008a => [ undef,               $SHORT,     1, undef                   ], #
  0x008b => [ undef,               $UNDEF,     4, undef                   ], #
  0x008c => [ undef,               $UNDEF, undef, undef                   ], #
  0x008d => ['ColourMode',         $ASCII, undef, undef                   ], #
  0x0090 => ['FlashType',          $ASCII, undef, undef                   ], #
  0x0091 => [ undef,               $UNDEF, undef, undef                   ], #
  0x0092 => [ undef,               $SSHORT,    1, undef                   ], #
  0x0095 => [ undef,               $ASCII, undef, undef                   ], #
  0x0097 => [ undef,               $UNDEF, undef, undef                   ], #
  0x0098 => [ undef,               $UNDEF, undef, undef                   ], #
  0x0099 => [ undef,               $SHORT,     2, undef                   ], #
  0x009a => [ undef,               $RATIONAL,  2, undef                   ], #
  0x00a0 => [ undef,               $ASCII, undef, undef                   ], #
  0x00a2 => [ undef,               $LONG,      1, undef                   ], #
  0x00a3 => [ undef,               $BYTE,      1, undef                   ], #
  0x00a5 => [ undef,               $LONG,      1, undef                   ], #
  0x00a6 => [ undef,               $LONG,      1, undef                   ], #
  0x00a7 => ['PictureNumber',      $LONG,      1, undef                   ], #
  0x00a8 => ['ExposureMode',       $UNDEF, undef, '(NORM|SHAR|SOFT|...)'  ], #
  0x00a9 => [ undef,               $ASCII, undef, undef                   ], #
  0x00aa => [ undef,               $ASCII, undef, undef                   ], #
  0x00ab => [ undef,               $ASCII, undef, undef                   ], #
  0x0e08 => [ undef,               $SHORT,     1, undef                   ], #
  0x0e09 => [ undef,               $ASCII, undef, undef                   ], #
  0x0e10 => [ undef,               $LONG,      1, undef                ], }; #
#----------------------------------------------------------------------------#
$$HASH_MAKERNOTES{'Olympus'}{'tags'} =                                       #
{ 0x0100 => ['JPEGThumbnail',      $UNDEF, undef, '\377\330\377.*'        ], #
  0x0200 => ['SpecialMode',        $LONG,      3, $IFD_integer            ], #
  0x0201 => ['JpegQuality',        $SHORT,     1, '[123]'                 ], #
  0x0202 => ['Macro',              $SHORT,     1, '[012]'                 ], #
  0x0203 => [ undef,               $SHORT,     1, undef                   ], #
  0x0204 => ['DigitalZoom',        $RATIONAL,  1, $IFD_integer            ], #
  0x0205 => [ undef,               $RATIONAL,  1, undef                   ], #
  0x0206 => [ undef,               $SSHORT,    6, undef                   ], #
  0x0207 => ['SoftwareRelease',    $ASCII,     5, '[A-Z0-9]*'             ], #
  0x0208 => ['PictureInfo',        $ASCII, undef, '[\040-\176]*'          ], #
  0x0209 => ['CameraID',           $UNDEF, undef, '.*'                    ], #
  0x0300 => [ undef,               $SHORT,     1, undef                   ], #
  0x0301 => [ undef,               $SHORT,     1, undef                   ], #
  0x0302 => [ undef,               $SHORT,     1, undef                   ], #
  0x0303 => [ undef,               $SHORT,     1, undef                   ], #
  0x0304 => [ undef,               $SHORT,     1, undef                   ], #
  0x0f00 => ['DataDump',           $UNDEF, undef, undef                   ], #
  0x1000 => [ undef,               $SRATIONAL, 1, undef                   ], #
  0x1001 => [ undef,               $SRATIONAL, 1, undef                   ], #
  0x1002 => [ undef,               $SRATIONAL, 1, undef                   ], #
  0x1003 => [ undef,               $SRATIONAL, 1, undef                   ], #
  0x1004 => ['FlashMode',          $SHORT,     1, undef                   ], #
  0x1005 => [ undef,               $SHORT,     2, undef                   ], #
  0x1006 => ['Bracket',            $SRATIONAL, 1, undef                   ], #
  0x1007 => [ undef,               $SSHORT,    1, undef                   ], #
  0x1008 => [ undef,               $SSHORT,    1, undef                   ], #
  0x1009 => [ undef,               $SHORT,     1, undef                   ], #
  0x100a => [ undef,               $SHORT,     1, undef                   ], #
  0x100b => ['FocusMode',          $SHORT,     1, undef                   ], #
  0x100c => ['FocusDistance',      $RATIONAL,  1, undef                   ], #
  0x100d => ['Zoom',               $SHORT,     1, undef                   ], #
  0x100e => ['MacroFocus',         $SHORT,     1, undef                   ], #
  0x100f => ['Sharpness',          $SHORT,     1, undef                   ], #
  0x1010 => [ undef,               $SHORT,     1, undef                   ], #
  0x1011 => ['ColourMatrix',       $SHORT,     9, undef                   ], #
  0x1012 => ['BlackLevel',         $SHORT,     4, undef                   ], #
  0x1013 => [ undef,               $SHORT,     1, undef                   ], #
  0x1014 => [ undef,               $SHORT,     1, undef                   ], #
  0x1015 => ['WhiteBalance',       $SHORT,     2, undef                   ], #
  0x1016 => [ undef,               $SHORT,     1, undef                   ], #
  0x1017 => ['RedBias',            $SHORT,     2, undef                   ], #
  0x1018 => ['BlueBias',           $SHORT,     2, undef                   ], #
  0x1019 => [ undef,               $SHORT,     1, undef                   ], #
  0x101a => ['SerialNumber',       $ASCII,    32, '[\040-\176].*\000*'    ], #
  0x101b => [ undef,               $LONG,      1, undef                   ], #
  0x101c => [ undef,               $LONG,      1, undef                   ], #
  0x101d => [ undef,               $LONG,      1, undef                   ], #
  0x101e => [ undef,               $LONG,      1, undef                   ], #
  0x101f => [ undef,               $LONG,      1, undef                   ], #
  0x1020 => [ undef,               $LONG,      1, undef                   ], #
  0x1021 => [ undef,               $LONG,      1, undef                   ], #
  0x1022 => [ undef,               $LONG,      1, undef                   ], #
  0x1023 => ['FlashBias',          $SRATIONAL, 1, undef                   ], #
  0x1024 => [ undef,               $SHORT,     1, undef                   ], #
  0x1025 => [ undef,               $SRATIONAL, 1, undef                   ], #
  0x1026 => [ undef,               $SHORT,     1, undef                   ], #
  0x1027 => [ undef,               $SHORT,     1, undef                   ], #
  0x1028 => [ undef,               $SHORT,     1, undef                   ], #
  0x1029 => ['Contrast',           $SHORT,     1, undef                   ], #
  0x102a => ['SharpnessFactor',    $SHORT,     1, undef                   ], #
  0x102b => ['ColourControl',      $SHORT,     6, undef                   ], #
  0x102c => ['ValidBits',          $SHORT,     2, undef                   ], #
  0x102d => ['CoringFilter',       $SHORT,     1, undef                   ], #
  0x102e => ['FinalWidth',         $LONG,      1, undef                   ], #
  0x102f => ['FinalHeight',        $LONG,      1, undef                   ], #
  0x1030 => [ undef,               $SHORT,     1, undef                   ], #
  0x1031 => [ undef,               $LONG,      8, undef                   ], #
  0x1032 => [ undef,               $SHORT,     1, undef                   ], #
  0x1033 => [ undef,               $LONG,    720, undef                   ], #
  0x1034 => ['CompressionRatio',   $RATIONAL,  1, undef                   ], #
  0x1035 => [ undef,               $LONG,      1, undef                   ], #
  0x1036 => [ undef,               $LONG,      1, undef                   ], #
  0x1037 => [ undef,               $LONG,      1, undef                   ], #
  0x1038 => [ undef,               $SHORT,     1, undef                   ], #
  0x1039 => [ undef,               $SHORT,     1, undef                   ], #
  0x103a => [ undef,               $SHORT,     1, undef                   ], #
  0x103b => [ undef,               $SHORT,     1, undef                   ], #
  0x103c => [ undef,               $SHORT,     1, undef                ], }; #
#----------------------------------------------------------------------------#
$$HASH_MAKERNOTES{'Panasonic_1'}{'tags'} =                                   #
{ 0x0001 => ['ImageQuality',       $SHORT,     1, '[23]'                  ], #
  0x0002 => ['FirmwareVersion',    $UNDEF,     4, '010\d'                 ], #
  0x0003 => ['WhiteBalance',       $SHORT,     1, '[1-58]'                ], #
  0x0007 => ['FocusMode',          $SHORT,     1, '[12]'                  ], #
  0x000f => ['SpotMode',           $BYTE,      2, undef                   ], #
  0x001a => ['ImageStabilizer',    $SHORT,     1, '[2-4]'                 ], #
  0x001c => ['MacroMode',          $SHORT,     1, '[129]'                 ], #
  0x001f => ['ShootingMode',       $SHORT,     1, '([2-9]|1[1389]|2[01])' ], #
  0x0020 => ['Audio',              $SHORT,     1, '[12]'                  ], #
  0x0021 => [ undef,               $UNDEF, undef, undef                   ], #
  0x0022 => [ undef,               $SHORT,     1, undef                   ], #
  0x0023 => ['WhiteBalanceAdjust', $SHORT,     1, $IFD_integer            ], #
  0x0024 => ['FlashBias',          $SHORT,     1, $IFD_integer            ], #
  0x0025 => [ undef,               $UNDEF,    16, undef                   ], #
  0x0026 => [ undef,               $UNDEF,     4, '0100'                  ], #
  0x0027 => [ undef,               $SHORT,     1, undef                   ], #
  0x0028 => ['ColourEffect',       $SHORT,     1, '[1-5]'                 ], #
  0x0029 => [ undef,               $LONG,      1, undef                   ], #
  0x002a => [ undef,               $SHORT,     1, undef                   ], #
  0x002b => [ undef,               $LONG,      1, undef                   ], #
  0x002c => ['Contrast',           $SHORT,     1, '[012]'                 ], #
  0x002d => ['NoiseReduction',     $SHORT,     1, '[012]'                 ], #
  0x002e => [ undef,               $SHORT,     1, undef                   ], #
  0x002f => [ undef,               $SHORT,     1, undef                   ], #
  0x0e00 => ['PrintIM_Data',       $UNDEF, undef, undef                   ], # 
  0x4449 => [ undef,               $UNDEF,   512, undef                ], }; #
#----------------------------------------------------------------------------#
$$HASH_MAKERNOTES{'Pentax_1'}{'tags'} =                                      #
{ 0x0001 => ['CaptureMode',        $SHORT,     1, '[0-4]'                 ], #
  0x0002 => ['QualityLevel',       $SHORT,     1, '[0-2]'                 ], #
  0x0003 => ['FocusMode',          $SHORT,     1, '[23]'                  ], #
  0x0004 => ['FlashMode',          $SHORT,     1, '[1246]'                ], #
  0x0005 => [ undef,               $SHORT,     1, undef                   ], #
  0x0006 => [ undef,               $LONG,      1, undef                   ], #
  0x0007 => ['WhiteBalance',       $SHORT,     1, '[0-5]'                 ], #
  0x0008 => [ undef,               $SHORT,     1, undef                   ], #
  0x0009 => [ undef,               $SHORT,     1, undef                   ], #
  0x000a => ['DigitalZoom',        $LONG,      1, $IFD_integer            ], #
  0x000b => ['Sharpness',          $SHORT,     1, '[012]'                 ], #
  0x000c => ['Contrast',           $SHORT,     1, '[012]'                 ], #
  0x000d => ['Saturation',         $SHORT,     1, '[012]'                 ], #
  0x000e => [ undef,               $SHORT,     1, undef                   ], #
  0x000f => [ undef,               $LONG,      1, undef                   ], #
  0x0010 => [ undef,               $SHORT,     1, undef                   ], #
  0x0011 => [ undef,               $LONG,      1, undef                   ], #
  0x0012 => [ undef,               $SHORT,     1, undef                   ], #
  0x0013 => [ undef,               $SHORT,     1, undef                   ], #
  0x0014 => ['ISOSpeed',           $SHORT,     1, '(10|16|100|200)'       ], #
  0x0015 => [ undef,               $SHORT,     1, undef                   ], #
  0x0017 => ['Colour',             $SHORT,     1, '[123]'                 ], #
  0x0018 => [ undef,               $LONG,      1, undef                   ], #
  0x0019 => [ undef,               $SHORT,     1, undef                   ], #
  0x0e00 => ['PrintIM_Data',       $UNDEF, undef, undef                   ], # 
  0x1000 => ['TimeZone',           $UNDEF,     4, undef                   ], #
  0x1001 => ['DaylightSavings',    $UNDEF,     4, undef                ], }; #
#----------------------------------------------------------------------------#
$$HASH_MAKERNOTES{'Pentax_2'}{'tags'} =                                      #
{ 0x0001 => [ undef,               $SHORT,     1, undef                   ], #
  0x0002 => [ undef,               $SHORT,     1, undef                   ], #
  0x0003 => [ undef,               $LONG,      1, undef                   ], #
  0x0004 => [ undef,               $LONG,      1, undef                   ], #
  0x0005 => [ undef,               $LONG,      1, undef                   ], #
  0x0006 => [ undef,               $UNDEF,     4, undef                   ], #
  0x0007 => [ undef,               $UNDEF,     3, undef                   ], #
  0x0008 => [ undef,               $SHORT,     1, undef                   ], #
  0x0009 => [ undef,               $SHORT,     1, undef                   ], #
  0x000a => [ undef,               $SHORT,     1, undef                   ], #
  0x000b => [ undef,               $SHORT,     1, undef                   ], #
  0x000c => [ undef,               $SHORT,     1, undef                   ], #
  0x000d => [ undef,               $SHORT,     1, undef                   ], #
  0x000e => [ undef,               $SHORT,     1, undef                   ], #
  0x000f => [ undef,               $SHORT,     1, undef                   ], #
  0x0010 => [ undef,               $SHORT,     1, undef                   ], #
  0x0011 => [ undef,               $SHORT,     1, undef                   ], #
  0x0012 => [ undef,               $LONG,      1, undef                   ], #
  0x0013 => [ undef,               $SHORT,     1, undef                   ], #
  0x0014 => [ undef,               $SHORT,     1, undef                   ], #
  0x0015 => [ undef,               $SHORT,     1, undef                   ], #
  0x0016 => [ undef,               $SHORT,     1, undef                   ], #
  0x0017 => [ undef,               $SHORT,     1, undef                   ], #
  0x0018 => [ undef,               $SHORT,     1, undef                   ], #
  0x0019 => [ undef,               $SHORT,     1, undef                   ], #
  0x001a => [ undef,               $SHORT,     1, undef                   ], #
  0x001b => [ undef,               $SHORT,     1, undef                   ], #
  0x001c => [ undef,               $SHORT,     1, undef                   ], #
  0x001d => [ undef,               $LONG,      1, undef                   ], #
  0x001e => [ undef,               $SHORT,     1, undef                   ], #
  0x001f => [ undef,               $SHORT,     1, undef                   ], #
  0x0020 => [ undef,               $SHORT,     1, undef                   ], #
  0x0021 => [ undef,               $SHORT,     1, undef                   ], #
  0x0022 => [ undef,               $SHORT,     1, undef                   ], #
  0x0023 => [ undef,               $SHORT,     1, undef                   ], #
  0x0024 => [ undef,               $SHORT,     1, undef                   ], #
  0x0025 => [ undef,               $SHORT,     1, undef                   ], #
  0x0026 => [ undef,               $SHORT,     1, undef                   ], #
  0x0027 => [ undef,               $UNDEF,     4, undef                   ], #
  0x0028 => [ undef,               $UNDEF,     4, undef                   ], #
  0x0029 => [ undef,               $LONG,      1, undef                ], }; #
#----------------------------------------------------------------------------#
$$HASH_MAKERNOTES{'Ricoh_3'}{'tags'} =                                       #
{ 0x0001 => ['DataType',           $ASCII, undef, undef                   ], #
  0x0002 => ['FirmwareVersion',    $ASCII, undef, 'Rev\d{4}'              ], #
  0x0003 => [ undef,               $LONG,      4, undef                   ], #
  0x0005 => [ undef,               $UNDEF, undef, undef                   ], #
  0x0006 => [ undef,               $UNDEF, undef, undef                   ], #
  0x0e00 => ['PrintIM_Data',       $UNDEF, undef, undef                   ], # 
  0x1001 => [ undef,               $UNDEF, undef, undef                   ], #
  0x1002 => [ undef,               $LONG,      1, undef                   ], #
  0x1003 => [ undef,               $LONG,      1, undef                   ], #
  0x2001 => ['CameraInfoIFD',      $UNDEF, undef,'\[Ricoh Camera Info\].*'] };
#----------------------------------------------------------------------------#
$$HASH_MAKERNOTES{'Sanyo'}{'tags'} =                                         #
{ 0x0100 => ['JPEGThumbnail',      $UNDEF, undef, '\377\330\377.*'        ], #
  0x0200 => ['SpecialMode',        $LONG,      3, $IFD_integer            ], #
  0x0201 => ['JPEGQuality',        $SHORT,     1, '[\000-\007][\000-\002]'], #
  0x0202 => ['Macro',              $SHORT,     1, '[0-3]'                 ], #
  0x0203 => [ undef,               $SHORT,     1, '[0]'                   ], #
  0x0204 => ['DigitalZoom',        $RATIONAL,  1, $IFD_integer            ], #
  0x0207 => ['SoftwareRelease',    $ASCII, undef, $IFD_Cstring            ], #
  0x0208 => ['PictInfo',           $ASCII, undef, '[\040-\176]*'          ], #
  0x0209 => ['CameraID',           $UNDEF,    32, '.*'                    ], #
  0x020e => ['SequentShotMethod',  $SHORT,     1, '[0-3]'                 ], #
  0x020f => ['WideRange',          $SHORT,     1, '[01]'                  ], #
  0x0210 => ['ColourAdjustMode',   $SHORT,     1, $IFD_integer            ], #
  0x0213 => ['QuickShot',          $SHORT,     1, '[01]'                  ], #
  0x0214 => ['SelfTimer',          $SHORT,     1, '[01]'                  ], #
  0x0216 => ['VoiceMemo',          $SHORT,     1, '[01]'                  ], #
  0x0217 => ['RecShutterRelease',  $SHORT,     1, '[01]'                  ], #
  0x0218 => ['FlickerReduce',      $SHORT,     1, '[01]'                  ], #
  0x0219 => ['OpticalZoom',        $SHORT,     1, '[01]'                  ], #
  0x021b => ['DigitalZoom',        $SHORT,     1, '[01]'                  ], #
  0x021d => ['LightSourceSpecial', $SHORT,     1, '[01]'                  ], #
  0x021e => ['Resaved',            $SHORT,     1, '[01]'                  ], #
  0x021f => ['SceneSelect',        $SHORT,     1, '[0-5]'                 ], #
  0x0223 => ['ManualFocalDistance',$RATIONAL,  1, $IFD_integer            ], #
  0x0224 => ['SequentShotInterval',$SHORT,     1, '[0-3]'                 ], #
  0x0225 => ['FlashMode',          $SHORT,     1, '[0-3]'                 ], #
  0x0e00 => ['PrintIM_Data',       $UNDEF, undef, undef                   ], #
  0x0f00 => ['DataDump',           $LONG,  undef, undef                ], }; #
#----------------------------------------------------------------------------#
$$HASH_MAKERNOTES{'Sigma'}{'tags'} =                                         #
{ 0x0002 => ['CameraSerialNumber', $ASCII, undef, '\d*'                   ], #
  0x0003 => ['DriveMode',          $ASCII, undef, '(SINGLE|Burst)\000'    ], #
  0x0004 => ['ResolutionMode',     $ASCII, undef, '(HI|MED|LO)\000'       ], #
  0x0005 => ['AutofocusMode',      $ASCII, undef, '(AF-S|AF-C)\000'       ], #
  0x0006 => ['FocusSetting',       $ASCII, undef, '(AF|M)\000'            ], #
  0x0007 => ['WhiteBalance',       $ASCII, undef, '(Auto|Sunlight)\000'   ], #
  0x0008 => ['ExposureMode',       $ASCII,     2, '(P|A|S|M)\000'         ], #
  0x0009 => ['MeteringMode',       $ASCII,     2, '(A|C|8)\000'           ], #
  0x000a => ['FocalLengthRange',   $ASCII, undef, $IFD_Cstring            ], #
  0x000b => ['ColorSpace',         $ASCII, undef, '(sRGB)\000'            ], #
  0x000c => ['Exposure',           $ASCII,    10, 'Expo:[+-]0.\d\000'     ], #
  0x000d => ['Contrast',           $ASCII,    10, 'Cont:[+-]0.\d\000'     ], #
  0x000e => ['Shadow',             $ASCII,    10, 'Shad:[+-]0.\d\000'     ], #
  0x000f => ['Highlight',          $ASCII,    10, 'High:[+-]0.\d\000'     ], #
  0x0010 => ['Saturation',         $ASCII,    10, 'Satu:[+-]0.\d\000'     ], #
  0x0011 => ['Sharpness',          $ASCII,    10, 'Shar:[+-]0.\d\000'     ], #
  0x0012 => ['X3FillLight',        $ASCII,    10, 'Fill:[+-]0.\d\000'     ], #
  0x0014 => ['ColorAdjustment',    $ASCII,     9, 'CC:\d.[+-]\d.\000'     ], #
  0x0015 => ['AdjustmentMode',     $ASCII, undef, '(Custom|Auto) Se.*\000'], #
  0x0016 => ['Quality',            $ASCII, undef, 'Qual:\d\d\000'         ], #
  0x0017 => ['Firmware',           $ASCII, undef, '[\d\.]* Release\000'   ], #
  0x0018 => ['Software',           $ASCII, undef, 'SIGMA .* [\d\.]*\000'  ], #
  0x0019 => ['AutoBracket',        $ASCII, undef, $IFD_Cstring         ], }; #
#----------------------------------------------------------------------------#
$$HASH_MAKERNOTES{'Sony'}{'tags'} =                                          #
{ 0x0e00 => ['PrintIM_Data',       $UNDEF, undef, undef                 ],}; # 
#----------------------------------------------------------------------------#
$$HASH_MAKERNOTES{'Foveon'}{'tags'} = $$HASH_MAKERNOTES{'Sigma'}{'tags'};    #


#### Erase unknown fields, for the time being
#### Also add non-numeric tags for all notes
for my $name (keys %$HASH_MAKERNOTES) {
    my $hash = $$HASH_MAKERNOTES{$name}{'tags'};
    %$hash = map { defined ${$$hash{$_}}[0] ?
		       ($_ => $$hash{$_}) : () } keys %$hash;
}

#============================================================================#
# Return the hash reference to Tables.pm                                     #
#============================================================================#
$HASH_MAKERNOTES
