###########################################################
# A Perl package for showing/modifying JPEG (meta)data.   #
# Copyright (C) 2004,2005,2006 Stefano Bettelli           #
# See the COPYING and LICENSE files for license terms.    #
###########################################################
package Image::MetaData::JPEG::data::Tables;
use Exporter 'import';
use strict;
use warnings;
no  integer;

#============================================================================#
#============================================================================#
#============================================================================#
# This section defines the export policy of this module; no variable or      #
# method is exported by default. Everything is exportable via %EXPORT_TAGS.  #
#----------------------------------------------------------------------------#
our @ISA         = qw(Exporter);                                             #
our @EXPORT      = qw();                                                     #
our @EXPORT_OK   = qw();                                                     #
our %EXPORT_TAGS =                                                           #
    (RecordTypes => [qw($NIBBLES $BYTE $ASCII $SHORT $LONG $RATIONAL),       #
		     qw($SBYTE $UNDEF $SSHORT $SLONG $SRATIONAL $FLOAT),     #
		     qw($DOUBLE $REFERENCE)],                                #
     RecordProps => [qw(@JPEG_RECORD_TYPE_NAME @JPEG_RECORD_TYPE_LENGTH),    #
		     qw(@JPEG_RECORD_TYPE_CATEGORY @JPEG_RECORD_TYPE_SIGN)], #
     Endianness  => [qw($NATIVE_ENDIANNESS $BIG_ENDIAN $LITTLE_ENDIAN)],     #
     JPEGgrammar => [qw($JPEG_PUNCTUATION %JPEG_MARKER $JPEG_SEG_MAX_LEN)],  #
     TagsAPP0    => [qw($APP0_JFIF_TAG $APP0_JFXX_TAG $APP0_JFXX_JPG),       #
		     qw($APP0_JFXX_1B $APP0_JFXX_3B $APP0_JFXX_PAL)],        #
     TagsAPP1_Exif=>[qw($APP1_TH_JPEG $APP1_TH_TIFF $APP1_TH_TYPE),          #
		     qw($APP1_EXIF_TAG $THJPEG_OFFSET $THJPEG_LENGTH),       #
		     qw($APP1_TIFF_SIG $THTIFF_OFFSET $THTIFF_LENGTH),       #
		     qw(%IFD_SUBDIRS $HASH_MAKERNOTES $MAKERNOTE_TAG)],      #
     TagsAPP1_XMP=> [qw($APP1_XMP_TAG $APP1_XMP_XPACKET_BEGIN),              #
                     qw($APP1_XMP_XPACKET_ID $APP1_XMP_META_NS),             #
		     qw($APP1_XMP_OUTER_RDF_NS)],                            #
     TagsAPP2    => [qw($APP2_FPXR_TAG $APP2_ICC_TAG)],                      #
     TagsAPP3    => [qw($APP3_EXIF_TAG %IFD_SUBDIRS)],                       #
     TagsAPP13   => [qw($APP13_PHOTOSHOP_IPTC $APP13_PHOTOSHOP_IDS),         #
		     qw($APP13_PHOTOSHOP_TYPE $APP13_IPTC_TAGMARKER),        #
		     qw($APP13_PHOTOSHOP_DIRNAME $APP13_IPTC_DIRNAME)],      #
     TagsAPP14   => [qw($APP14_PHOTOSHOP_IDENTIFIER)],                       #
     Lookups     => [qw(&JPEG_lookup)], );                                   #
#----------------------------------------------------------------------------#
Exporter::export_ok_tags(                                                    #
    qw(RecordTypes RecordProps Endianness JPEGgrammar),                      #
    qw(TagsAPP0 TagsAPP1_Exif TagsAPP1_XMP),                                 #
    qw(TagsAPP2 TagsAPP3 TagsAPP13 TagsAPP14 Lookups));                      #
#============================================================================#
#============================================================================#
#============================================================================#
# Constants for the grammar of a JPEG files. You can find here everything    #
# about segment markers as well as the JPEG puncutation mark. The maximum    #
# length of the data area of a standard JPEG segment is determined by the    #
# fact that the segment lenght must be written to a two bytes field (inclu-  #
# ding the two bytes themselves (so, it is 2^16 - 3).                        #
#----------------------------------------------------------------------------#
our $JPEG_SEG_MAX_LEN = 2**16 - 3; # data area max length for a std segment  #
our $JPEG_PUNCTUATION = 0xff; # constant prefixed to every JPEG marker       #
our %JPEG_MARKER =            # non-repetitive JPEG markers                  #
    (TEM => 0x01,  # for TEMporary private use in arithmetic coding          #
     DHT => 0xc4,  # Define Huffman Table(s)                                 #
     JPG => 0xc8,  # reserved for JPEG extensions                            #
     DAC => 0xcc,  # Define Arithmetic Coding Conditioning(s)                #
     SOI => 0xd8,  # Start Of Image                                          #
     EOI => 0xd9,  # End Of Image                                            #
     SOS => 0xda,  # Start Of Scan                                           #
     DQT => 0xdb,  # Define Quantization Table(s)                            #
     DNL => 0xdc,  # Define Number of Lines                                  #
     DRI => 0xdd,  # Define Restart Interval                                 #
     DHP => 0xde,  # Define Hierarchical Progression                         #
     EXP => 0xdf,  # EXPand reference component(s)                           #
     COM => 0xfe); # COMment block                                           #
#----------------------------------------------------------------------------#
# markers 0x02 --> 0xbf are REServed for future uses                         #
for (0x02..0xbf) { $JPEG_MARKER{sprintf "res%02x", $_} = $_; }               #
# some markers in 0xc0 --> 0xcf correspond to Start-Of-Frame typologies      #
for (0xc0..0xc3, 0xc5..0xc7, 0xc9..0xcb,                                     #
     0xcd..0xcf) { $JPEG_MARKER{sprintf "SOF_%d", $_ - 0xc0} = $_; }         #
# markers 0xd0 --> 0xd7 correspond to ReSTart with module 8 count            #
for (0xd0..0xd7) { $JPEG_MARKER{sprintf "RST%d", $_ - 0xd0} = $_; }          #
# markers 0xe0 --> 0xef are the APPlication markers                          #
for (0xe0..0xef) { $JPEG_MARKER{sprintf "APP%d", $_ - 0xe0} = $_; }          #
# markers 0xf0 --> 0xfd are reserved for JPEG extensions                     #
for (0xf0..0xfd) { $JPEG_MARKER{sprintf "JPG%d", $_ - 0xf0} = $_; }          #
#============================================================================#
#============================================================================#
#============================================================================#
# Functions for generating arrays (arg0=hashref, arg1=index) or references   #
# to lookup tables [hashes] (arg0=hashref,arg1=index) from hashes; it is     #
# assumed that the general hash they work on has array references as values. #
#----------------------------------------------------------------------------#
sub generate_lookup { my %a=map { $_ => $_[0]{$_}[$_[1]] } keys %{$_[0]}; \%a};
sub generate_array  { map { $_[0]{$_}[$_[1]] } (0..(-1+scalar keys %{$_[0]}))};
#============================================================================#
#============================================================================#
#============================================================================#
# Various lists for JPEG record names, lengths, categories and signs; see    #
# Image::MetaData::JPEG::Record class for further details. The general hash  #
# is private to this file, the other arrays are exported if so requested.    #
#----------------------------------------------------------------------------#
# I gave up trying to calculate the length of a reference. This is probably  #
# allocation dependent ... I use 0 here, meaning the length is variable.     #
#----------------------------------------------------------------------------#
my $RECORD_TYPE_GENERAL =                                                    #
{(our $NIBBLES   =  0) => [ 'NIBBLES'   , 1, 'I', 'N' ],                     #
 (our $BYTE      =  1) => [ 'BYTE'      , 1, 'I', 'N' ],                     #
 (our $ASCII     =  2) => [ 'ASCII'     , 0, 'S', 'N' ],                     #
 (our $SHORT     =  3) => [ 'SHORT'     , 2, 'I', 'N' ],                     #
 (our $LONG      =  4) => [ 'LONG'      , 4, 'I', 'N' ],                     #
 (our $RATIONAL  =  5) => [ 'RATIONAL'  , 8, 'R', 'N' ],                     #
 (our $SBYTE     =  6) => [ 'SBYTE'     , 1, 'I', 'Y' ],                     #
 (our $UNDEF     =  7) => [ 'UNDEF'     , 0, 'S', 'N' ],                     #
 (our $SSHORT    =  8) => [ 'SSHORT'    , 2, 'I', 'Y' ],                     #
 (our $SLONG     =  9) => [ 'SLONG'     , 4, 'I', 'Y' ],                     #
 (our $SRATIONAL = 10) => [ 'SRATIONAL' , 8, 'R', 'Y' ],                     #
 (our $FLOAT     = 11) => [ 'FLOAT'     , 4, 'F', 'N' ],                     #
 (our $DOUBLE    = 12) => [ 'DOUBLE'    , 8, 'F', 'N' ],                     #
 (our $REFERENCE = 13) => [ 'REFERENCE' , 0, 'p', 'N' ],    };               #
#----------------------------------------------------------------------------#
our @JPEG_RECORD_TYPE_NAME     = generate_array($RECORD_TYPE_GENERAL, 0);    #
our @JPEG_RECORD_TYPE_LENGTH   = generate_array($RECORD_TYPE_GENERAL, 1);    #
our @JPEG_RECORD_TYPE_CATEGORY = generate_array($RECORD_TYPE_GENERAL, 2);    #
our @JPEG_RECORD_TYPE_SIGN     = generate_array($RECORD_TYPE_GENERAL, 3);    #
#============================================================================#
#============================================================================#
#============================================================================#
# These tags are related to endianness. The endianness of the current        #
# machine is detected every time with a simple procedure.                    #
#----------------------------------------------------------------------------#
my ($__short, $__byte1, $__byte2) = unpack "SCC", "\111\333" x 2;            #
our $BIG_ENDIAN			= 'MM';                                      #
our $LITTLE_ENDIAN		= 'II';                                      #
our $NATIVE_ENDIANNESS = $__byte2 + ($__byte1<<8) == $__short ? $BIG_ENDIAN  #
    : $__byte1 + ($__byte2<<8) == $__short ? $LITTLE_ENDIAN : undef;         #
#----------------------------------------------------------------------------#
# various interesting constants which are not tags (mostly record values);   #
#----------------------------------------------------------------------------#
our $APP0_JFIF_TAG		= "JFIF\000";                                #
our $APP0_JFXX_TAG		= "JFXX\000";                                #
our $APP0_JFXX_JPG		= 0x10;                                      #
our $APP0_JFXX_1B		= 0x11;                                      #
our $APP0_JFXX_3B		= 0x13;                                      #
our $APP0_JFXX_PAL		= 768;                                       #
our $APP1_EXIF_TAG		= "Exif\000\000";                            #
our $APP1_XMP_TAG		= "http://ns.adobe.com/xap/1.0/\000";        #
our $APP1_XMP_XPACKET_ID        = 'W5M0MpCehiHzreSzNTczkc9d';                #
our $APP1_XMP_XPACKET_BEGIN     = "\x{FEFF}";                                #
our $APP1_XMP_META_NS           = 'adobe:ns:meta/';                          #
our $APP1_XMP_OUTER_RDF_NS      ='http://www.w3.org/1999/02/22-rdf-syntax-ns#';
our $APP1_TIFF_SIG		= 42;                                        #
our $APP1_TH_TIFF		= 1;                                         #
our $APP1_TH_JPEG		= 6;                                         #
our $APP2_FPXR_TAG		= "FPXR\000";                                #
our $APP2_ICC_TAG		= "ICC_PROFILE\000";                         #
our $APP3_EXIF_TAG		= "Meta\000\000";                            #
our $APP13_PHOTOSHOP_IDS        = ["Photoshop 3.0\000",'Adobe_Photoshop2.5:'];
our $APP13_PHOTOSHOP_TYPE	= ['8BIM', '8BPS', 'PHUT'];                  #
our $APP13_PHOTOSHOP_IPTC	= 0x0404;                                    #
our $APP13_PHOTOSHOP_DIRNAME    = 'Photoshop_RECORDS';                       #
our $APP13_IPTC_TAGMARKER	= 0x1c;                                      #
our $APP13_IPTC_DIRNAME         = 'IPTC_RECORD';                             #
our $APP14_PHOTOSHOP_IDENTIFIER	= 'Adobe';                                   #
#============================================================================#
#============================================================================#
#============================================================================#
# The following lines contain a list of general-purpose regular expressions, #
# which are used by the IFD, GPS ... and other sections. The only reason for #
# them being here is to avoid to do errors more than once ...                #
#----------------------------------------------------------------------------#
my $re_integer = '\d+';                       # a generic integer number     #
my $re_signed  = join('', '-?', $re_integer); # a generic signed integer num #
my $re_float   = '[+-]?\d+(|.\d+)';           # a generic floating point     #
my $re_Cstring = '.*\000';                    # a null-terminated string     #
my $re_yr18    = '(18|19|20)\d\d';            # YYYY (from 1800AD only ...)  #
my $re_year    = '\d{4}';                     # YYYY (from 0AD on)           #
my $re_month   = '(0[1-9]|1[0-2])';           # MM (month in 1-12)           #
my $re_day     = '(0[1-9]|[12]\d|3[01])';     # DD (day in 1-31)             #
my $re_hour    = '([01]\d|2[0-3])';           # HH (hour in 0-23)            #
my $re_minute  = '[0-5]\d';                   # MM (minute in 0-59)          #
my $re_second  = $re_minute;                  # SS (seconds like minutes)    #
my $re_zone    = join('',  $re_hour, $re_minute);             # HHMM         #
my $re_dt18    = join('',  $re_yr18, $re_month,  $re_day);    # YYYYMMDD     #
my $re_date    = join('',  $re_year, $re_month,  $re_day);    # YYYYMMDD     #
my $re_time    = join('',  $re_hour, $re_minute, $re_second); # HHMMSS       #
my $re_dt18_cl = join(':', $re_yr18, $re_month,  $re_day);    # YYYY:MM:DD   #
my $re_date_cl = join(':', $re_year, $re_month,  $re_day);    # YYYY:MM:DD   #
my $re_time_cl = join(':', $re_hour, $re_minute, $re_second); # HH:MM:SS     #
#============================================================================#
#============================================================================#
#============================================================================#
# Root level records for an Exif APP1 segment; we could avoid writing them   #
# down here, but this makes syntax checks easier. Also, mandatory tags are   #
# here just for reference, since I think they are already present, hence     #
# never used. See the tables for IFD0 and IFD1 for further details.          #
#--- Mandatory records for IFD0 and IFD1 (not calculated) -------------------#
my $HASH_APP1_ROOT_MANDATORY = {'Identifier'  => $APP1_EXIF_TAG,             #
				'Endianness'  => $BIG_ENDIAN,                #
				'Signature'   => $APP1_TIFF_SIG, };          #
#--- Legal records' list ----------------------------------------------------#
my $HASH_APP1_ROOT_GENERAL =                                                 #
{'Identifier'    => ['Idx-1', $ASCII, 6,     $APP1_EXIF_TAG, 'B'          ], #
 'Endianness'    => ['Idx-2', $UNDEF, 2,   "($BIG_ENDIAN|$LITTLE_ENDIAN)" ], #
 'Signature'     => ['Idx-3', $SHORT, 1,     $APP1_TIFF_SIG, 'B'          ], #
 'ThumbnailData' => ['Idx-4', $UNDEF, undef, '.*',           'T'       ], }; #
#============================================================================#
#============================================================================#
#============================================================================#
# Most tags in the following three lists are the same for IFD0 and IFD1,     #
# only the support level changes (some of them, indeed, must be present in   #
# both directories). See the relevant sections in the Image::MetaData::JPEG  #
# module perldoc page for further details on the %$HASH_APP1_IFD01_* hashes: #
#  MAIN       --> "Canonical Exif 2.2 and TIFF 6.0 tags for IFD0 and IFD1";  #
#  ADDITIONAL --> "Additional TIFF 6.0 tags not in Exif 2.2 for IFD0";       #
#  COMPANIES  --> "Exif tags assigned to companies for IFD0 and IFD1".       #
#----------------------------------------------------------------------------#
# The meaning of pseudo-regular-expressions is the following:                #
# - 'calculated': these tags must not be set by the final user (they are     #
#     created, if necessary, by the module itself [this is more reliable]).  #
# - 'obsoleted': this means that the corresponding tag is no more allowed.   #
# Some tags do not have a fixed type (for instance, they can be $SHORT or    #
# $LONG): in these cases, the most general type was chosen. Remember that    #
# some tags in the main hash table are mandatory.                            #
#----------------------------------------------------------------------------#
# Hash keys are numeric tags, here written in hexadecimal base.              #
# Fields: 0 -> name, 1 -> type, 2 -> count, 3 -> matching regular expression #
# 4 -> (optional) this tag can be set only together with the thumbnail       #
#----------------------------------------------------------------------------#
my $IFD_integer  = $re_integer;              # a generic integer number      #
my $IFD_signed   = $re_signed;               # a generic signed integer num  #
my $IFD_float    = $re_float;                # a generic floating point      #
my $IFD_Cstring  = $re_Cstring;              # a null-terminated string      #
my $IFD_dt_full  = $re_dt18_cl.' '.$re_time_cl; # YYYY:MM:DD HH:MM:SS        #
my $IFD_datetime = '('.$IFD_dt_full.'|    :  :     :  :  |\s{19})\000';      #
#--- Special screen rules for IFD0 and IFD1 ---------------------------------#
# a YCbCrSubSampling tag indicates the ratio of chrominance components. Its  #
# value can be only [2,1] (for YCbCr 4:2:2) or [2,2] (for YCbCr 4:2:0).      #
my $SSR_YCCsampl = sub { die unless $_[0] == 2 && $_[1] =~ /1|2/; };         #
#--- Mandatory records for IFD0 and IFD1 (not calculated) -------------------#
my $HASH_APP1_IFD01_MANDATORY = {'XResolution'               => [72, 1],     #
				 'YResolution'               => [72, 1],     #
				 'ResolutionUnit'            =>  2, };       #
my $HASH_APP1_IFD0_MANDATORY  = {%$HASH_APP1_IFD01_MANDATORY,                #
				 'YCbCrPositioning'          =>  1, };       #
my $HASH_APP1_IFD1_MANDATORY  = {%$HASH_APP1_IFD01_MANDATORY,                #
				 'YCbCrSubSampling'          => [2, 1],      #
				 'PhotometricInterpretation' =>  2,          #
				 'PlanarConfiguration'       =>  1, };       #
#--- Legal records' list ----------------------------------------------------#
my $HASH_APP1_IFD01_MAIN =                                                   #
{0x0100 => ['ImageWidth',                 $LONG,      1, $IFD_integer, 'T'], #
 0x0101 => ['ImageLength',                $LONG,      1, $IFD_integer, 'T'], #
 0x0102 => ['BitsPerSample',              $SHORT,     3, '8',          'T'], #
 0x0103 => ['Compression',                $SHORT,     1, '[16]',       'T'], #
 0x0106 => ['PhotometricInterpretation',  $SHORT,     1, '[26]',          ], #
 0x010e => ['ImageDescription',           $ASCII, undef, $IFD_Cstring     ], #
 0x010f => ['Make',                       $ASCII, undef, $IFD_Cstring     ], #
 0x0110 => ['Model',                      $ASCII, undef, $IFD_Cstring     ], #
 0x0111 => ['StripOffsets',               $LONG,  undef, 'calculated'     ], #
 0x0112 => ['Orientation',                $SHORT,     1, '[1-8]'          ], #
 0x0115 => ['SamplesPerPixel',            $SHORT,     1, '3',          'T'], #
 0x0116 => ['RowsPerStrip',               $LONG,      1, $IFD_integer, 'T'], #
 0x0117 => ['StripByteCounts',            $LONG,  undef, $IFD_integer, 'T'], #
 0x011a => ['XResolution',                $RATIONAL,  1, $IFD_integer     ], #
 0x011b => ['YResolution',                $RATIONAL,  1, $IFD_integer     ], #
 0x011c => ['PlanarConfiguration',        $SHORT,     1, '[12]'           ], #
 0x0128 => ['ResolutionUnit',             $SHORT,     1, '[23]'           ], #
 0x012d => ['TransferFunction',           $SHORT,   768, $IFD_integer     ], #
 0x0131 => ['Software',                   $ASCII, undef, $IFD_Cstring     ], #
 0x0132 => ['DateTime',                   $ASCII,    20, $IFD_datetime    ], #
 0x013b => ['Artist',                     $ASCII, undef, $IFD_Cstring     ], #
 0x013e => ['WhitePoint',                 $RATIONAL,  2, $IFD_integer     ], #
 0x013f => ['PrimaryChromaticities',      $RATIONAL,  6, $IFD_integer     ], #
 0x0201 => ['JPEGInterchangeFormat',      $LONG,      1, 'calculated'     ], #
 0x0202 => ['JPEGInterchangeFormatLength',$LONG,      1, $IFD_integer, 'T'], #
 0x0211 => ['YCbCrCoefficients',          $RATIONAL,  3, $IFD_integer     ], #
 0x0212 => ['YCbCrSubSampling',           $SHORT,     2, $SSR_YCCsampl    ], #
 0x0213 => ['YCbCrPositioning',           $SHORT,     1, '[12]'           ], #
 0x0214 => ['ReferenceBlackWhite',        $RATIONAL,  6, $IFD_integer     ], #
 0x8298 => ['Copyright',                  $ASCII, undef, $IFD_Cstring     ], #
 0x8769 => ['ExifOffset',                 $LONG,      1, 'calculated'     ], #
 0x8825 => ['GPSInfo',                    $LONG,      1, 'calculated'  ], }; #
#----------------------------------------------------------------------------#
my $HASH_APP1_IFD01_ADDITIONAL =                                             #
{0x00fe => ['NewSubfileType',             $LONG,      1, $IFD_integer ],     #
 0x00ff => ['SubFileType',                $SHORT,     1, $IFD_integer ],     #
 0x0107 => ['Thresholding',               $SHORT,     1, $IFD_integer ],     #
 0x0108 => ['CellWidth',                  $SHORT,     1, $IFD_integer ],     #
 0x0109 => ['CellLength',                 $SHORT,     1, $IFD_integer ],     #
 0x010a => ['FillOrder',                  $SHORT,     1, $IFD_integer ],     #
 0x010d => ['DocumentName',               $ASCII, undef, $IFD_Cstring ],     #
 0x0118 => ['MinSampleValue',             $SHORT, undef, $IFD_integer ],     #
 0x0119 => ['MaxSampleValue',             $SHORT, undef, $IFD_integer ],     #
 0x011d => ['PageName',                   $ASCII, undef, $IFD_Cstring ],     #
 0x011e => ['XPosition',                  $RATIONAL,  1, $IFD_integer ],     #
 0x011f => ['YPosition',                  $RATIONAL,  1, $IFD_integer ],     #
 0x0120 => ['FreeOffsets',                $LONG,  undef, $IFD_integer ],     #
 0x0121 => ['FreeByteCounts',             $LONG,  undef, $IFD_integer ],     #
 0x0122 => ['GrayResponseUnit',           $SHORT,     1, $IFD_integer ],     #
 0x0123 => ['GrayResponseCurve',          $SHORT, undef, $IFD_integer ],     #
 0x0124 => ['T4Options',                  $LONG,      1, $IFD_integer ],     #
 0x0125 => ['T6Options',                  $LONG,      1, $IFD_integer ],     #
 0x0129 => ['PageNumber',                 $SHORT,     2, $IFD_integer ],     #
 0x012c => ['ColorResponseUnit',          $SHORT,     1, 'invalid'    ],     #
 0x013c => ['HostComputer',               $ASCII, undef, $IFD_Cstring ],     #
 0x013d => ['Predictor',                  $SHORT,     1, $IFD_integer ],     #
 0x0140 => ['Colormap',                   $SHORT, undef, $IFD_integer ],     #
 0x0141 => ['HalftoneHints',              $SHORT,     2, $IFD_integer ],     #
 0x0142 => ['TileWidth',                  $LONG,      1, $IFD_integer ],     #
 0x0143 => ['TileLength',                 $LONG,      1, $IFD_integer ],     #
 0x0144 => ['TileOffsets',                $LONG,  undef, $IFD_integer ],     #
 0x0145 => ['TileByteCounts',             $LONG,  undef, $IFD_integer ],     #
 0x0146 => ['BadFaxLines',                $LONG,      1, $IFD_integer ],     #
 0x0147 => ['CleanFaxData',               $SHORT,     1, $IFD_integer ],     #
 0x0148 => ['ConsecutiveBadFaxLines',     $LONG,      1, $IFD_integer ],     #
 0x014a => ['SubIFD',                     $LONG,  undef, $IFD_integer ],     #
 0x014c => ['InkSet',                     $SHORT,     1, $IFD_integer ],     #
 0x014d => ['InkNames',                   $ASCII, undef, $IFD_Cstring ],     #
 0x014e => ['NumberOfInks',               $SHORT,     1, $IFD_integer ],     #
 0x0150 => ['DotRange',                   $SHORT, undef, $IFD_integer ],     #
 0x0151 => ['TargetPrinter',              $ASCII, undef, $IFD_Cstring ],     #
 0x0152 => ['ExtraSamples',               $SHORT, undef, $IFD_integer ],     #
 0x0153 => ['SampleFormats',              $SHORT, undef, $IFD_integer ],     #
 0x0154 => ['SMinSampleValue',            $UNDEF, undef, '.*'         ],     #
 0x0155 => ['SMaxSampleValue',            $UNDEF, undef, '.*'         ],     #
 0x0156 => ['TransferRange',              $SHORT,     6, $IFD_integer ],     #
 0x0157 => ['ClipPath',                   $BYTE,  undef, $IFD_integer ],     #
 0x0158 => ['XClipPathUnits',             $DOUBLE,    1, $IFD_float   ],     #
 0x0159 => ['YClipPathUnits',             $DOUBLE,    1, $IFD_float   ],     #
 0x015a => ['Indexed',                    $SHORT,     1, $IFD_integer ],     #
 0x015b => ['JPEGTables',                 undef,  undef, 'invalid'    ],     #
 0x015f => ['OPIProxy',                   $SHORT,     1, $IFD_integer ],     #
 0x0200 => ['JPEGProc',                   $SHORT,     1, 'invalid'    ],     #
 0x0203 => ['JPEGRestartInterval',        $SHORT,     1, 'invalid'    ],     #
 0x0205 => ['JPEGLosslessPredictors',     $SHORT, undef, 'invalid'    ],     #
 0x0206 => ['JPEGPointTransforms',        $SHORT, undef, 'invalid'    ],     #
 0x0207 => ['JPEGQTables',                $LONG,  undef, 'invalid'    ],     #
 0x0208 => ['JPEGDCTables',               $LONG,  undef, 'invalid'    ],     #
 0x0209 => ['JPEGACTables',               $LONG,  undef, 'invalid'    ],     #
 0x02bc => ['XML_Packet',                 $BYTE,  undef, $IFD_integer ], };  #
#----------------------------------------------------------------------------#
# The following company-related fields are marked as invalid because they    #
# are present also in the SubIFD section (with different numerical values)   #
# and I don't want the two entries to collide when setting IMAGE_DATA:       #
# 'FlashEnergy', 'SpatialFrequencyResponse', FocalPlane[XY]Resolution',      #
# 'FocalPlaneResolutionUnit', 'ExposureIndex', 'SensingMethod', 'CFAPattern' #
#----------------------------------------------------------------------------#
my $HASH_APP1_IFD01_COMPANIES =                                              #
{0x800d => ['ImageID',                    $ASCII, undef, $IFD_Cstring ],     #
 0x80b9 => ['RefPts',                     undef,  undef, 'invalid'    ],     #
 0x80ba => ['RegionTackPoint',            undef,  undef, 'invalid'    ],     #
 0x80bb => ['RegionWarpCorners',          undef,  undef, 'invalid'    ],     #
 0x80bc => ['RegionAffine',               undef,  undef, 'invalid'    ],     #
 0x80e3 => ['Matteing',                   $SHORT,     1, 'obsoleted'  ],     #
 0x80e4 => ['DataType',                   $SHORT,     1, 'obsoleted'  ],     #
 0x80e5 => ['ImageDepth',                 $LONG,      1, $IFD_integer ],     #
 0x80e6 => ['TileDepth',                  $LONG,      1, $IFD_integer ],     #
 0x8214 => ['ImageFullWidth',             $LONG,      1, $IFD_integer ],     #
 0x8215 => ['ImageFullLength',            $LONG,      1, $IFD_integer ],     #
 0x8216 => ['TextureFormat',              $ASCII, undef, $IFD_Cstring ],     #
 0x8217 => ['WrapModes',                  $ASCII, undef, $IFD_Cstring ],     #
 0x8218 => ['FovCot',                     $FLOAT,     1, $IFD_float   ],     #
 0x8219 => ['MatrixWorldToScreen',        $FLOAT,    16, $IFD_float   ],     #
 0x821a => ['MatrixWorldToCamera',        $FLOAT,    16, $IFD_float   ],     #
 0x827d => ['WriterSerialNumber',         undef,  undef, 'invalid'    ],     #
 0x828d => ['CFARepeatPatternDim',        $SHORT,     2, $IFD_integer ],     #
 0x828e => ['CFAPattern',                 $BYTE,  undef, 'invalid'    ],     #
 0x828f => ['BatteryLevel',               $ASCII, undef, $IFD_Cstring ],     #
 0x830e => ['ModelPixelScaleTag',         $DOUBLE,    3, $IFD_float   ],     #
 0x83bb => ['IPTC/NAA',                   $ASCII, undef, $IFD_Cstring ],     #
 0x8480 => ['IntergraphMatrixTag',        $DOUBLE,   16, 'obsoleted'  ],     #
 0x8482 => ['ModelTiepointTag',           $DOUBLE,undef, $IFD_float   ],     #
 0x84e0 => ['Site',                       $ASCII, undef, $IFD_Cstring ],     #
 0x84e1 => ['ColorSequence',              $ASCII, undef, $IFD_Cstring ],     #
 0x84e2 => ['IT8Header',                  $ASCII, undef, $IFD_Cstring ],     #
 0x84e3 => ['RasterPadding',              $SHORT,     1, $IFD_integer ],     #
 0x84e4 => ['BitsPerRunLength',           $SHORT,     1, $IFD_integer ],     #
 0x84e5 => ['BitsPerExtendedRunLength',   $SHORT,     1, $IFD_integer ],     #
 0x84e6 => ['ColorTable',                 $BYTE,  undef, $IFD_integer ],     #
 0x84e7 => ['ImageColorIndicator',        $BYTE,      1, $IFD_integer ],     #
 0x84e8 => ['BackgroundColorIndicator',   $BYTE,      1, $IFD_integer ],     #
 0x84e9 => ['ImageColorValue',            $BYTE,      1, $IFD_integer ],     #
 0x84ea => ['BackgroundColorValue',       $BYTE,      1, $IFD_integer ],     #
 0x84eb => ['PixelIntensityRange',        $BYTE,      2, $IFD_integer ],     #
 0x84ec => ['TransparencyIndicator',      $BYTE,      1, $IFD_integer ],     #
 0x84ed => ['ColorCharacterization',      $ASCII, undef, $IFD_Cstring ],     #
 0x84ee => ['HCUsage',                    $LONG,      1, $IFD_integer ],     #
 0x84ef => ['TrapIndicator',              $BYTE,      1, $IFD_integer ],     #
 0x84f0 => ['CMYKEquivalent',             $SHORT, undef, $IFD_integer ],     #
 0x84f1 => ['Reserved_TIFF_IT_1',         undef,  undef, 'invalid'    ],     #
 0x84f2 => ['Reserved_TIFF_IT_2',         undef,  undef, 'invalid'    ],     #
 0x84f3 => ['Reserved_TIFF_IT_3',         undef,  undef, 'invalid'    ],     #
 0x85b8 => ['FrameCount',                 $LONG,      1, $IFD_integer ],     #
 0x85d8 => ['ModelTransformationTag',     $DOUBLE,   16, $IFD_float   ],     #
 0x8649 => ['PhotoshopImageResources',    $BYTE,  undef, $IFD_integer ],     #
 0x8773 => ['ICCProfile',                 undef,  undef, 'invalid'    ],     #
 0x87af => ['GeoKeyDirectoryTag',         $SHORT, undef, $IFD_integer ],     #
 0x87b0 => ['GeoDoubleParamsTag',         $DOUBLE,undef, $IFD_float   ],     #
 0x87b1 => ['GeoAsciiParamsTag',          $ASCII, undef, $IFD_Cstring ],     #
 0x87be => ['JBIG_Options',               undef,  undef, 'invalid'    ],     #
 0x8829 => ['Interlace',                  $SHORT,     1, $IFD_integer ],     #
 0x882a => ['TimeZoneOffset',             $SSHORT,undef, $IFD_signed  ],     #
 0x882b => ['SelfTimerMode',              $SHORT,     1, $IFD_integer ],     #
 0x885c => ['FaxRecvParams',              $LONG,      1, $IFD_integer ],     #
 0x885d => ['FaxSubAddress',              $ASCII, undef, $IFD_Cstring ],     #
 0x885e => ['FaxRecvTime',                $LONG,      1, $IFD_integer ],     #
 0x8871 => ['FedExEDR',                   undef,  undef, 'invalid'    ],     #
 0x920b => ['FlashEnergy',               $RATIONAL,undef,'invalid'    ],     #
 0x920c => ['SpatialFrequencyResponse',   undef,  undef, 'invalid'    ],     #
 0x920d => ['Noise',                      undef,  undef, 'invalid'    ],     #
 0x920e => ['FocalPlaneXResolution',      $RATIONAL,  1, 'invalid'    ],     #
 0x920f => ['FocalPlaneYResolution',      $RATIONAL,  1, 'invalid'    ],     #
 0x9210 => ['FocalPlaneResolutionUnit',   $SHORT,     1, 'invalid'    ],     #
 0x9211 => ['ImageNumber',                $LONG,      1, $IFD_integer ],     #
 0x9212 => ['SecurityClassification',     $ASCII, undef, $IFD_Cstring ],     #
 0x9213 => ['ImageHistory',               $ASCII, undef, $IFD_Cstring ],     #
 0x9215 => ['ExposureIndex',             $RATIONAL,undef,'invalid'    ],     #
 0x9216 => ['TIFF/EPStandardID',          $BYTE,      4, $IFD_integer ],     #
 0x9217 => ['SensingMethod',              $SHORT,     1, 'invalid'    ],     #
 0x923f => ['StoNits',                    $DOUBLE,    1, $IFD_float   ],     #
 0x935c => ['ImageSourceData',            undef,  undef, 'invalid'    ],     #
 0xc4a5 => ['PrintIM_Data',               undef,  undef, 'invalid'    ],     #
 0xc44f => ['PhotoshopAnnotations',       undef,  undef, 'invalid'    ],     #
 0xffff => ['DCSHueShiftValues',          undef,  undef, 'invalid'    ], };  #
#----------------------------------------------------------------------------#
my $HASH_APP1_IFD01_GENERAL = {};                                            #
@$HASH_APP1_IFD01_GENERAL{keys %$_} =                                        #
    values %$_ for ($HASH_APP1_IFD01_MAIN,                                   #
		    $HASH_APP1_IFD01_ADDITIONAL,                             #
		    $HASH_APP1_IFD01_COMPANIES);                             #
#============================================================================#
#============================================================================#
#============================================================================#
# See the "Exif tags for the 0th IFD Exif private subdirectory" section in   #
# the Image::MetaData::JPEG module perldoc page for further details (private #
# EXIF region in IFD0, also known as SubIFD).                                #
#----------------------------------------------------------------------------#
# Hash keys are numeric tags, here written in hexadecimal base.              #
# Fields: 0 -> name, 1 -> type, 2 -> count, 3 -> matching regular            #
# Mandatory records: ExifVersion, ComponentsConfiguration, FlashpixVersion,  #
#                    ColorSpace, PixelXDimension and PixelYDimension.        #
#----------------------------------------------------------------------------#
my $IFD_subsecs  = '\d*\s*\000';                    # a fraction of a second #
my $IFD_Ustring  = '(ASCII\000{3}|JIS\000{5}|Unicode\000|\000{8}).*';        #
my $IFD_DOSfile  = '\w{8}\.\w{3}\000';              # a DOS filename (8+3)   #
my $IFD_lightsrc = '([0-49]|1[0-57-9]|2[0-4]|255)'; # possible light sources #
my $IFD_flash    = '([01579]|1[356]|2[459]|3[12]|6[59]|7[1379]|89|9[35])';   #
my $IFD_hexstr   = '[0-9a-fA-F]+\000+';             # hexadecimal ASCII str  #
my $IFD_Exifver  = '0(100|110|200|210|220|221)';    # known Exif versions    #
my $IFD_setdesc  = '.{4}(\376\377(.{2})*\000\000)*'; # for DeviceSettingDesc.#
my $IFD_compconf = '(\004\005\006|\001\002\003)\000';# for ComponentsConfig. #
#--- Special screen rules ---------------------------------------------------#
# a SubjectArea tag indicates the location and area of the main subject. The #
# tag can contain 2, 3 or 4 integer numbers (see Exif 2.2 for their meaning) #
my $SSR_subjectarea = sub { die if scalar @_ < 2 || scalar @_ > 4;           #
			    die if grep { ! /^\d+$/ } @_; };                 #
# a CFAPattern tag indicates a color filter array. The first four bytes are  #
# two shorts giving the horizontal (m) and vertical (n) repeat pixel units.  #
# Then, m x n bytes follow, with the actual filter values (in the range 0-6).#
my $SSR_cfapattern  = sub { my ($x, $y) = unpack 'nn', $_[0];                #
			    die if length $_[0] != 4+$x*$y;                  #
			    die if $_[0] !~ /^.{4}[0-6]*$/; };               #
#--- Mandatory records ------------------------------------------------------#
my $HASH_APP1_SUBIFD_MANDATORY = {'ExifVersion'       => '0220',             #
 			    'ComponentsConfiguration' => "\001\002\003\000", #
				  'FlashpixVersion'   => '0100',             #
				  'ColorSpace'        => 1,                  #
				  'PixelXDimension'   => 0,   # global info  #
				  'PixelYDimension'   => 0 }; # needed here! #
#--- Legal records' list ----------------------------------------------------#
my $HASH_APP1_SUBIFD_GENERAL =                                               #
{0x829a => ['ExposureTime',               $RATIONAL,  1, $IFD_integer    ],  #
 0x829d => ['FNumber',                    $RATIONAL,  1, $IFD_integer    ],  #
 0x8822 => ['ExposureProgram',            $SHORT,     1, '[0-8]'         ],  #
 0x8824 => ['SpectralSensitivity',        $ASCII, undef, $IFD_Cstring    ],  #
 0x8827 => ['ISOSpeedRatings',            $SHORT, undef, $IFD_integer    ],  #
 0x8828 => ['OECF',                       $UNDEF, undef, '.*'            ],  #
 0x9000 => ['ExifVersion',                $UNDEF,     4, $IFD_Exifver    ],  #
 0x9003 => ['DateTimeOriginal',           $ASCII,    20, $IFD_datetime   ],  #
 0x9004 => ['DateTimeDigitized',          $ASCII,    20, $IFD_datetime   ],  #
 0x9101 => ['ComponentsConfiguration',    $UNDEF,     4, $IFD_compconf   ],  #
 0x9102 => ['CompressedBitsPerPixel',     $RATIONAL,  1, $IFD_integer    ],  #
 0x9201 => ['ShutterSpeedValue',          $SRATIONAL, 1, $IFD_signed     ],  #
 0x9202 => ['ApertureValue',              $RATIONAL,  1, $IFD_integer    ],  #
 0x9203 => ['BrightnessValue',            $SRATIONAL, 1, $IFD_signed     ],  #
 0x9204 => ['ExposureBiasValue',          $SRATIONAL, 1, $IFD_signed     ],  #
 0x9205 => ['MaxApertureValue',           $RATIONAL,  1, $IFD_integer    ],  #
 0x9206 => ['SubjectDistance',            $RATIONAL,  1, $IFD_integer    ],  #
 0x9207 => ['MeteringMode',               $SHORT,     1, '([0-6]|255)'   ],  #
 0x9208 => ['LightSource',                $SHORT,     1, $IFD_lightsrc   ],  #
 0x9209 => ['Flash',                      $SHORT,     1, $IFD_flash      ],  #
 0x920a => ['FocalLength',                $RATIONAL,  1, $IFD_integer    ],  #
 0x9214 => ['SubjectArea',                $SHORT, undef, $SSR_subjectarea],  #
 0x927c => ['MakerNote',                  $UNDEF, undef, 'invalid'       ],  #
 0x9286 => ['UserComment',                $UNDEF, undef, $IFD_Ustring    ],  #
 0x9290 => ['SubSecTime',                 $ASCII, undef, $IFD_subsecs    ],  #
 0x9291 => ['SubSecTimeOriginal',         $ASCII, undef, $IFD_subsecs    ],  #
 0x9292 => ['SubSecTimeDigitized',        $ASCII, undef, $IFD_subsecs    ],  #
 0xa000 => ['FlashpixVersion',            $UNDEF,     4, '0100'          ],  #
 0xa001 => ['ColorSpace',                 $SHORT,     1, '(1|65535)'     ],  #
 0xa002 => ['PixelXDimension',            $LONG,      1, $IFD_integer    ],  #
 0xa003 => ['PixelYDimension',            $LONG,      1, $IFD_integer    ],  #
 0xa004 => ['RelatedSoundFile',           $ASCII,    13, $IFD_DOSfile    ],  #
 0xa005 => ['InteroperabilityOffset',     $LONG,      1, 'calculated'    ],  #
 0xa20b => ['FlashEnergy',                $RATIONAL,  1, $IFD_integer    ],  #
 0xa20c => ['SpatialFrequencyResponse',   $UNDEF, undef, '.*'            ],  #
 0xa20e => ['FocalPlaneXResolution',      $RATIONAL,  1, $IFD_integer    ],  #
 0xa20f => ['FocalPlaneYResolution',      $RATIONAL,  1, $IFD_integer    ],  #
 0xa210 => ['FocalPlaneResolutionUnit',   $SHORT,     1, '[23]'          ],  #
 0xa214 => ['SubjectLocation',            $SHORT,     2, $IFD_integer    ],  #
 0xa215 => ['ExposureIndex',              $RATIONAL,  1, $IFD_integer    ],  #
 0xa217 => ['SensingMethod',              $SHORT,     1, '[1-578]'       ],  #
 0xa300 => ['FileSource',                 $UNDEF,     1, '\003'          ],  #
 0xa301 => ['SceneType',                  $UNDEF,     1, '\001'          ],  #
 0xa302 => ['CFAPattern',                 $UNDEF, undef, $SSR_cfapattern ],  #
 0xa401 => ['CustomRendered',             $SHORT,     1, '[01]'          ],  #
 0xa402 => ['ExposureMode',               $SHORT,     1, '[012]'         ],  #
 0xa403 => ['WhiteBalance',               $SHORT,     1, '[01]'          ],  #
 0xa404 => ['DigitalZoomRatio',           $RATIONAL,  1, $IFD_integer    ],  #
 0xa405 => ['FocalLengthIn35mmFilm',      $SHORT,     1, $IFD_integer    ],  #
 0xa406 => ['SceneCaptureType',           $SHORT,     1, '[0-3]'         ],  #
 0xa407 => ['GainControl',                $SHORT,     1, '[0-4]'         ],  #
 0xa408 => ['Contrast',                   $SHORT,     1, '[0-2]'         ],  #
 0xa409 => ['Saturation',                 $SHORT,     1, '[0-2]'         ],  #
 0xa40a => ['Sharpness',                  $SHORT,     1, '[0-2]'         ],  #
 0xa40b => ['DeviceSettingDescription',   $UNDEF, undef, $IFD_setdesc    ],  #
 0xa40c => ['SubjectDistanceRange',       $SHORT,     1, '[0-3]'         ],  #
 0xa420 => ['ImageUniqueID',              $ASCII,    33, $IFD_hexstr     ],  #
# --- From Photoshop >= 7.0 treatment of raw camera files (undocumented) --- #
 0xfde8 => ['_OwnerName',     $ASCII, undef, "Owner'".'s Name: .*\000'   ],  #
 0xfde9 => ['_SerialNumber',  $ASCII, undef, 'Serial Number: .*\000'     ],  #
 0xfdea => ['_Lens',          $ASCII, undef, 'Lens: .*\000'              ],  #
 0xfe4c => ['_RawFile',       $ASCII, undef, 'Raw File: .*\000'          ],  #
 0xfe4d => ['_Converter',     $ASCII, undef, 'Converter: .*\000'         ],  #
 0xfe4e => ['_WhiteBalance',  $ASCII, undef, 'White Balance: .*\000'     ],  #
 0xfe51 => ['_Exposure',      $ASCII, undef, 'Exposure: .*\000'          ],  #
 0xfe52 => ['_Shadows',       $ASCII, undef, 'Shadows: .*\000'           ],  #
 0xfe53 => ['_Brightness',    $ASCII, undef, 'Brightness: .*\000'        ],  #
 0xfe54 => ['_Contrast',      $ASCII, undef, 'Contrast: .*\000'          ],  #
 0xfe55 => ['_Saturation',    $ASCII, undef, 'Saturation: .*\000'        ],  #
 0xfe56 => ['_Sharpness',     $ASCII, undef, 'Sharpness: .*\000'         ],  #
 0xfe57 => ['_Smoothness',    $ASCII, undef, 'Smoothness: .*\000'        ],  #
 0xfe58 => ['_MoireFilter',   $ASCII, undef, 'Moire Filter: .*\000'   ], };  #
#============================================================================#
#============================================================================#
#============================================================================#
# See the "EXIF tags for the 0th IFD Interoperability subdirectory" section  #
# in the Image::MetaData::JPEG module perldoc page for further details.      #
# Mandatory records: InteroperabilityIndex and InteroperabilityVersion       #
#----------------------------------------------------------------------------#
# Hash keys are numeric tags, here written in hexadecimal base.              #
# Fields: 0 -> name, 1 -> type, 2 -> count, 3 -> matching regular            #
#--- Mandatory records ------------------------------------------------------#
my $HASH_INTEROP_MANDATORY = {'InteroperabilityVersion' => '0100',           #
			      'InteroperabilityIndex'   => 'R98'  };         #
#--- Legal records' list ----------------------------------------------------#
my $HASH_INTEROP_GENERAL =                                                   #
{0x0001 => ['InteroperabilityIndex',      $ASCII,     4, 'R98\000'     ],    #
 0x0002 => ['InteroperabilityVersion',    $UNDEF,     4, '[0-9]{4}'    ],    #
 0x1000 => ['RelatedImageFileFormat',     $ASCII, undef, $IFD_Cstring  ],    #
 0x1001 => ['RelatedImageWidth',          $LONG,      1, '[0-9]*'      ],    #
 0x1002 => ['RelatedImageLength',         $LONG,      1, '[0-9]*'      ], }; #
#============================================================================#
#============================================================================#
#============================================================================#
# See the "EXIF tags for the 0th IFD GPS subdirectory" section in the        #
# Image::MetaData::JPEG module perldoc page for further details on GPS data. #
# Mandatory records: only GPSVersionID                                       #
#----------------------------------------------------------------------------#
# Hash keys are numeric tags, here written in hexadecimal base.              #
# Fields: 0 -> name, 1 -> type, 2 -> count, 3 -> matching regular            #
#----------------------------------------------------------------------------#
my $GPS_re_Cstring   = $re_Cstring;            # a null terminated string    #
my $GPS_re_date      = $re_dt18_cl . '\000';   # YYYY:MM:DD null terminated  #
my $GPS_re_number    = $re_integer;            # a generic integer number    #
my $GPS_re_NS        = '[NS]\000';             # latitude reference          #
my $GPS_re_EW        = '[EW]\000';             # longitude reference         #
my $GPS_re_spdsref   = '[KMN]\000';            # speed or distance reference #
my $GPS_re_direref   = '[TM]\000';             # directin reference          #
my $GPS_re_string    = '[AJU\000].*';          # GPS "undefined" strings     #
#--- Special screen rules ---------------------------------------------------#
# a direction is a rational number in [0.00, 359.99] (we should also test    #
# explicitely that the numerator and the denominator are not negative).      #
my $SSR_direction  = sub { die if grep { $_ < 0 } @_;                        #
			   my $dire = $_[0]/$_[1]; die if $dire >= 360;      #
			   die unless $dire =~ /^\d+(\.\d{1,2})?$/; };       #
# a "triplet" corresponds to three rationals for units, minutes (< 60) and   #
# seconds (< 60). The 1st argument must be a limit on units (helper rule).   #
my $SSR_triplet    = sub { my $limit = shift; die if grep { $_ < 0 } @_;     #
			   my ($dd,$mm,$ss) = map {$_[$_]/$_[1+$_]} (0,2,4); #
			   die unless $mm < 60 && $ss < 60 && $dd <= $limit; #
			   die unless ($dd + $mm /60 + $ss/360) <= $limit;}; #
# a latitude or a longitude is stored as a sequence of three rationals nums  #
# (degrees, minutes and seconds) with degrees<=90 or 180 (see $SSR_triplet). #
my $SSR_latitude   = sub { &$SSR_triplet( 90, @_); };                        #
my $SSR_longitude  = sub { &$SSR_triplet(180, @_); };                        #
# a time stamp is stored as three rationals (hours, minutes and seconds); in #
# this case hours must be <= 24 (see $SSR_triplet for further details).      #
my $SSR_stupidtime = sub { &$SSR_triplet(24, @_); };                         #
#--- Mandatory records ------------------------------------------------------#
my $HASH_GPS_MANDATORY = {'GPSVersionID' => [2,2,0,0]};                      #
#--- Legal records' list ----------------------------------------------------#
my $HASH_GPS_GENERAL =                                                       #
{0x00 => ['GPSVersionID',                 $BYTE,      4, '.'             ],  #
 0x01 => ['GPSLatitudeRef',               $ASCII,     2, $GPS_re_NS      ],  #
 0x02 => ['GPSLatitude',                  $RATIONAL,  3, $SSR_latitude   ],  #
 0x03 => ['GPSLongitudeRef',              $ASCII,     2, $GPS_re_EW      ],  #
 0x04 => ['GPSLongitude',                 $RATIONAL,  3, $SSR_longitude  ],  #
 0x05 => ['GPSAltitudeRef',               $BYTE,      1, '[01]'          ],  #
 0x06 => ['GPSAltitude',                  $RATIONAL,  1, $GPS_re_number  ],  #
 0x07 => ['GPSTimeStamp',                 $RATIONAL,  3, $SSR_stupidtime ],  #
 0x08 => ['GPSSatellites',                $ASCII, undef, $GPS_re_Cstring ],  #
 0x09 => ['GPSStatus',                    $ASCII,     2, '[AV]\000'      ],  #
 0x0a => ['GPSMeasureMode',               $ASCII,     2, '[23]\000'      ],  #
 0x0b => ['GPSDOP',                       $RATIONAL,  1, $GPS_re_number  ],  #
 0x0c => ['GPSSpeedRef',                  $ASCII,     2, $GPS_re_spdsref ],  #
 0x0d => ['GPSSpeed',                     $RATIONAL,  1, $GPS_re_number  ],  #
 0x0e => ['GPSTrackRef',                  $ASCII,     2, $GPS_re_direref ],  #
 0x0f => ['GPSTrack',                     $RATIONAL,  1, $SSR_direction  ],  #
 0x10 => ['GPSImgDirectionRef',           $ASCII,     2, $GPS_re_direref ],  #
 0x11 => ['GPSImgDirection',              $RATIONAL,  1, $SSR_direction  ],  #
 0x12 => ['GPSMapDatum',                  $ASCII, undef, $GPS_re_Cstring ],  #
 0x13 => ['GPSDestLatitudeRef',           $ASCII,     2, $GPS_re_NS      ],  #
 0x14 => ['GPSDestLatitude',              $RATIONAL,  3, $SSR_latitude   ],  #
 0x15 => ['GPSDestLongitudeRef',          $ASCII,     2, $GPS_re_EW      ],  #
 0x16 => ['GPSDestLongitude',             $RATIONAL,  3, $SSR_longitude  ],  #
 0x17 => ['GPSDestBearingRef',            $ASCII,     2, $GPS_re_direref ],  #
 0x18 => ['GPSDestBearing',               $RATIONAL,  1, $SSR_direction  ],  #
 0x19 => ['GPSDestDistanceRef',           $ASCII,     2, $GPS_re_spdsref ],  #
 0x1a => ['GPSDestDistance',              $RATIONAL,  1, $GPS_re_number  ],  #
 0x1b => ['GPSProcessingMethod',          $UNDEF, undef, $GPS_re_string  ],  #
 0x1c => ['GPSAreaInformation',           $UNDEF, undef, $GPS_re_string  ],  #
 0x1d => ['GPSDateStamp',                 $ASCII,    11, $GPS_re_date    ],  #
 0x1e => ['GPSDifferential',              $SHORT,     1, '[01]'         ],}; #
#============================================================================#

# Tags used for ICC data in APP2 (they are 4 bytes strings, so
# I prefer to write the string and then convert it).
sub str2hex { my $z = 0; ($z *= 256) += $_ for unpack "CCCC", $_[0]; $z; }
my $HASH_APP2_ICC =
{str2hex('A2B0') => 'AT0B0Tag', 
 str2hex('A2B1') => 'AToB1Tag',
 str2hex('A2B2') => 'AToB2Tag',
 str2hex('bXYZ') => 'BlueMatrixColumn',
 str2hex('bTRC') => 'BlueTRC',
 str2hex('B2A0') => 'BToA0Tag',
 str2hex('B2A1') => 'BToA1Tag',
 str2hex('B2A2') => 'BToA2Tag',
 str2hex('calt') => 'CalibrationDateTime',
 str2hex('targ') => 'CharTarget',
 str2hex('chad') => 'ChromaticAdaptation',
 str2hex('chrm') => 'Chromaticity',
 str2hex('clro') => 'ColorantOrder',
 str2hex('clrt') => 'ColorantTable',
 str2hex('cprt') => 'Copyright',
 str2hex('dmnd') => 'DeviceMfgDesc',
 str2hex('dmdd') => 'DeviceModelDesc',
 str2hex('gamt') => 'Gamut',
 str2hex('kTRC') => 'GrayTRC',
 str2hex('gXYZ') => 'GreenMatrixColumn',
 str2hex('gTRC') => 'GreenTRC',
 str2hex('lumi') => 'Luminance',
 str2hex('meas') => 'Measurement',
 str2hex('bkpt') => 'MediaBlackPoint',
 str2hex('wtpt') => 'MediaWhitePoint',
 str2hex('ncl2') => 'NamedColor2',
 str2hex('resp') => 'OutputResponse',
 str2hex('pre0') => 'Preview0',
 str2hex('pre1') => 'Preview1',
 str2hex('pre2') => 'Preview2',
 str2hex('desc') => 'ProfileDescription',
 str2hex('pseq') => 'ProfileSequenceDesc',
 str2hex('rXYZ') => 'RedMatrixColumn',
 str2hex('rTRC') => 'RedTRC',
 str2hex('tech') => 'Technology',
 str2hex('vued') => 'ViewingCondDesc',
 str2hex('view') => 'ViewingConditions', };

# Tags used by the 0-th IFD of an APP3 segment (reference ... ?)
my $HASH_APP3_IFD =
{0xc350 => 'FilmProductCode',
 0xc351 => 'ImageSource',
 0xc352 => 'PrintArea',
 0xc353 => 'CameraOwner',
 0xc354 => 'CameraSerialNumber',
 0xc355 => 'GroupCaption',
 0xc356 => 'DealerID',
 0xc357 => 'OrderID',
 0xc358 => 'BagNumber',
 0xc359 => 'ScanFrameSeqNumber',
 0xc35a => 'FilmCategory',
 0xc35b => 'FilmGenCode',
 0xc35c => 'ScanSoftware',
 0xc35d => 'FilmSize',
 0xc35e => 'SBARGBShifts',
 0xc35f => 'SBAInputColor',
 0xc360 => 'SBAInputBitDepth',
 0xc361 => 'SBAExposureRec',
 0xc362 => 'UserSBARGBShifts',
 0xc363 => 'ImageRotationStatus',
 0xc364 => 'RollGUID',
 0xc365 => 'APP3Version',
 0xc36e => 'SpecialEffectsIFD', # pointer to an IFD
 0xc36f => 'BordersIFD', };     # pointer to an IFD

my $HASH_APP3_SPECIAL =
{0x0000 => 'APP3_SpecialIFD_tag_0',
 0x0001 => 'APP3_SpecialIFD_tag_1',
 0x0002 => 'APP3_SpecialIFD_tag_2', };

my $HASH_APP3_BORDERS =
{0x0000 => 'APP3_BordersIFD_tag_0',
 0x0001 => 'APP3_BordersIFD_tag_1',
 0x0002 => 'APP3_BordersIFD_tag_2',
 0x0003 => 'APP3_BordersIFD_tag_3',
 0x0004 => 'APP3_BordersIFD_tag_4',
 0x0008 => 'APP3_BordersIFD_tag_8', };

#============================================================================#
#============================================================================#
#============================================================================#
# See the "VALID TAGS FOR IPTC DATA" section in the Image::MetaData::JPEG    #
# module perldoc page for further details on IPTC data. Also 1:xx datasets   #
# are documented here, although only 2:xx datasets are likely to be found.   #
# Note: I don't know why the standard says 4 for 'RecordVersion'; it turns   #
# out that you always find 2 in JPEG files.                                  #
#----------------------------------------------------------------------------#
# Hash keys are numeric tags in decimal (the IPTC standard uses base 10...). #
# Fields: 0 -> Tag name, 1 -> repeatability ('N' means non-repeatable),      #
#         2,3 -> min and max length, 4 -> regular expression to match.       #
# The regular expression for "words" is what they call graphic characters.   #
#----------------------------------------------------------------------------#
my $IPTC_re_word = '^[^\000-\040\177]*$';                   # words          #
my $IPTC_re_line = '^[^\000-\037\177]*$';                   # words + spaces #
my $IPTC_re_para = '^[^\000-\011\013\014\016-\037\177]*$';  # line + CR + LF #
my $IPTC_re_dt18 = $re_dt18;                                # CCYYMMDD       #
my $IPTC_re_date = $re_date;                                # CCYYMMDD full  #
my $IPTC_re_dura = $re_time;                                # HHMMSS         #
my $IPTC_re_time = $IPTC_re_dura . '[\+-]' . $re_zone;      # HHMMSS+/-HHMM  #
my $vchr         = '\040-\051\053-\071\073-\076\100-\176';  # (SubjectRef.)  #
my $IPTC_re_sure='['.$vchr.']{1,32}?:[01]\d{7}(:['.$vchr.'\s]{0,64}?){3}';   #
#--- Mandatory records ------------------------------------------------------#
my $HASH_IPTC_MANDATORY_1 = {'ModelVersion'  => "\000\004" };                #
my $HASH_IPTC_MANDATORY_2 = {'RecordVersion' => "\000\002" };                #
#--- Legal records' list ( datasets 1:xx ) ----------------------------------#
my $HASH_IPTC_GENERAL_1 =                                                    #
{0   => ['ModelVersion',                'N', 2,  2, 'binary'              ], #
 5   => ['Destination',                 ' ',1,1024, $IPTC_re_word         ], #
 20  => ['FileFormat',                  'N', 2,  2, 'invalid,binary'      ], #
 22  => ['FileFormatVersion',           'N', 2,  2, 'invalid,binary'      ], #
 30  => ['ServiceIdentifier',           'N', 0, 10, $IPTC_re_word         ], #
 40  => ['EnvelopeNumber',              'N', 8,  8, 'invalid,\d{8}'       ], #
 50  => ['ProductID',                   ' ', 0, 32, $IPTC_re_word         ], #
 60  => ['EnvelopePriority',            'N', 1,  1, 'invalid,[1-9]'       ], #
 70  => ['DataSent',                    'N', 8,  8, 'invalid,date'        ], #
 80  => ['TimeSent',                    'N',11, 11, 'invalid,time'        ], #
 90  => ['CodedCharacterSet',           'N', 0, 32, '\033.{1,3}'          ], #
 100 => ['UNO',                         'N',14, 80, 'invalid'             ], #
 120 => ['ARMIdentifier',               'N', 2,  2, 'invalid,binary'      ], #
 122 => ['ARMVersion',                  'N', 2,  2, 'invalid,binary'    ],}; #
#--- Legal records' list ( datasets 2:xx ) ----------------------------------#
my $HASH_IPTC_GENERAL_2 =                                                    #
{0   => ['RecordVersion',               'N', 2,  2, 'binary'              ], #
 3   => ['ObjectTypeReference',         'N', 3, 67, '\d{2}:[\w\s]{0,64}?' ], #
 4   => ['ObjectAttributeReference',    ' ', 4, 68, '\d{3}:[\w\s]{0,64}?' ], #
 5   => ['ObjectName',                  'N', 1, 64, $IPTC_re_line         ], #
 7   => ['EditStatus',                  'N', 1, 64, $IPTC_re_line         ], #
 8   => ['EditorialUpdate',             'N', 2,  2, '01'                  ], #
 10  => ['Urgency',                     'N', 1,  1, '[1-8]'               ], #
 12  => ['SubjectReference',            ' ',13,236, $IPTC_re_sure         ], #
 15  => ['Category',                    'N', 1,  3, '[a-zA-Z]{1,3}?'      ], #
 20  => ['SupplementalCategory',        ' ', 1, 32, $IPTC_re_line         ], #
 22  => ['FixtureIdentifier',           'N', 1, 32, $IPTC_re_word         ], #
 25  => ['Keywords',                    ' ', 1, 64, $IPTC_re_line         ], #
 26  => ['ContentLocationCode',         ' ', 3,  3, '[A-Z]{3}'            ], #
 27  => ['ContentLocationName',         ' ', 1, 64, $IPTC_re_line         ], #
 30  => ['ReleaseDate',                 'N', 8,  8, $IPTC_re_dt18         ], #
 35  => ['ReleaseTime',                 'N',11, 11, $IPTC_re_time         ], #
 37  => ['ExpirationDate',              'N', 8,  8, $IPTC_re_dt18         ], #
 38  => ['ExpirationTime',              'N',11, 11, $IPTC_re_time         ], #
 40  => ['SpecialInstructions',         'N', 1,256, $IPTC_re_line         ], #
 42  => ['ActionAdvised',               'N', 2,  2, '0[1-4]'              ], #
 45  => ['ReferenceService',            ' ',10, 10, 'invalid'             ], #
 47  => ['ReferenceDate',               ' ', 8,  8, 'invalid'             ], #
 50  => ['ReferenceNumber',             ' ', 8,  8, 'invalid'             ], #
 55  => ['DateCreated',                 'N', 8,  8, $IPTC_re_date         ], #
 60  => ['TimeCreated',                 'N',11, 11, $IPTC_re_time         ], #
 62  => ['DigitalCreationDate',         'N', 8,  8, $IPTC_re_dt18         ], #
 63  => ['DigitalCreationTime',         'N',11, 11, $IPTC_re_time         ], #
 65  => ['OriginatingProgram',          'N', 1, 32, $IPTC_re_line         ], #
 70  => ['ProgramVersion',              'N', 1, 10, $IPTC_re_line         ], #
 75  => ['ObjectCycle',                 'N', 1,  1, '[apb]'               ], #
 80  => ['ByLine',                      ' ', 1, 32, $IPTC_re_line         ], #
 85  => ['ByLineTitle',                 ' ', 1, 32, $IPTC_re_line         ], #
 90  => ['City',                        'N', 1, 32, $IPTC_re_line         ], #
 92  => ['SubLocation',                 'N', 1, 32, $IPTC_re_line         ], #
 95  => ['Province/State',              'N', 1, 32, $IPTC_re_line         ], #
 100 => ['Country/PrimaryLocationCode', 'N', 3,  3, '[A-Z]{3}'            ], #
 101 => ['Country/PrimaryLocationName', 'N', 1, 64, $IPTC_re_line         ], #
 103 => ['OriginalTransmissionReference','N',1, 32, $IPTC_re_line         ], #
 105 => ['Headline',                    'N', 1,256, $IPTC_re_line         ], #
 110 => ['Credit',                      'N', 1, 32, $IPTC_re_line         ], #
 115 => ['Source',                      'N', 1, 32, $IPTC_re_line         ], #
 116 => ['CopyrightNotice',             'N', 1,128, $IPTC_re_line         ], #
 118 => ['Contact',                     ' ', 1,128, $IPTC_re_line         ], #
 120 => ['Caption/Abstract',            'N', 1,2000,$IPTC_re_para         ], #
 122 => ['Writer/Editor',               ' ', 1, 32, $IPTC_re_line         ], #
 125 => ['RasterizedCaption',           'N',7360,7360,'binary'            ], #
 130 => ['ImageType',                   'N', 2,  2,'[0-49][WYMCKRGBTFLPS]'], #
 131 => ['ImageOrientation',            'N', 1,  1, '[PLS]'               ], #
 135 => ['LanguageIdentifier',          'N', 2,  3, '[a-zA-Z]{2,3}?'      ], #
 150 => ['AudioType',                   'N', 2,  2, '[012][ACMQRSTVW]'    ], #
 151 => ['AudioSamplingRate',           'N', 6,  6, '\d{6}'               ], #
 152 => ['AudioSamplingResolution',     'N', 2,  2, '\d{2}'               ], #
 153 => ['AudioDuration',               'N', 6,  6, $IPTC_re_dura         ], #
 154 => ['AudioOutcue',                 'N', 1, 64, $IPTC_re_line         ], #
 200 => ['ObjDataPreviewFileFormat',    'N', 2,  2, 'invalid,binary'      ], #
 201 => ['ObjDataPreviewFileFormatVer', 'N', 2,  2, 'invalid,binary'      ], #
 202 => ['ObjDataPreviewData',          'N', 1,256000,'invalid,binary'  ],}; #
#============================================================================#
#============================================================================#
#============================================================================#
# Esoteric tags for a Photoshop APP13 segment (not IPTC data);               #
# see the "VALID TAGS FOR PHOTOSHOP-STYLE APP13 DATA" section in the         #
# Image::MetaData::JPEG module perldoc page for further details.             #
# [tags 0x07d0 --> 0x0bb6 are reserved for path information]                 #
#----------------------------------------------------------------------------#
# Hash keys are numeric tags, here written in hexadecimal base.              #
# Fields: 0 -> Tag name, 1 -> repeatability ('N' means non-repeatable),      #
#         2,3 -> min and max length, 4 -> regular expression to match.       #
# The syntax specifications are currently just placeholder, but this could   #
# change in future. The only effect is to inhibit a direct assignement of    #
# the 'IPTC/NAA' dataset, which must be modified with specialised routines.  #
#----------------------------------------------------------------------------#
my $HASH_PHOTOSHOP_PATHINFO =                                                #
{( map { $_ => [ sprintf("PathInfo_%3x",$_),                                 #
		 ' ', 0, 65535, 'binary'] } (0x07d0..0x0bb6) ),              #
 0x0bb7 => ['ClippingPathName',         ' ', 0, 65535, 'binary'        ], }; #
#----------------------------------------------------------------------------#
my $HASH_PHOTOSHOP_GENERAL =                                                 #
{0x03e8 => ['Photoshop2Info',           ' ', 0, 65535, 'binary'           ], #
 0x03e9 => ['MacintoshPrintInfo',       ' ', 0, 65535, 'binary'           ], #
 0x03eb => ['Photoshop2ColorTable',     ' ', 0, 65535, 'binary'           ], #
 0x03ed => ['ResolutionInfo',           ' ', 0, 65535, 'binary'           ], #
 0x03ee => ['AlphaChannelsNames',       ' ', 0, 65535, 'binary'           ], #
 0x03ef => ['DisplayInfo',              ' ', 0, 65535, 'binary'           ], #
 0x03f0 => ['PStringCaption',           ' ', 0, 65535, 'binary'           ], #
 0x03f1 => ['BorderInformation',        ' ', 0, 65535, 'binary'           ], #
 0x03f2 => ['BackgroundColor',          ' ', 0, 65535, 'binary'           ], #
 0x03f3 => ['PrintFlags',               ' ', 0, 65535, 'binary'           ], #
 0x03f4 => ['BWHalftoningInfo',         ' ', 0, 65535, 'binary'           ], #
 0x03f5 => ['ColorHalftoningInfo',      ' ', 0, 65535, 'binary'           ], #
 0x03f6 => ['DuotoneHalftoningInfo',    ' ', 0, 65535, 'binary'           ], #
 0x03f7 => ['BWTransferFunc',           ' ', 0, 65535, 'binary'           ], #
 0x03f8 => ['ColorTransferFuncs',       ' ', 0, 65535, 'binary'           ], #
 0x03f9 => ['DuotoneTransferFuncs',     ' ', 0, 65535, 'binary'           ], #
 0x03fa => ['DuotoneImageInfo',         ' ', 0, 65535, 'binary'           ], #
 0x03fb => ['EffectiveBW',              ' ', 0, 65535, 'binary'           ], #
 0x03fc => ['ObsoletePhotoshopTag1',    ' ', 0, 65535, 'binary'           ], #
 0x03fd => ['EPSOptions',               ' ', 0, 65535, 'binary'           ], #
 0x03fe => ['QuickMaskInfo',            ' ', 0, 65535, 'binary'           ], #
 0x03ff => ['ObsoletePhotoshopTag2',    ' ', 0, 65535, 'binary'           ], #
 0x0400 => ['LayerStateInfo',           ' ', 0, 65535, 'binary'           ], #
 0x0401 => ['WorkingPathInfo',          ' ', 0, 65535, 'binary'           ], #
 0x0402 => ['LayersGroupInfo',          ' ', 0, 65535, 'binary'           ], #
 0x0403 => ['ObsoletePhotoshopTag3',    ' ', 0, 65535, 'binary'           ], #
 0x0404 => ['IPTC/NAA',                 ' ', 0, 65535, 'invalid'          ], #
 0x0405 => ['RawImageMode',             ' ', 0, 65535, 'binary'           ], #
 0x0406 => ['JPEGQuality',              ' ', 0, 65535, 'binary'           ], #
 0x0408 => ['GridGuidesInfo',           ' ', 0, 65535, 'binary'           ], #
 0x0409 => ['ThumbnailResource',        ' ', 0, 65535, 'binary'           ], #
 0x040a => ['CopyrightFlag',            ' ', 0, 65535, 'binary'           ], #
 0x040b => ['URL',                      ' ', 0, 65535, 'binary'           ], #
 0x040c => ['ThumbnailResource2',       ' ', 0, 65535, 'binary'           ], #
 0x040d => ['GlobalAngle',              ' ', 0, 65535, 'binary'           ], #
 0x040e => ['ColorSamplersResource',    ' ', 0, 65535, 'binary'           ], #
 0x040f => ['ICCProfile',               ' ', 0, 65535, 'binary'           ], #
 0x0410 => ['Watermark',                ' ', 0, 65535, 'binary'           ], #
 0x0411 => ['ICCUntagged',              ' ', 0, 65535, 'binary'           ], #
 0x0412 => ['EffectsVisible',           ' ', 0, 65535, 'binary'           ], #
 0x0413 => ['SpotHalftone',             ' ', 0, 65535, 'binary'           ], #
 0x0414 => ['IDsBaseValue',             ' ', 0, 65535, 'binary'           ], #
 0x0415 => ['UnicodeAlphaNames',        ' ', 0, 65535, 'binary'           ], #
 0x0416 => ['IndexedColourTableCount',  ' ', 0, 65535, 'binary'           ], #
 0x0417 => ['TransparentIndex',         ' ', 0, 65535, 'binary'           ], #
 0x0419 => ['GlobalAltitude',           ' ', 0, 65535, 'binary'           ], #
 0x041a => ['Slices',                   ' ', 0, 65535, 'binary'           ], #
 0x041b => ['WorkflowURL',              ' ', 0, 65535, 'binary'           ], #
 0x041c => ['JumpToXPEP',               ' ', 0, 65535, 'binary'           ], #
 0x041d => ['AlphaIdentifiers',         ' ', 0, 65535, 'binary'           ], #
 0x041e => ['URLList',                  ' ', 0, 65535, 'binary'           ], #
 0x0421 => ['VersionInfo',              ' ', 0, 65535, 'binary'           ], #
 0x2710 => ['PrintFlagsInfo',           ' ', 0, 65535, 'binary'        ], }; #
#----------------------------------------------------------------------------#
@$HASH_PHOTOSHOP_GENERAL{keys %$HASH_PHOTOSHOP_PATHINFO} =                   #
    values %$HASH_PHOTOSHOP_PATHINFO;                                        #
#============================================================================#
#============================================================================#
#============================================================================#
# Some scalar-valued hashes, which were once original databases, are now     #
# generated with "generate_lookup" from more general array-valued hashes     #
# (in practice, a single column is singled out from a multi-column table).   #
# %$HASH_APP1_IFD is built by merging the first column of 3 different hashes.#
#----------------------------------------------------------------------------#
my $HASH_PHOTOSHOP_TAGS  = generate_lookup($HASH_PHOTOSHOP_GENERAL     ,0);  #
my $HASH_PHOTOSHOP_PHUT  = generate_lookup($HASH_PHOTOSHOP_PATHINFO    ,0);  #
my $HASH_IPTC_TAGS_1     = generate_lookup($HASH_IPTC_GENERAL_1        ,0);  #
my $HASH_IPTC_TAGS_2     = generate_lookup($HASH_IPTC_GENERAL_2        ,0);  #
my $HASH_APP1_ROOT       = generate_lookup($HASH_APP1_ROOT_GENERAL     ,0);  #
my $HASH_APP1_GPS        = generate_lookup($HASH_GPS_GENERAL           ,0);  #
my $HASH_APP1_INTEROP    = generate_lookup($HASH_INTEROP_GENERAL       ,0);  #
my $HASH_APP1_IFD        = generate_lookup($HASH_APP1_IFD01_GENERAL    ,0);  #
my $HASH_APP1_SUBIFD     = generate_lookup($HASH_APP1_SUBIFD_GENERAL   ,0);  #
#============================================================================#
#============================================================================#
#============================================================================#
# Some segments (APP1 and APP3 currently) have an IFD-like structure, i.e.   #
# they can have "subdirectories" pointed to by offset tags. These subdirs    #
# are bifurcation points for the lookup process, and are represented by      #
# hash references instead of plain strings (scalars).                        #
#----------------------------------------------------------------------------#
$$HASH_APP1_IFD{SubIFD}     = $HASH_APP1_SUBIFD;   # Exif private tags       #
$$HASH_APP1_IFD{GPS}        = $HASH_APP1_GPS;      # GPS tags                #
$$HASH_APP3_IFD{Special}    = $HASH_APP3_SPECIAL;  # Special effect tags     #
$$HASH_APP3_IFD{Borders}    = $HASH_APP3_BORDERS;  # Border tags             #
$$HASH_APP1_SUBIFD{Interop} = $HASH_APP1_INTEROP;  # Interoperability tags   #
#============================================================================#
#============================================================================#
#============================================================================#
# MakerNote stuff is stored in a separated file; the return value of this    #
# inclusion is the $HASH_MAKERNOTES hash reference, containing all relevant  #
# parameters. We only have to link this new table into $HASH_APP1_SUBIFD.    #
#----------------------------------------------------------------------------#
our $HASH_MAKERNOTES = require 'Image/MetaData/JPEG/data/Makernotes.pl';     #
$$HASH_APP1_SUBIFD{'MakerNoteData_' . $_} =                                  #
    generate_lookup($$HASH_MAKERNOTES{$_}{tags} ,0)                          #
    for keys %$HASH_MAKERNOTES;                                              #
#============================================================================#
#============================================================================#
#============================================================================#
# Syntax tables and mandatory records tables for IPTC data are hidden in the #
# corresponding tag hashes. Another %IFD_SUBDIRS is overkill here.           #
#----------------------------------------------------------------------------#
$$HASH_IPTC_TAGS_1{__syntax}    = $HASH_IPTC_GENERAL_1;                      #
$$HASH_IPTC_TAGS_1{__mandatory} = $HASH_IPTC_MANDATORY_1;                    #
$$HASH_IPTC_TAGS_2{__syntax}    = $HASH_IPTC_GENERAL_2;                      #
$$HASH_IPTC_TAGS_2{__mandatory} = $HASH_IPTC_MANDATORY_2;                    #
$$HASH_PHOTOSHOP_TAGS{__syntax} = $HASH_PHOTOSHOP_GENERAL;                   #
#============================================================================#
#============================================================================#
#============================================================================#
# The following hash is the database for the tag-to-tagname translation; of  #
# course, records with a textual tag are not listed here. The navigation     #
# through this structure is best done with the help of the JPEG_lookup       #
# function, so this hash is not exported (as it was some time ago).          #
#----------------------------------------------------------------------------#
my $psdirname = sub { $APP13_PHOTOSHOP_DIRNAME . '_' . $_[0] };              #
#----------------------------------------------------------------------------#
my $JPEG_RECORD_NAME =                                                       #
{APP1  => {%$HASH_APP1_ROOT,                                   # APP1 root   #
	   IFD0                     => $HASH_APP1_IFD,         # main image  #
	   IFD1                     => $HASH_APP1_IFD, },      # thumbnail   #
 APP2  => {TagTable                 => $HASH_APP2_ICC, },      # ICC data    #
 APP3  => {IFD0                     => $HASH_APP3_IFD, },      # main image  #
 APP13 => {&$psdirname('8BIM')      => $HASH_PHOTOSHOP_TAGS,   # PS:8BIM     #
	   &$psdirname('8BPS')      => $HASH_PHOTOSHOP_TAGS,   # PS: < ver 4 #
	   &$psdirname('PHUT')      => $HASH_PHOTOSHOP_PHUT,   # PS:PHUT     #
	   $APP13_IPTC_DIRNAME.'_1' => $HASH_IPTC_TAGS_1,      # PS:IPTC R:1 #
	   $APP13_IPTC_DIRNAME.'_2' => $HASH_IPTC_TAGS_2, }, };# PS:IPTC R:2 #
#----------------------------------------------------------------------------#

###########################################################
# This helper function returns record data from the       #
# %$JPEG_RECORD_NAME hash. The arguments are first joined #
# with the '@' character, and then splitted on the same   #
# character to give a list of '@'-free strings (this al-  #
# lows for greater flexibility at call time); this list   #
# contains keys for exploring the %$JPEG_RECORD_NAME hash;#
# e.g., the arguments ('APP1', 'IFD0@GPS', 0x1e) select   #
# $JPEG_RECORD_NAME{APP1}{IFD0}{GPS}{0x1e}, i.e. the      #
# textual name of the GPS record with key = 0x1e in the   #
# IFD0 in the APP1 segment. If, at some point during the  #
# search, an argument fails (it is not a valid key) or it #
# is not defined, the search is interrupted, and undef is #
# returned. Note also that the return value could be a    #
# string as well as a hash reference, depending on the    #
# search depth. If the key lookup for the last argument   #
# fails, a reverse lookup is run (i.e., the key corres-   #
# ponding to the value equal to the last user argument is #
# searched). If even this lookup fails, undef is returned.#
########################################################### 
sub JPEG_lookup {
    # all searches start from here
    my $lookup = $JPEG_RECORD_NAME;
    # print a debugging message and return immediately unless
    # all arguments are scalars (i.e., references are not allowed)
    for (@_) { print "wrong argument(s) in JPEG_lookup call", return if ref; }
    # delete all undefined or "false" arguments
    @_ = grep { defined $_ } @_;
    # join all remaining arguments
    my $keystring = join('@', @_);
    # split the resulting string on '@'
    my @keylist = split('@', $keystring);
    # extract and save the last argument for special treatment
    my $last = pop @keylist;
    # delete all false arguments
    @keylist = grep { $_ } @keylist;
    # refuse to work with $last undefined
    return unless defined $last;
    # consume the list of "normal" arguments: they must be successive
    # keys for navigation in a multi-level hash. Interrupt the search
    # as soon as an argument is undefined or $lookup is not a hash ref
    for (@keylist) {
	# return undef as soon as an argument is undefined
	return undef unless $_;
	# go one level deeper in the hash exploration
	$lookup = $$lookup{$_};
	# return undef if $lookup is no more a hash reference
	return undef unless ref $lookup eq 'HASH'; }
    # $lookup is a hash reference now. Return the value
    # corresponding to $last (used as a key) if it exists.
    return $$lookup{$last} if exists $$lookup{$last};
    # if we are still here, scan the hash looking for a value equal to
    # $last, and return its key. Avoid each %$lookup, since we could
    # exit the loop before the end and I don't want to reset the
    # iterator in that stupid manner.
    for (keys %$lookup) { return $_ if $$lookup{$_} eq $last; }
    # if we are still here, we have lost
    return undef;
};

#============================================================================#
#============================================================================#
#============================================================================#
# This hash is needed to overcome some complications due to the APP1/APP3    #
# structure: some IFDs or sub-IFDs can contain offset tags (tags whose value #
# is an offset in the JPEG file), linking to nested structures, which are    #
# represented internally as sub-lists pointed to by $REFERENCE records; the  #
# sub-lists deserve in general a more significant name than the offset tag   #
# name. Each key in the following hash is a path to an IFD or one of its     #
# subdirectories; the corresponding value is a hash reference, with the      #
# pointed hash mapping offset tag numerical values to subdirectory names.    #
# (the [tag names] -> [tag numerical values] translation is done afterwards) #
#----------------------------------------------------------------------------#
# A sub hash must also own the '__syntax' and '__mandatory' keys, returning  #
# a reference to a hash of syntactical properties to be respected by data in #
# the corresponding IFD and a reference to a hash of mandatory records.      #
# These special entries are of course treated differently from the others ...#
#----------------------------------------------------------------------------#
# When the JPEG file is read, offset tag records are not stored; insted, we  #
# store a $REFERENCE record with the mapped name (and the name of the origi- #
# nating offset tag saved in the "extra" field). The following hash can then #
# be used in both directions to do data parsing/dumping.                     #
#----------------------------------------------------------------------------#
our %IFD_SUBDIRS =                                                           #
('APP1'             => {'__syntax'           => $HASH_APP1_ROOT_GENERAL,     #
			'__mandatory'        => $HASH_APP1_ROOT_MANDATORY }, #
 'APP1@IFD0'        => {'__syntax'           => $HASH_APP1_IFD01_GENERAL,    #
			'__mandatory'        => $HASH_APP1_IFD0_MANDATORY,   #
			'GPSInfo'            => 'GPS',                       #
			'ExifOffset'         => 'SubIFD'},                   #
 'APP1@IFD0@GPS'    => {'__syntax'           => $HASH_GPS_GENERAL,           #
			'__mandatory'        => $HASH_GPS_MANDATORY },       #
 'APP1@IFD0@SubIFD' => {'__syntax'           => $HASH_APP1_SUBIFD_GENERAL,   #
			'__mandatory'        => $HASH_APP1_SUBIFD_MANDATORY, #
			'MakerNote'          => 'MakerNoteData',             #
			'InteroperabilityOffset' => 'Interop'},              #
 'APP1@IFD0@SubIFD@Interop' => {'__syntax'   => $HASH_INTEROP_GENERAL,       #
				'__mandatory'=> $HASH_INTEROP_MANDATORY },   #
 'APP1@IFD1'        => {'__syntax'           => $HASH_APP1_IFD01_GENERAL,    #
			'__mandatory'        => $HASH_APP1_IFD1_MANDATORY }, #
 'APP3@IFD0'        => {'BordersIFD'         => 'Borders',                   #
			'SpecialEffectsIFD'  => 'Special'}, );               #
#----------------------------------------------------------------------------#
while (my ($ifd_path, $ifd_hash) = each %IFD_SUBDIRS) {                      #
    my %h = map { $_ =~ /__syntax|__mandatory/ ? ($_ => $$ifd_hash{$_}) :    #
		      (JPEG_lookup($ifd_path, $_) => $$ifd_hash{$_})         #
		  } keys %$ifd_hash;                                         #
    $IFD_SUBDIRS{$ifd_path} = \ %h; }                                        #
#============================================================================#
#============================================================================#
#============================================================================#
# These parameters must be initialised with JPEG_lookup, because I don't     #
# want to have them written explicitely in more than one place.              #
#----------------------------------------------------------------------------#
our $APP1_TH_TYPE  = JPEG_lookup('APP1@IFD1@Compression');                   #
our $THJPEG_OFFSET = JPEG_lookup('APP1@IFD1@JPEGInterchangeFormat');         #
our $THJPEG_LENGTH = JPEG_lookup('APP1@IFD1@JPEGInterchangeFormatLength');   #
our $THTIFF_OFFSET = JPEG_lookup('APP1@IFD1@StripOffsets');                  #
our $THTIFF_LENGTH = JPEG_lookup('APP1@IFD1@StripByteCounts');               #
our $MAKERNOTE_TAG = JPEG_lookup('APP1@IFD0@SubIFD@MakerNote');              #
#----------------------------------------------------------------------------#

# successful package load
1;
