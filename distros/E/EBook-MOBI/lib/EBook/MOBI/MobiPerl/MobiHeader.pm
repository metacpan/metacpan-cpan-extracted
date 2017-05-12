use strict;

#    Copyright (C) 2007 Tommy Persson, tpe@ida.liu.se
#
#    MobiPerl/MobiHeader.pm, Copyright (C) 2007 Tommy Persson, tpe@ida.liu.se
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.


#
# This is a patch of a function in Palm::Doc to be able to handle
# DRM:ed files.
#


package EBook::MOBI::Palm::Doc;

our $VERSION = 2011.11.26;

sub _parse_headerrec($) {
	my $record = shift;
	return undef unless exists $record->{'data'};

	# Doc header is minimum of 16 bytes
	return undef if length $record->{'data'} < 16;


	my ($version,$spare,$ulen, $records, $recsize, $position)
		= unpack( 'n n N n n N', $record->{'data'} );

	# the header is followed by a list of record sizes. We don't use
	# this since we can guess the sizes pretty easily by looking at
	# the actual records.

	# According to the spec, $version is either 1 (uncompressed)
	# or 2 (compress), while spare is always zero. AportisDoc supposedly sets
	# spare to something else, so screw AportisDoc.

    #
    # $version is 17480 for DRM:ed MobiPocket books
    #
    # So comment away the check
   ###	return undef if $version != DOC_UNCOMPRESSED and $version != DOC_COMPRESSED;

	return undef if $spare != 0;

	$record->{'version'} = $version;
	$record->{'length'} = $ulen;
	$record->{'records'} = $records;
	$record->{'recsize'} = $recsize;
	$record->{'position'} = $position;

	return $record;
}




package EBook::MOBI::MobiPerl::MobiHeader;

use FindBin qw($RealBin);
use lib "$RealBin";

use EBook::MOBI::MobiPerl::EXTH;

use strict;

#
# TYPE: 2=book
#
our $VERSION = '0.72'; # VERSION: Should be 3 or 4
#
# CODEPAGE: utf-8: 65001; westerner: 1252
#
# IMAGERECORDINDEX: the index of the first record with image in it
#
# Language seems to be stored in 4E: en-us    0409
#                                       sv    041d
#                                       fi    000b
#                                       en    0009
#
# 0x50 and 0x54 might also be some kind of language specification
#

#
# 0000: MOBI        header-size type      codepage 
# 0010: unique-id   version     FFFFFFFF  FFFFFFFF
#
# header-size = E4 if version = 4
# type        = 2 - book
# codepage    = 1252 - westerner
# unique-id   = seems to be random
# version     = 3 or 4
#
# 0040: data4  exttitleoffset exttitlelength language
# 0050: data1  data2          data3          nonbookrecordpointer
# 0060: data5
#
# data1 and data2 id 09 in Oxford dictionary. The same as languange...
# nonbookrecordpointer in Oxford is 0x7167. data5 is 0x7157
# data3 is 05 in Oxford so maybe this is the version?
#
#pdurrant:
#
# 0040: nonbookrecordpointer  exttitleoffset exttitlelength language
# 0050: data1  data2          data3          firstimagerecordpointer
# 0060: data5
#


my %langmap = (
	       "es"    => 0x000a,
	       "sv"    => 0x001d,
	       "sv-se" => 0x041d,
	       "sv-fi" => 0x081d,
	       "fi"    => 0x000b,
	       "en"    => 0x0009,
	       "en-au" => 0x0C09,
	       "en-bz" => 0x2809,
	       "en-ca" => 0x1009,
	       "en-cb" => 0x2409,
	       "en-ie" => 0x1809,
	       "en-jm" => 0x2009,
	       "en-nz" => 0x1409,
	       "en-ph" => 0x3409,
	       "en-za" => 0x1c09,
	       "en-tt" => 0x2c09,
	       "en-us" => 0x0409,
	       "en-gb" => 0x0809,
	       "en-zw" => 0x3009,
	       "da"    => 0x0006,
	       "da-dk" => 0x0406,
	       "da"    => 0x0006,
	       "da"    => 0x0006,
	       "nl"    => 0x0013,
	       "nl-be" => 0x0813,
	       "nl-nl" => 0x0413,
	       "fi"    => 0x000b,
	       "fi-fi" => 0x040b,
	       "fr"    => 0x000c,
	       "fr-fr" => 0x040c,
	       "de"    => 0x0007,
	       "de-at" => 0x0c07,
	       "de-de" => 0x0407,
	       "de-lu" => 0x1007,
	       "de-ch" => 0x0807,
	       "no"    => 0x0014,
	       "nb-no" => 0x0414,
	       "nn-no" => 0x0814,
	       "zh-cn" => 0x0804,
);


my %mainlanguage = (
		 0 => "NEUTRAL",
		 54 => "AFRIKAANS",
		 28 => "ALBANIAN",
		 1 => "ARABIC",
		 43 => "ARMENIAN",
		 77 => "ASSAMESE",
		 44 => "AZERI",
		 45 => "BASQUE",
		 35 => "BELARUSIAN",
		 69 => "BENGALI",
		 2 => "BULGARIAN",
		 3 => "CATALAN",
		 4 => "CHINESE",
		 26 => "CROATIAN",
		 5 => "CZECH",
		 6 => "DANISH",
		 19 => "DUTCH",
		 9 => "ENGLISH",
		 37 => "ESTONIAN",
		 56 => "FAEROESE",
		 41 => "FARSI",
		 11 => "FINNISH",
		 12 => "FRENCH",
		 55 => "GEORGIAN",
		 7 => "GERMAN",
		 8 => "GREEK",
		 71 => "GUJARATI",
		 13 => "HEBREW",
		 57 => "HINDI",
		 14 => "HUNGARIAN",
		 15 => "ICELANDIC",
		 33 => "INDONESIAN",
		 16 => "ITALIAN",
		 17 => "JAPANESE",
		 75 => "KANNADA",
		 63 => "KAZAK",
		 87 => "KONKANI",
		 18 => "KOREAN",
		 38 => "LATVIAN",
		 39 => "LITHUANIAN",
		 47 => "MACEDONIAN",
		 62 => "MALAY",
		 76 => "MALAYALAM",
		 58 => "MALTESE",
		 78 => "MARATHI",
		 97 => "NEPALI",
		 20 => "NORWEGIAN",
		 72 => "ORIYA",
		 21 => "POLISH",
		 22 => "PORTUGUESE",
		 70 => "PUNJABI",
		 23 => "RHAETOROMANIC",
		 24 => "ROMANIAN",
		 25 => "RUSSIAN",
		 59 => "SAMI",
		 79 => "SANSKRIT",
		 26 => "SERBIAN",
		 27 => "SLOVAK",
		 36 => "SLOVENIAN",
		 46 => "SORBIAN",
		 10 => "SPANISH",
		 48 => "SUTU",
		 65 => "SWAHILI",
		 29 => "SWEDISH",
		 73 => "TAMIL",
		 68 => "TATAR",
		 74 => "TELUGU",
		 30 => "THAI",
		 49 => "TSONGA",
		 50 => "TSWANA",
		 31 => "TURKISH",
		 34 => "UKRAINIAN",
		 32 => "URDU",
		 67 => "UZBEK",
		 42 => "VIETNAMESE",
		 52 => "XHOSA",
		 53 => "ZULU",
		 );


my $langmap = {};
$langmap->{"ENGLISH"} = {
		   1 => "ENGLISH_US",
		   2 => "ENGLISH_UK",
		   3 => "ENGLISH_AUS",
		   4 => "ENGLISH_CAN",
		   5 => "ENGLISH_NZ",
		   6 => "ENGLISH_EIRE",
		   7 => "ENGLISH_SOUTH_AFRICA",
		   8 => "ENGLISH_JAMAICA",
		   10 => "ENGLISH_BELIZE",
		   11 => "ENGLISH_TRINIDAD",
		   12 => "ENGLISH_ZIMBABWE",
		   13 => "ENGLISH_PHILIPPINES",
	       };

my %sublanguage = (
		   0 => "NEUTRAL",
		   1 => "ARABIC_SAUDI_ARABIA",
		   2 => "ARABIC_IRAQ",
		   3 => "ARABIC_EGYPT",
		   4 => "ARABIC_LIBYA",
		   5 => "ARABIC_ALGERIA",
		   6 => "ARABIC_MOROCCO",
		   7 => "ARABIC_TUNISIA",
		   8 => "ARABIC_OMAN",
		   9 => "ARABIC_YEMEN",
		   10 => "ARABIC_SYRIA",
		   11 => "ARABIC_JORDAN",
		   12 => "ARABIC_LEBANON",
		   13 => "ARABIC_KUWAIT",
		   14 => "ARABIC_UAE",
		   15 => "ARABIC_BAHRAIN",
		   16 => "ARABIC_QATAR",
		   1 => "AZERI_LATIN",
		   2 => "AZERI_CYRILLIC",
		   1 => "CHINESE_TRADITIONAL",
		   2 => "CHINESE_SIMPLIFIED",
		   3 => "CHINESE_HONGKONG",
		   4 => "CHINESE_SINGAPORE",
		   1 => "DUTCH",
		   2 => "DUTCH_BELGIAN",
		   1 => "FRENCH",
		   2 => "FRENCH_BELGIAN",
		   3 => "FRENCH_CANADIAN",
		   4 => "FRENCH_SWISS",
		   5 => "FRENCH_LUXEMBOURG",
		   6 => "FRENCH_MONACO",
		   1 => "GERMAN",
		   2 => "GERMAN_SWISS",
		   3 => "GERMAN_AUSTRIAN",
		   4 => "GERMAN_LUXEMBOURG",
		   5 => "GERMAN_LIECHTENSTEIN",
		   1 => "ITALIAN",
		   2 => "ITALIAN_SWISS",
		   1 => "KOREAN",
		   1 => "LITHUANIAN",
		   1 => "MALAY_MALAYSIA",
		   2 => "MALAY_BRUNEI_DARUSSALAM",
		   1 => "NORWEGIAN_BOKMAL",
		   2 => "NORWEGIAN_NYNORSK",
		   2 => "PORTUGUESE",
		   1 => "PORTUGUESE_BRAZILIAN",
		   2 => "SERBIAN_LATIN",
		   3 => "SERBIAN_CYRILLIC",
		   1 => "SPANISH",
		   2 => "SPANISH_MEXICAN",
		   4 => "SPANISH_GUATEMALA",
		   5 => "SPANISH_COSTA_RICA",
		   6 => "SPANISH_PANAMA",
		   7 => "SPANISH_DOMINICAN_REPUBLIC",
		   8 => "SPANISH_VENEZUELA",
		   9 => "SPANISH_COLOMBIA",
		   10 => "SPANISH_PERU",
		   11 => "SPANISH_ARGENTINA",
		   12 => "SPANISH_ECUADOR",
		   13 => "SPANISH_CHILE",
		   14 => "SPANISH_URUGUAY",
		   15 => "SPANISH_PARAGUAY",
		   16 => "SPANISH_BOLIVIA",
		   17 => "SPANISH_EL_SALVADOR",
		   18 => "SPANISH_HONDURAS",
		   19 => "SPANISH_NICARAGUA",
		   20 => "SPANISH_PUERTO_RICO",
		   1 => "SWEDISH",
		   2 => "SWEDISH_FINLAND",
		   1 => "UZBEK_LATIN",
		   2 => "UZBEK_CYRILLIC",
		   );

my %booktypedesc = (2 => "BOOK",
		    3 => "PALMDOC",
		    4 => "AUDIO",
		    257 => "NEWS",
		    258 => "NEWS_FEED",
		    259 => "NEWS_MAGAZINE",
		    513 => "PICS",
		    514 => "WORD",
		    515 => "XLS",
		    516 => "PPT",
		    517 => "TEXT",
		    518 => "HTML",
		   );

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    bless {
	TYPE => 2,
	VERSION => 4,
	CODEPAGE => 1252,
	TITLE => "Unspecified Title",
	AUTHOR => "Unspecified Author",
	PUBLISHER => "",
	DESCRIPTION => "",
	SUBJECT => "",
	IMAGERECORDINDEX => 0,
	LANGUAGE => "en",
	COVEROFFSET => -1,
	THUMBOFFSET => -1,
	@_
    }, $class;
}

sub set_author {
    my $self = shift;
    my $val = shift;
    $self->{AUTHOR} = $val;
}

sub get_author {
    my $self = shift;
    return $self->{AUTHOR};
}

sub set_cover_offset {
    my $self = shift;
    my $val = shift;
    $self->{COVEROFFSET} = $val;
}

sub get_cover_offset {
    my $self = shift;
    return $self->{COVEROFFSET};
}

sub set_thumb_offset {
    my $self = shift;
    my $val = shift;
    $self->{THUMBOFFSET} = $val;
}

sub get_thumb_offset {
    my $self = shift;
    return $self->{THUMBOFFSET};
}

sub set_publisher {
    my $self = shift;
    my $val = shift;
    $self->{PUBLISHER} = $val;
}

sub get_publisher {
    my $self = shift;
    return $self->{PUBLISHER};
}

sub set_description {
    my $self = shift;
    my $val = shift;
    $self->{DESCRIPTION} = $val;
}

sub get_description {
    my $self = shift;
    return $self->{DESCRIPTION};
}

sub set_subject {
    my $self = shift;
    my $val = shift;
    $self->{SUBJECT} = $val;
}

sub get_subject {
    my $self = shift;
    return $self->{SUBJECT};
}

sub set_language {
    my $self = shift;
    my $val = shift;
    $self->{LANGUAGE} = $val;
}

sub get_language {
    my $self = shift;
    return $self->{LANGUAGE};
}

sub set_title {
    my $self = shift;
    my $val = shift;
    $self->{TITLE} = $val;
}

sub get_title {
    my $self = shift;
    return $self->{TITLE};
}

sub set_image_record_index {
    my $self = shift;
    my $val = shift;
    $self->{IMAGERECORDINDEX} = $val;
}

sub get_image_record_index {
    my $self = shift;
    return $self->{IMAGERECORDINDEX};
}

sub get_type {
    my $self = shift;
    return $self->{TYPE};
}

sub get_codepage {
    my $self = shift;
    return $self->{CODEPAGE};
}

sub set_codepage {
    my $self = shift;
    my $value = shift;
    $self->{CODEPAGE} = $value;
}

sub set_version {
    my $self = shift;
    my $val = shift;
    $self->{VERSION} = $val;
}

sub get_version {
    my $self = shift;
    return $self->{VERSION};
}

sub get_unique_id {
    my $self = shift;
    my $r1 = int (rand (256));
    my $r2 = int (rand (256));
    my $r3 = int (rand (256));
    my $r4 = int (rand (256));
    my $res = $r1+$r2*256+$r3*256*256+$r4*256*256*256;
    return $res;
}

sub get_header_size {
    my $self = shift;
    my $res = 0x74;
    if ($self->get_version () == 4) {
	$res = 0xE4;
    }
    return $res;
}

sub get_extended_header_data {
    my $self = shift;
    my $author = $self->get_author ();

    my $eh = new EBook::MOBI::MobiPerl::EXTH;
    $eh->set ("author", $author);
    my $pub = $self->get_publisher ();
    $eh->set ("publisher", $pub) if $pub;

    my $desc = $self->get_description ();
    $eh->set ("description", $desc) if $desc;

    my $subj = $self->get_subject ();
    $eh->set ("subject", $subj) if $subj;

    my $coffset = $self->get_cover_offset ();
    if ($coffset >= 0) {
##	my $data = pack ("N", $coffset);
##	print STDERR "COFFSET:$coffset:$data:\n";
	$eh->set ("coveroffset", $coffset);
    }

    my $toffset = $self->get_thumb_offset ();
    if ($toffset >= 0) {
##	my $data = pack ("N", $toffset);
##	my $hex = MobiPerl::Util::iso2hex ($data);
##	print STDERR "TOFFSET:$toffset:$hex\n";
	$eh->set ("thumboffset", $toffset);
    }

##    $eh->set ("hasfakecover", pack ("N", 0));

    return $eh->get_data ();
}

sub get_data {
    my $self = shift;
    my $res = "";

    my $vie1 = 0; # 0x11 Alice 0x0D Rosenbaum 0xFFFFFFFF, Around the world
    $vie1 = 0xFFFFFFFF;

    my $vie2 = 0x04; # had this, around the world have 0x01

    my $use_extended_header = 1;
    my $extended_header_flag = 0x00;
    if ($use_extended_header) {
	$extended_header_flag = 0x50; # At MOBI+0x70
    }

    my $extended_title_offset = $self->get_header_size () + 16 + length ($self->get_extended_header_data ());
    my $extended_title_length = length ($self->get_title ());

    #print STDERR "MOBIHDR: imgrecpointer: ", $self->get_image_record_index (), "\n";

    $res .= pack ("a*NNNNN", "MOBI",
		  $self->get_header_size (), 
		  $self->get_type (), 
		  $self->get_codepage (), 
		  $self->get_unique_id (), 
		  $self->get_version ());

    $res .= pack ("NN", 0xFFFFFFFF, 0xFFFFFFFF);
    $res .= pack ("NNNN", 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);
    $res .= pack ("NNNN", 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);
    my $langnumber = $self->get_language ();
    if (defined $langmap{$langnumber}) {
	$langnumber = $langmap{$langnumber};
    }
    $res .= pack ("NNNN", $vie1, $extended_title_offset, 
		  $extended_title_length, $langnumber);
    $res .= pack ("NNNN", 0xFFFFFFFF, 0xFFFFFFFF, $vie2, $self->get_image_record_index ());
    $res .= pack ("NNNN", 0xFFFFFFFF, 0, 0xFFFFFFFF, 0);
    $res .= pack ("N", $extended_header_flag);
#    print STDERR "MOBIHEADERSIZE: $mobiheadersize " . length ($header->{'data'}). "\n";
    while (length ($res) < $self->get_header_size ()) {
###	print STDERR "LEN: " . length ($res) . " - " . $self->get_header_size () . "\n";
	$res .= pack ("N", 0);
    }

    substr ($res, 0x94, 4, pack ("N", 0xFFFFFFFF));
    substr ($res, 0x98, 4, pack ("N", 0xFFFFFFFF));

    substr ($res, 0xb0, 4, pack ("N", 0xFFFFFFFF)); 
    # maybe pointer to last image or to thumbnail image record

    substr ($res, 0xb8, 4, pack ("N", 0xFFFFFFFF)); # record pointer
    substr ($res, 0xc0, 4, pack ("N", 0xFFFFFFFF)); # record pointer
    substr ($res, 0xc8, 4, pack ("N", 0xFFFFFFFF)); # record pointer

    #
    # unknown
    #

    substr ($res, 0xd0, 4, pack ("N", 0xFFFFFFFF));
    substr ($res, 0xd8, 4, pack ("N", 0xFFFFFFFF));
    substr ($res, 0xdc, 4, pack ("N", 0xFFFFFFFF));


    $res .= $self->get_extended_header_data ();
    $res .= pack ("a*", $self->get_title ());
    
    #
    # Why?
    #
    for (1..48) {
	$res .= pack ("N", 0);
    }
    return $res;
}


#
# Help function that is not dependent on object state
#

sub get_extended_title {
    my $h = shift;
    my $len = length ($h);
    my ($exttitleoffset) = unpack ("N", substr ($h, 0x44));
    my ($exttitlelength) = unpack ("N", substr ($h, 0x48));
    my ($title) = unpack ("a$exttitlelength", substr ($h, $exttitleoffset-16));
    return $title;
}

sub set_extended_title {
    my $mh = shift;
    my $len = length ($mh);
    my $title = shift;
    my $titlelen = length ($title);
    my ($exttitleoffset) = unpack ("N", substr ($mh, 0x44));
    my ($exttitlelength) = unpack ("N", substr ($mh, 0x48));
    my ($version) = unpack ("N", substr ($mh, 0x14));

    my $res = substr ($mh, 0, $exttitleoffset-16);
    my $aftertitle = substr ($mh, $exttitleoffset-16+$exttitlelength);

    $res .= $title;

    my $diff = $titlelen - $exttitlelength;
    if ($diff <= 0) {
	foreach ($diff .. -1) {
	    $res .= pack ("C", 0);
	    $diff++;
	}
    } else {
	my $comp = $diff % 4;
	if ($comp) {
	    foreach ($comp .. 3) {
		$res .= pack ("C", 0);
		$diff++;
	    }
	}
    }
    $res = fix_pointers ($res, $exttitleoffset, $diff);

    $res .= $aftertitle;
    substr ($res, 0x48, 4, pack ("N", $titlelen));

    return $res;
}

sub get_mh_language_code {
    my $h = shift;
    my $len = length ($h);
    my ($lang) = unpack ("N", substr ($h, 0x4C));
    return $lang;
}

sub get_language_desc {
    my $code = shift;
    my $lid = $code & 0xFF;
    my $lang = $mainlanguage{$lid};
    my $sublid = ($code >> 10) & 0xFF;
    my $sublang = $langmap->{$lang}->{$sublid};
    my $res = "";
    $res .= "$lang";
    $res .= " - $sublang";
    return $res;
}


sub set_booktype {
    my $mh = shift;
    my $len = length ($mh);
    my $type = shift;
    substr ($mh, 0x08, 4, pack ("N", $type));
    return $mh;
}

sub set_language_in_header {
    my $mh = shift;
    my $len = length ($mh);
    my $lan = shift;

    my $langnumber = $lan;
    if (defined $langmap{$langnumber}) {
	$langnumber = $langmap{$langnumber};
    }

    substr ($mh, 0x4C, 4, pack ("N", $langnumber));
    return $mh;
}

sub add_exth_data {
    my $h = shift;
    my $type = shift;
    my $data = shift;
    return set_exth_data ($h, $type, $data, 1);
}

sub set_exth_data {
    my $h = shift;
    my $len = length ($h);
    my $type = shift;
    my $data = shift;
    my $addflag = shift;
    my $delexthindex = shift;
    my $res = $h;
    if (defined $data) {
	print STDERR "Setting extended header data: $type - $data\n";
    } else {
	print STDERR "Deleting extended header data of type: $type - $delexthindex\n";
    }

    my ($doctype, $length, $htype, $codepage, $uniqueid, $ver) =
	unpack ("a4NNNNN", $h);

    my ($exthflg) = unpack ("N", substr ($h, 0x70));

    my $exth = substr ($h, $length);
    my $prefix = substr ($h, 0, $length);
    my $suffix;
    my $mobidiff = 0;
    my $eh;
    my $exthlen = 0;
    if ($exthflg & 0x40) {
	my ($doctype, $exthlen1, $n_items) = unpack ("a4NN", $exth);
	$exthlen = $exthlen1;
	$suffix = substr ($exth, $exthlen);
	$eh = new MobiPerl::EXTH ($exth);
    } else {
	$eh = new MobiPerl::EXTH ();
	$suffix = $exth;
	substr ($prefix, 0x70, 4, pack ("N", $exthflg | 0x40));
	# pdurrant: as well as setting the exthflg, we need make sure the version >= 4
	if ($ver < 4) {
	    substr($prefix, 0x14, 4, pack("N",4));
	}

    	# pdurrant: and if the mobi header is short, we need to increase its size
    	if ($length < 0xE8) {
	    if ($length < 0x9C) {
    		#get rid of any old bad data inappropriate for new header
    		$prefix = substr($prefix, 0, 0x74);
	    }
	    $prefix .= substr(pack("CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC", 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF), length($prefix)-0xE8);
	    $mobidiff = 0xE8-$length;
	    substr ($prefix, 4, 4, pack ("N", 0xE8));
	}
    }

    if ($addflag) {
	$eh->add ($type, $data);
    } else {
	if (defined $data) {
	    $eh->set ($type, $data);
	} else {
	    $eh->delete ($type, $delexthindex);
	}
    }
    print STDERR "GETSTRING: ", $eh->get_string ();

    #
    # Fix DRM and TITLE info pointers...
    #
    
    my $exthdata = $eh->get_data ();

    my $exthdiff = length ($exthdata)-$exthlen;
    if ($exthdiff <= 0) {
	foreach ($exthdiff .. -1) {
	    $exthdata .= pack ("C", 0);
	    $exthdiff++;
	}
    }

    $res = $prefix . $exthdata . $suffix;

    $res = fix_pointers ($res, $length, $mobidiff+$exthdiff);

    return $res;
}


sub fix_pointers {
    my $mh = shift;
    my $startblock = shift;
    my $offset = shift;

    #
    # Fix pointers to long title and to DRM record
    # 

    my ($exttitleoffset) = unpack ("N", substr ($mh, 0x44));
    if ($exttitleoffset > $startblock and $offset > 0) {
	substr ($mh, 0x44, 4, pack ("N", $exttitleoffset+$offset));	
    }
    # pdurrant
    my ($ehlen) = unpack ("N", substr ($mh,0x04));
    if ($ehlen > 0x98 ) { #pdurrant
	my ($drmoffset) = unpack ("N", substr ($mh, 0x98));
	if ($drmoffset != 0xFFFFFFFF and
	    $drmoffset > $startblock and $offset > 0) {
	    substr ($mh, 0x98, 4, pack ("N", $drmoffset+$offset));
	}
    }
    return $mh;
}

sub get_booktype_desc {
    my $type = shift;
    my $res = $type;
    if (defined $booktypedesc{$type}) {
	$res = $booktypedesc{$type};
    }
    return $res;
}



return 1;

__END__

=head1 NAME

EBook::MOBI::MobiPerl::MobiHeader

=head1 INFO

For information about this code, please visit L<https://dev.mobileread.com/trac/mobiperl>

=cut

