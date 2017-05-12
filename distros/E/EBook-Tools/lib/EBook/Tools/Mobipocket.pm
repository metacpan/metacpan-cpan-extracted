package EBook::Tools::Mobipocket;
use warnings; use strict; use utf8;
#use warnings::unused;
#use 5.010; # Needed for smart-match operator
#v5.10 feature use removed until 5.10 is standard on MacOSX and Debian
use English qw( -no_match_vars );
use version 0.74; our $VERSION = qv("0.5.0");

# Perl Critic overrides:
## no critic (Package variable)
# Double-sigils are needed for lexical variables in clear print statements
## no critic (Double-sigil dereference)
# Mixed case subs and the variable %record are inherited from Palm::PDB
## no critic (ProhibitAmbiguousNames)
## no critic (ProhibitMixedCaseSubs)

require Exporter;
use base qw(Exporter Palm::Raw);

our @EXPORT_OK;
@EXPORT_OK = qw (
    &find_mobidedrm
    &find_mobigen
    &parse_mobi_exth
    &parse_mobi_header
    &parse_mobi_language
    &pid_append_checksum
    &pid_is_valid
    &pukall_cipher_1
    &system_mobidedrm
    &system_mobigen
    &unpack_mobi_language
    );
our %EXPORT_TAGS = ('all' => [@EXPORT_OK]);

sub import   ## no critic (Always unpack @_ first)
{
    &Palm::PDB::RegisterPDBHandlers( __PACKAGE__, [ "MOBI", "BOOK" ], );
    &Palm::PDB::RegisterPRCHandlers( __PACKAGE__, [ "MOBI", "BOOK" ], );
    EBook::Tools::Mobipocket->export_to_level(1, @_);
    return;
}

=head1 NAME

EBook::Tools::Mobipocket - Palm::PDB handler for manipulating the Mobipocket format.

=head1 SYNOPSIS

 use EBook::Tools::Mobipocket qw(:all);
 my $mobi = EBook::Tools::Mobipocket->new();
 $mobi->Load('filename.prc');
 print "Title: ",$mobi->{title},"\n";
 print "Author: ",$mobi->{header}{exth}{author},"\n";
 print "Language: ",$mobi->{header}{mobi}{language},"\n";

 my $mobigen = find_mobigen();
 system_mobigen('myfile.opf');

=head1 DEPENDENCIES

=over

=item * C<Bit::Vector>

=item * C<Compress::Zlib>

=item * C<HTML::Tree>

=item * C<Image::Size>

=item * C<List::MoreUtils>

=item * C<P5-Palm>

=item * C<String::CRC32>

=back

=cut


use Bit::Vector;
use Carp;
use Compress::Zlib;
use EBook::Tools qw(:all);
use EBook::Tools::PalmDoc qw(parse_palmdoc_header uncompress_palmdoc);
use Encode;
use Fcntl qw(SEEK_CUR SEEK_SET);
use File::Basename qw(dirname fileparse);
use File::Path;     # Exports 'mkpath' and 'rmtree'
use HTML::TreeBuilder;
use Image::Size;
use List::Util qw(min);
use List::MoreUtils qw(uniq);
use Palm::PDB;
use Palm::Raw();
use String::CRC32();


our %exthtypes = (
    1 => 'drm_server_id',
    2 => 'drm_commerce_id',
    3 => 'drm_ebookbase_book_id',
    100 => 'author',
    101 => 'publisher',
    102 => 'imprint',
    103 => 'description',
    104 => 'isbn',
    105 => 'subject',
    106 => 'publicationdate',
    107 => 'review',
    108 => 'contributor',
    109 => 'rights',
    110 => 'subjectcode',
    111 => 'type',
    112 => 'source',
    113 => 'asin',
    114 => 'versionnumber',
    115 => 'sample',
    116 => 'startreading',
    117 => 'adult',
    118 => 'retailprice',
    119 => 'currency',
    120 => '120',
    200 => '200',
    201 => 'coveroffset',
    202 => 'thumboffset',
    203 => 'hasfakecover',
    204 => '204',
    205 => '205',
    206 => '206',
    207 => '207',
    208 => '208',
    209 => '209',
    210 => '210',
    300 => '300',
    401 => 'clippinglimit',
    402 => 'publisherlimit',
    403 => '403',
    501 => 'cdetype',
    502 => 'lastupdatetime',
    503 => 'updatedtitle',
    );

# A subset of %exthtypes where the value is an integer, not a string
our %exth_is_int = (
    114 => 'versionnumber',
    115 => 'sample',
    201 => 'coveroffset',
    202 => 'thumboffset',
    203 => 'hasfakecover',
    204 => '204',
    205 => '205',
    206 => '206',
    207 => '207',
    300 => '300',
    401 => 'clippinglimit',
    403 => '403',
    );

# A subset of %exthtypes where the value could conceivably show up
# several times
our %exth_repeats = (
    101 => 'publisher',
    104 => 'isbn',
    105 => 'subject',
    108 => 'contributor',
    110 => 'subjectcode',
    );


our %mobilangcode;
$mobilangcode{0}{0}   = '';
$mobilangcode{54}{0}  = 'af'; # Afrikaans
$mobilangcode{28}{0}  = 'sq'; # Albanian
$mobilangcode{1}{0}   = 'ar'; # Arabic
$mobilangcode{1}{20}  = 'ar-dz'; # Arabic (Algeria)
$mobilangcode{1}{60}  = 'ar-bh'; # Arabic (Bahrain)
$mobilangcode{1}{12}  = 'ar-eg'; # Arabic (Egypt)
#$mobilangcode{1}{??} = 'ar-iq'; # Arabic (Iraq) -- Mobipocket broken
$mobilangcode{1}{44}  = 'ar-jo'; # Arabic (Jordan)
$mobilangcode{1}{52}  = 'ar-kw'; # Arabic (Kuwait)
$mobilangcode{1}{48}  = 'ar-lb'; # Arabic (Lebanon)
#$mobilangcode{1}{??} = 'ar-ly'; # Arabic (Libya) -- Mobipocket broken
$mobilangcode{1}{24}  = 'ar-ma'; # Arabic (Morocco)
$mobilangcode{1}{32}  = 'ar-om'; # Arabic (Oman)
$mobilangcode{1}{64}  = 'ar-qa'; # Arabic (Qatar)
$mobilangcode{1}{4}   = 'ar-sa'; # Arabic (Saudi Arabia)
$mobilangcode{1}{40}  = 'ar-sy'; # Arabic (Syria)
$mobilangcode{1}{28}  = 'ar-tn'; # Arabic (Tunisia)
$mobilangcode{1}{56}  = 'ar-ae'; # Arabic (United Arab Emirates)
$mobilangcode{1}{36}  = 'ar-ye'; # Arabic (Yemen)
$mobilangcode{43}{0}  = 'hy'; # Armenian
$mobilangcode{77}{0}  = 'as'; # Assamese
$mobilangcode{44}{0}  = 'az'; # "Azeri (IANA: Azerbaijani)
#$mobilangcode{44}{??} = 'az-cyrl'; # "Azeri (Cyrillic)" -- Mobipocket broken
#$mobilangcode{44}{??} = 'az-latn'; # "Azeri (Latin)" -- Mobipocket broken
$mobilangcode{45}{0}  = 'eu'; # Basque
$mobilangcode{35}{0}  = 'be'; # Belarusian
$mobilangcode{69}{0}  = 'bn'; # Bengali
$mobilangcode{2}{0}   = 'bg'; # Bulgarian
$mobilangcode{3}{0}   = 'ca'; # Catalan
$mobilangcode{4}{0}   = 'zh'; # Chinese
$mobilangcode{4}{12}  = 'zh-hk'; # Chinese (Hong Kong)
$mobilangcode{4}{8}   = 'zh-cn'; # Chinese (PRC)
$mobilangcode{4}{16}  = 'zh-sg'; # Chinese (Singapore)
$mobilangcode{4}{4}   = 'zh-tw'; # Chinese (Taiwan)
$mobilangcode{26}{0}  = 'hr'; # Croatian
$mobilangcode{5}{0}   = 'cs'; # Czech
$mobilangcode{6}{0}   = 'da'; # Danish
$mobilangcode{19}{0}  = 'nl'; # Dutch / Flemish
$mobilangcode{19}{8}  = 'nl-be'; # Dutch (Belgium)
$mobilangcode{9}{0}   = 'en'; # English
$mobilangcode{9}{12}  = 'en-au'; # English (Australia)
$mobilangcode{9}{40}  = 'en-bz'; # English (Belize)
$mobilangcode{9}{16}  = 'en-ca'; # English (Canada)
$mobilangcode{9}{24}  = 'en-ie'; # English (Ireland)
$mobilangcode{9}{32}  = 'en-jm'; # English (Jamaica)
$mobilangcode{9}{20}  = 'en-nz'; # English (New Zealand)
$mobilangcode{9}{52}  = 'en-ph'; # English (Philippines)
$mobilangcode{9}{28}  = 'en-za'; # English (South Africa)
$mobilangcode{9}{44}  = 'en-tt'; # English (Trinidad)
$mobilangcode{9}{8}   = 'en-gb'; # English (United Kingdom)
$mobilangcode{9}{4}   = 'en-us'; # English (United States)
$mobilangcode{9}{48}  = 'en-zw'; # English (Zimbabwe)
$mobilangcode{37}{0}  = 'et'; # Estonian
$mobilangcode{56}{0}  = 'fo'; # Faroese
$mobilangcode{41}{0}  = 'fa'; # Farsi / Persian
$mobilangcode{11}{0}  = 'fi'; # Finnish
$mobilangcode{12}{0}  = 'fr'; # French
$mobilangcode{12}{4}  = 'fr'; # French (Mobipocket bug?)
$mobilangcode{12}{8}  = 'fr-be'; # French (Belgium)
$mobilangcode{12}{12} = 'fr-ca'; # French (Canada)
$mobilangcode{12}{20} = 'fr-lu'; # French (Luxembourg)
$mobilangcode{12}{24} = 'fr-mc'; # French (Monaco)
$mobilangcode{12}{16} = 'fr-ch'; # French (Switzerland)
$mobilangcode{55}{0}  = 'ka'; # Georgian
$mobilangcode{7}{0}   = 'de'; # German
$mobilangcode{7}{12}  = 'de-at'; # German (Austria)
$mobilangcode{7}{20}  = 'de-li'; # German (Liechtenstein)
$mobilangcode{7}{16}  = 'de-lu'; # German (Luxembourg)
$mobilangcode{7}{8}   = 'de-ch'; # German (Switzerland)
$mobilangcode{8}{0}   = 'el'; # Greek, Modern (1453-)
$mobilangcode{71}{0}  = 'gu'; # Gujarati
$mobilangcode{13}{0}  = 'he'; # Hebrew (also code 'iw'?)
$mobilangcode{57}{0}  = 'hi'; # Hindi
$mobilangcode{14}{0}  = 'hu'; # Hungarian
$mobilangcode{15}{0}  = 'is'; # Icelandic
$mobilangcode{33}{0}  = 'id'; # Indonesian
$mobilangcode{16}{0}  = 'it'; # Italian
$mobilangcode{16}{4}  = 'it'; # Italian (Mobipocket bug?)
$mobilangcode{16}{8}  = 'it-ch'; # Italian (Switzerland)
$mobilangcode{17}{0}  = 'ja'; # Japanese
$mobilangcode{75}{0}  = 'kn'; # Kannada
$mobilangcode{63}{0}  = 'kk'; # Kazakh
$mobilangcode{87}{0}  = 'x-kok'; # Konkani (real language code is 'kok'?)
$mobilangcode{18}{0}  = 'ko'; # Korean
$mobilangcode{38}{0}  = 'lv'; # Latvian
$mobilangcode{39}{0}  = 'lt'; # Lithuanian
$mobilangcode{47}{0}  = 'mk'; # Macedonian
$mobilangcode{62}{0}  = 'ms'; # Malay
#$mobilangcode{62}{??}  = 'ms-bn'; # Malay (Brunei Darussalam) -- not supported
#$mobilangcode{62}{??}  = 'ms-my'; # Malay (Malaysia) -- Mobipocket bug
$mobilangcode{76}{0}  = 'ml'; # Malayalam
$mobilangcode{58}{0}  = 'mt'; # Maltese
$mobilangcode{78}{0}  = 'mr'; # Marathi
$mobilangcode{97}{0}  = 'ne'; # Nepali
$mobilangcode{20}{0}  = 'no'; # Norwegian
#$mobilangcode{??}{??} = 'nb'; # Norwegian Bokml (Mobipocket not supported)
#$mobilangcode{??}{??} = 'nn'; # Norwegian Nynorsk (Mobipocket not supported)
$mobilangcode{72}{0}  = 'or'; # Oriya
$mobilangcode{21}{0}  = 'pl'; # Polish
$mobilangcode{22}{0}  = 'pt'; # Portuguese
$mobilangcode{22}{8}  = 'pt'; # Portuguese (Mobipocket bug?)
$mobilangcode{22}{4}  = 'pt-br'; # Portuguese (Brazil)
$mobilangcode{70}{0}  = 'pa'; # Punjabi
$mobilangcode{23}{0}  = 'rm'; # "Rhaeto-Romanic" (IANA: Romansh)
$mobilangcode{24}{0}  = 'ro'; # Romanian
#$mobilangcode{24}{??}  = 'ro-mo'; # Romanian (Moldova) (Mobipocket output is 0)
$mobilangcode{25}{0}  = 'ru'; # Russian
#$mobilangcode{25}{??}  = 'ru-mo'; # Russian (Moldova) (Mobipocket output is 0)
$mobilangcode{59}{0}  = 'sz'; # "Sami (Lappish)" (not an IANA language code)
                              # IANA code for "Northern Sami" is 'se'
                              # 'SZ' is the IANA region code for Swaziland
$mobilangcode{79}{0}  = 'sa'; # Sanskrit
$mobilangcode{26}{12} = 'sr'; # Serbian -- Mobipocket Cyrillic/Latin distinction broken
#$mobilangcode{26}{12} = 'sr-cyrl'; # Serbian (Cyrillic) (Mobipocket bug)
#$mobilangcode{26}{12} = 'sr-latn'; # Serbian (Latin) (Mobipocket bug)
$mobilangcode{27}{0}  = 'sk'; # Slovak
$mobilangcode{36}{0}  = 'sl'; # Slovenian
$mobilangcode{46}{0}  = 'sb'; # "Sorbian" (not an IANA language code)
                              # 'SB' is IANA region code for 'Solomon Islands'
                              # Lower Sorbian = 'dsb'
                              # Upper Sorbian = 'hsb'
                              # Sorbian Languages = 'wen'
$mobilangcode{10}{0}  = 'es'; # Spanish
$mobilangcode{10}{4}  = 'es'; # Spanish (Mobipocket bug?)
$mobilangcode{10}{44} = 'es-ar'; # Spanish (Argentina)
$mobilangcode{10}{64} = 'es-bo'; # Spanish (Bolivia)
$mobilangcode{10}{52} = 'es-cl'; # Spanish (Chile)
$mobilangcode{10}{36} = 'es-co'; # Spanish (Colombia)
$mobilangcode{10}{20} = 'es-cr'; # Spanish (Costa Rica)
$mobilangcode{10}{28} = 'es-do'; # Spanish (Dominican Republic)
$mobilangcode{10}{48} = 'es-ec'; # Spanish (Ecuador)
$mobilangcode{10}{68} = 'es-sv'; # Spanish (El Salvador)
$mobilangcode{10}{16} = 'es-gt'; # Spanish (Guatemala)
$mobilangcode{10}{72} = 'es-hn'; # Spanish (Honduras)
$mobilangcode{10}{8}  = 'es-mx'; # Spanish (Mexico)
$mobilangcode{10}{76} = 'es-ni'; # Spanish (Nicaragua)
$mobilangcode{10}{24} = 'es-pa'; # Spanish (Panama)
$mobilangcode{10}{60} = 'es-py'; # Spanish (Paraguay)
$mobilangcode{10}{40} = 'es-pe'; # Spanish (Peru)
$mobilangcode{10}{80} = 'es-pr'; # Spanish (Puerto Rico)
$mobilangcode{10}{56} = 'es-uy'; # Spanish (Uruguay)
$mobilangcode{10}{32} = 'es-ve'; # Spanish (Venezuela)
$mobilangcode{48}{0}  = 'sx'; # "Sutu" (not an IANA language code)
                              # "Sutu" is another name for "Southern Sotho"?
                              # IANA code for "Southern Sotho" is 'st'
$mobilangcode{65}{0}  = 'sw'; # Swahili
$mobilangcode{29}{0}  = 'sv'; # Swedish
$mobilangcode{29}{8}  = 'sv-fi'; # Swedish (Finland)
$mobilangcode{73}{0}  = 'ta'; # Tamil
$mobilangcode{68}{0}  = 'tt'; # Tatar
$mobilangcode{74}{0}  = 'te'; # Telugu
$mobilangcode{30}{0}  = 'th'; # Thai
$mobilangcode{49}{0}  = 'ts'; # Tsonga
$mobilangcode{50}{0}  = 'tn'; # Tswana
$mobilangcode{31}{0}  = 'tr'; # Turkish
$mobilangcode{34}{0}  = 'uk'; # Ukrainian
$mobilangcode{32}{0}  = 'ur'; # Urdu
$mobilangcode{67}{0}  = 'uz'; # Uzbek
$mobilangcode{67}{8}  = 'uz'; # Uzbek (Mobipocket bug?)
#$mobilangcode{67}{??} = 'uz-cyrl'; # Uzbek (Cyrillic)
#$mobilangcode{67}{??} = 'uz-latn'; # Uzbek (Latin)
$mobilangcode{42}{0}  = 'vi'; # Vietnamese
$mobilangcode{52}{0}  = 'xh'; # Xhosa
$mobilangcode{53}{0}  = 'zu'; # Zulu

our $mobigen_cmd = '';
our $mobidedrm_cmd = '';

my %pdbencoding = (
    '1252' => 'Windows-1252',
    '65001' => 'UTF-8',
    );


#################################
########## CONSTRUCTOR ##########
#################################

=head1 CONSTRUCTOR

=head2 C<new()>

Instantiates a new Ebook::Tools::Mobipocket object.

=cut

sub new   ## no critic (Always unpack @_ first)
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{'creator'} = 'BOOK';
    $self->{'type'} = 'MOBI';

    $self->{attributes}{resource} = 0;

    $self->{appinfo} = undef;
    $self->{sort} = undef;
    $self->{records} = [];

    $self->{header} = {};
    $self->{encoding} = 1252;
    $self->{text} = '';
    $self->{imagedata} = {};
    $self->{unknowndata} = {};
    $self->{recindexlinks} = {};
    $self->{recindex} = 1; # Image index used to keep track of which image
                           # record maps to which link.  This has to start
                           # at 1 to match what mobipocket does with the
                           # recindex attributes in the text

    $self->{title}     = '';
    $self->{author}    = '';
    $self->{rights}    = '';
    $self->{publisher} = '';
    $self->{isbn}      = '';

    return $self;
}


######################################
########## ACCESSOR METHODS ##########
######################################

=head1 ACCESSOR METHODS

=head2 C<drm()>

Returns 1 if the C<drmoffset> header value is neither C<0> nor
C<0xffffffff>.  Returns undef if C<drmoffset> is undefined. Returns 0
otherwise.

=cut

sub drm :method
{
    my $self = shift;
    my $drmoffset = $self->{header}{mobi}{drmoffset};
    return unless(defined $drmoffset);
    return 1 if( $drmoffset && ($drmoffset != hex("0xffffffff")) );
    return 0;
}


=head2 C<text()>

Returns the text of the file

=cut

sub text :method
{
    my $self = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my $length = length($self->{text});

    debug(2,"WARNING: actual text length (",$length,
         ") does not match specified text length (",
         $self->{header}{palm}{textlength},")")
        unless($length == $self->{header}{palm}{textlength});

    return $self->{text};
}


=head2 C<write_images()>

Writes each image record to the disk.

Returns the number of images written.

=cut

sub write_images :method
{
    my $self = shift;
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    my %imagedata = %{$self->{imagedata}};

    foreach my $image (sort keys %imagedata)
    {
        debug(1,"Writing image '",$image,"' [",
              length(${$imagedata{$image}})," bytes]");
        open(my $fh,">:raw",$image)
            or croak("Unable to open '",$image,"' to write image\n");
        print {*$fh} ${$imagedata{$image}};
        close($fh)
            or croak("Unable to close image file '",$image,"'\n");
    }
    return scalar(keys %imagedata);
}


=head2 C<write_text($filename)>

Writes the book text to disk with the given filename.  This filename
must match the filename given to L</fix_html()> for the internal links
to be consistent.

Croaks if C<$filename> is not specified.

Returns 1 on success, or undef if there was no text to write.

=cut

sub write_text :method
{
    my $self = shift;
    my $filename = shift;
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    croak($subname,"(): no filename specified.\n")
        unless($filename);
    return unless($$self{text});

    debug(1,"DEBUG: writing text to '",$filename,
          "', encoding ",$pdbencoding{$self->{encoding}});

    open(my $fh,">",$filename)
        or croak($subname,"(): unable to open '",$filename,"' for writing!\n");
    binmode($fh);
    print {*$fh} $self->{text};
    close($fh)
        or croak($subname,"(): unable to close '",$filename,"'!\n");

    croak($subname,"(): failed to generate any text")
        if(-z $filename);

    return 1;
}


=head2 C<write_unknown_records()>

Writes each unidentified record to disk with a filename in the format of
'raw-record-####', where #### is the record number (not the record ID).

Returns the number of records written.

=cut

sub write_unknown_records :method
{
    my $self = shift;
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    my %unknowndata = %{$self->{unknowndata}};

    foreach my $rec (sort { $a <=> $b } keys %unknowndata)
    {
        my $recstring = sprintf("%04d",$rec);
        debug(1,"Dumping raw record ",$recstring);
        my $rawname = "raw-record-" . $recstring;
        open(my $fh,">:raw",$rawname)
            or croak("Unable to open '",$rawname,"' to write raw record\n");
        print {*$fh} $$self{unknowndata}{$rec};
        close($fh)
            or croak("Unable to close raw record file '",$rawname,"'\n");
    }
    return scalar(keys %unknowndata);
}


######################################
########## MODIFIER METHODS ##########
######################################

=head1 MODIFIER METHODS

These methods have two naming/capitalization schemes -- methods
directly related to the subclassing of Palm::PDB use its MethodName
capitalization style.  Any other methods are
lowercase_with_underscores for consistency with the rest of
EBook::Tools.


=head2 C<Load($filename)>

Sets C<< $self->{filename} >> and then loads and parses the file specified
by C<$filename>, calling L</ParseRecord(%record)> on every record
found.

If DictionaryHuffman compression is detected, text records will be
left untouched during the ParseRecord pass, and
L</uncompress_dictionaryhuffman_records()> will be called after the
initial parsing pass is complete.

=cut

sub Load :method
{
    my $self = shift;
    my $filename = shift;
    my $retval;

    $self->{filename} = $filename;
    $retval = $self->SUPER::Load($filename);
    if($self->{header}{palm}{compression} == 17480)
    {
        $self->uncompress_dictionaryhuffman_records();
    }
    return $retval;
}


=head2 C<ParseRecord(%record)>

Parses PDB records, updating the object attributes.  This method is
called automatically on every database record during C<Load()>.

=cut

sub ParseRecord :method   ## no critic (Always unpack @_ first)
{
    ## The long if-elsif chain is the best logic for record number handling
    ## no critic (Cascading if-elsif chain)
    my $self = shift;
    my %record = @_;
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    my $currentrecord;
    if(!defined $$self{records})
    {
        $currentrecord = 0;
    }
    else
    {
        $currentrecord = scalar @{$$self{records}};
    }

    my $data = $record{data};
    my $compression = $$self{header}{palm}{compression};
    my $recordtext;

    # If a DATP record exists, it may have the same record number
    # as 'lastimagerecord'?
    my @afterimage;
    push(@afterimage,$self->{header}{mobi}{lastimagerecord}+1)
        if($self->{header}{mobi}{lastimagerecord});
    push(@afterimage,$self->{header}{mobi}{datprecord})
        if($self->{header}{mobi}{datprecord});

    # Several things can come after INDX records, but some of them can
    # have record offsets of 0
    my @afterindx;
    push(@afterindx,$self->{header}{mobi}{huffrecord})
        if($self->{header}{mobi}{huffrecord});
    push(@afterindx,$self->{header}{mobi}{firstimagerecord})
        if($self->{header}{mobi}{firstimagerecord});
    push(@afterindx,$self->{header}{mobi}{datprecord})
        if($self->{header}{mobi}{datprecord});

    if($currentrecord == 0)
    {
        $self->ParseRecord0($data);
    }
    elsif($currentrecord < $$self{header}{mobi}{indxrecord}
          && $currentrecord < $$self{header}{mobi}{firstimagerecord})
    {
        # Text records come immediately after the header record, but
        # the distinction between indxrecord and firstimagerecord is
        # not clear.  Sometimes images show up at one, and sometimes
        # the other.

        if($self->drm)
        {
            debug(3,"DEBUG: record ",$currentrecord,
                  " is DRM-protected text, skipping");
        }
        elsif($compression == 17480)
        {
            # HUFF/CDIC-compressed text is skipped on the first pass,
            # since uncompressing it requires data from records that
            # aren't parsed until later.
            debug(3,"DEBUG: record ",$currentrecord,
                  " is HUFF/CDIC-compressed, handled in second pass");
        }
        else
        {
            debug(3,"DEBUG: record ",$currentrecord,
                  " is uncompressed or PalmDoc-compressed text");
            $self->ParseRecordText(\$data);
        }
    }
    elsif($currentrecord >= $$self{header}{mobi}{indxrecord}
          && $currentrecord < min(@afterindx))
    {
        # INDX records are not understood.
        debug(1,"DEBUG: record ",$currentrecord," is INDX record [",
              length($data)," bytes starting with '",
              substr($record{data},0,4),"']");
        $$self{unknowndata}{$currentrecord} = $data;
    }
    elsif($currentrecord >= $$self{header}{mobi}{huffrecord}
          && $currentrecord <
          ($$self{header}{mobi}{huffrecord}
           + $$self{header}{mobi}{huffreccnt}) )
    {
        my $recordtype = substr($data,0,4);
        if($recordtype eq 'HUFF')
        {
            $self->ParseRecordHUFF(\$data);
        }
        elsif($recordtype eq 'CDIC')
        {
            $self->ParseRecordCDIC(\$data);
        }
        else
        {
            debug(1,"WARNING: record ",$currentrecord,
                  " expected HUFF/CDIC record, but found ",
                  length($data)," bytes starting with '",
                  $recordtype,"'");
        }
    }
    elsif($currentrecord >= $$self{header}{mobi}{firstimagerecord}
          && $currentrecord < min(@afterimage) )
    {
        my ($imagex,undef,$imagetype) = imgsize(\$data);
        if(defined($imagex) && $imagetype)
        {
            $self->ParseRecordImage(\$data);
        }
        else
        {
            debug(1,"DEBUG: record ",$currentrecord,
                  " is not imagedata, but ",length($data),
                  " bytes starting with '", substr($data,0,4),"'");
            $$self{unknowndata}{$currentrecord} = $data;
        }
    }
    elsif($currentrecord >= $$self{header}{mobi}{datprecord}
          && $currentrecord <
          $$self{header}{mobi}{datprecord} + $$self{header}{mobi}{datpreccnt})
    {
        # DATP records not understood
        my $recordid = substr($data,0,4);
        if($recordid eq 'DATP')
        {
            debug(2,"DEBUG: record ",$currentrecord," is DATP record");
        }
        else
        {
            debug(1,"DEBUG: record ",$currentrecord," isn't DATP record?");
        }
        $$self{unknowndata}{$currentrecord} = $data;
    }
    elsif($currentrecord == $$self{header}{mobi}{flisrecord})
    {
        my $recordid = substr($data,0,4);
        if($recordid eq 'FLIS')
        {
            debug(2,"DEBUG: record ",$currentrecord," is FLIS record");
        }
        else
        {
            debug(1,"DEBUG: record ",$currentrecord," isn't FLIS record?");
        }
        $$self{unknowndata}{$currentrecord} = $data;
    }
    elsif($currentrecord == $$self{header}{mobi}{fcisrecord})
    {
        my $recordid = substr($data,0,4);
        if($recordid eq 'FCIS')
        {
            debug(2,"DEBUG: record ",$currentrecord," is FCIS record");
        }
        else
        {
            debug(1,"DEBUG: record ",$currentrecord," isn't FCIS record?");
        }
        $$self{unknowndata}{$currentrecord} = $data;
    }
    else
    {
        $recordtext = uncompress($record{data});
        $recordtext = uncompress_palmdoc($record{data}) unless($recordtext);
        if($recordtext)
        {
            debug(1,"DEBUG: record ",$currentrecord," has extra text:");
            debug(1,"       '",$recordtext,"'");
            $$self{unknowndata}{$currentrecord} = $recordtext;
        }
        else
        {
            debug(1,"DEBUG: record ",$currentrecord," is unknown (",
                  length($data)," bytes starting with '",
                  substr($record{data},0,4),"')");
            $$self{unknowndata}{$currentrecord} = $data;
        }
    }

    return \%record;
}


=head2 C<ParseRecord0($data)>

Parses the header record and places the parsed values into the hashref
C<< $self->{header}{palm} >>, the hashref C<< $self->{header}{mobi} >>,
and C<< $self->{header}{exth} >> by calling L</parse_palmdoc_header()>,
L</parse_mobi_header()>, and L</parse_mobi_exth()> respectively.

=cut

sub ParseRecord0 :method
{
    my $self = shift;
    my $data = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my $headerdata;  # used for holding temporary data segments
    my $headersize;  # size of variable-length header data
    my %headermobi;

    my @list;

    # First 16 bytes are a slightly modified palmdoc header
    # See http://wiki.mobileread.com/wiki/MOBI
    $headerdata = substr($data,0,16);
    $$self{header}{palm} = parse_palmdoc_header($headerdata);

    # Find out how long the Mobipocket header actually is
    $headerdata = substr($data,16,8);
    @list = unpack("a4N",$headerdata);
    croak($subname,
          "(): Unrecognized Mobipocket header ID '",$list[0],
          "' (expected 'MOBI')")
        unless($list[0] eq 'MOBI');
    $headersize = $list[1];
    croak($subname,"(): unable to determine Mobipocket header size")
        unless($list[1]);

    # Unpack the full Mobipocket header
    $headerdata = substr($data,16,$headersize);
    %headermobi = %{parse_mobi_header($headerdata)};
    $$self{header}{mobi} = \%headermobi;
    $$self{encoding} = $headermobi{encoding};

    if($headermobi{exthflags} & 0x040) # If bit 6 is set, EXTH exists
    {
        debug(2,"DEBUG: Unpacking EXTH data at record 0 offset ",
              $headersize+16);
        $headerdata = substr($data,$headersize+16);
        $$self{header}{exth} = parse_mobi_exth($headerdata);
    }

    if($headermobi{titleoffset} && $headermobi{titlelength})
    {
        # This is a better guess at the title than the one
        # derived from $pdb->name
        $$self{title} =
            substr($data,$headermobi{titleoffset},$headermobi{titlelength});
        debug(1,"DEBUG: Extracted title '",$$self{title},"'");
    }

    return 1;
}


=head2 C<ParseRecordCDIC(\$data)>

Parses a CDIC record.  Takes as a sole argument a reference to the
data of the record.

=head3 Record format

=over

=item * Offset 0: Record identifier

4 bytes, always 'CDIC'

=item * Offset 4: Header length

4 bytes, big-endian long int, always = 16

=item * Offset 8: Index count

4 bytes, big-endian long int, marks the number of big-endian short
ints immediately following the header used as index points into the
dictionary data

=item * Offset 12: Codelength

4 bytes, big-endian long int, number of code bits

=item * Offset 16: Indexes

A number of big-endian short ints used as index points into the
dictionary data

=item * Offset ??: Dictionary data

Dictionary result strings immediately following the indexes

=back

=cut

sub ParseRecordCDIC
{
    my $self = shift;
    my $dataref = shift;
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    my $currentrecord = scalar @{$self->{records}};
    my %cdic;
    my @cdics;
    my $size = length($$dataref);
    my @list = unpack('a4NNN',substr($$dataref,0,16));
    my $recordid     = $list[0];
    my $headerlength = $list[1];
    my $indexcount   = $list[2];
    my $codelength   = $list[3];

    if($recordid ne 'CDIC')
    {
        debug(1,"DEBUG: record ",$currentrecord,
              " does not have CDIC header (found '",$recordid,"')");
        $$self{unknowndata}{$currentrecord} = $$dataref;
        $self->{huff} = {};
    }
    elsif($headerlength != 16)
    {
        debug(1,"DEBUG: record ",$currentrecord,
              " is CDIC record with unexpected header length (",
              $headerlength,", expected 16");
        $$self{unknowndata}{$currentrecord} = $$dataref;
        $self->{huff} = {};
    }
    elsif(!$codelength)
    {
        debug(1,"DEBUG: record ",$currentrecord,
              " is CDIC record with zero codelength!");
        $$self{unknowndata}{$currentrecord} = $$dataref;
        $self->{huff} = {};
    }
    elsif($headerlength + (1 << $codelength) >= $size)
    {
        debug(1,"DEBUG: record ",$currentrecord,
              " is CDIC record too short for its codelength (",
              $size," bytes, codelength=",$codelength,")");
        $$self{unknowndata}{$currentrecord} = $$dataref;
        $self->{huff} = {};
    }
    elsif($self->{huff}->{codelength}
          && $self->{huff}->{codelength} != $codelength)
    {
        debug(1,"DEBUG: record ",$currentrecord,
              " is CDIC record with a new codelength (",
              $codelength," bits, previous was ",
              $self->{huff}->{codelength});
        $$self{unknowndata}{$currentrecord} = $$dataref;
        $self->{huff} = {};
    }
    else
    {
        my @indexes = unpack("n$indexcount",substr($$dataref,16,$indexcount*2));
        $cdic{id} = $recordid;
        $cdic{indexes} = \@indexes;
        $cdic{data} = $$dataref;
        $cdic{codelength} = $codelength;
        $self->{huff}->{codelength} = $codelength;

        @cdics = @{$self->{cdics}} if($self->{cdics});

        push(@cdics,\%cdic);
        $self->{cdics} = \@cdics;
        debug(1,"DEBUG: record ",$currentrecord," is CDIC record ",
              $#cdics, " [",length($$dataref)," bytes,",
              " indexcount=",$indexcount,
              " codelength=",$codelength,"]");
    }
    return 1;
}


=head2 C<ParseRecordHUFF(\$data)>

Parses a HUFF record.  Takes as a sole argument a reference to the
data of the record.

=head3 Record format

=over

=item * Offset 0: Record identifier

4 bytes, always 'HUFF'

=item * Offset 4: Header length

4 bytes, big-endian long int, always = 24

=item * Offset 8: Cache table (big-endian) offset

4 bytes, big-endian long int, always = 24

=item * Offset 12: Base table (big-endian) offset

4 bytes, big-endian long int, always = 1048

=item * Offset 16: Cache table (little-endian) offset

4 bytes, big-endian long int, always = 1304

=item * Offset 20: Base table (little-endian) offset

4 bytes, big-endian long int, always = 2328

=item * Offset 24: Cache table (big-endian)

1024 bytes, 256 big-endian long ints

This is a look up table for the length and decoding of short
codewords.  If the codeword represented by the 8 bits is unique, then
bit 7 (0x80) will be set, and the low 5 bits are the length in bits of
the code.  The high three bytes partially represent the final symbol.

If bit 7 is clear, then the code is looked up in the base table

=item * Offset 1048: Base table (big-endian)

256 bytes, 64 big-endian long ints

This is where the codeword is looked up if it isn't found in the cache
table.

=item * Offset 1304: Cache table (little-endian)

1024 bytes, 256 little-endian long ints.

This contains exactly the same data as in the cache table at offset
24, except that all of the values are stored in little-endian format
instead of big-endian.

Presumably this is for a speed advantage on slow little-endian
processors.  This module uses only the big-endian tables.

=item * Offset 2328: Base table (little-endian)

256 bytes, 64 little-endian long ints

This contains exactly the same data as in the base table at offset
1048, except that all of the values are stored in little-endian format
instead of big-endian.

Presumably this is for a speed advantage on slow little-endian
processors.  This module uses only the big-endian tables.

=back

=cut


sub ParseRecordHUFF
{
    my $self = shift;
    my $dataref = shift;
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    my $currentrecord = scalar @{$self->{records}};
    my $size = length($$dataref);
    my %huff;
    my (@cache,@lecache);
    my (@basetable,@lebasetable);
    my $headerlength;
    my $codelength;

    my @list = unpack('a4NNNNN',substr($$dataref,0,24));
    $huff{id}            = $list[0];
    $huff{headerlength}  = $list[1];
    $huff{cacheoffset}   = $list[2];
    $huff{baseoffset}    = $list[3];
    $huff{lecacheoffset} = $list[4];
    $huff{lebaseoffset}  = $list[5];

    $huff{data}  = $$dataref;
    $huff{bitpos} = 0;

    if($huff{id} ne 'HUFF')
    {
        debug(1,"DEBUG: record ",$currentrecord,
              " does not have HUFF header (found '",$huff{id},"')");
        $$self{unknowndata}{$currentrecord} = $$dataref;
        return;
    }
    if($size < 2584)
    {
        debug(1,"WARNING: record ",$currentrecord,
              " is HUFF record with unexpected size (",
              $size," bytes, expected at least 2584");
        $$self{unknowndata}{$currentrecord} = $$dataref;
        return;
    }
    if($size < $huff{lebaseoffset} + 256)
    {
        debug(1,"WARNING: recoord ",$currentrecord,
              "is HUFF record too short to read all data (",
              $size," bytes, lebaseoffset=",$huff{lebaseoffset});
        $$self{unknowndata}{$currentrecord} = $$dataref;
        return;
    }

    @cache = unpack('N[256]',
                    substr($$dataref,$huff{cacheoffset},256*4));
    $huff{cache} = \@cache;

    @basetable = unpack('N[64]',
                        substr($$dataref,$huff{baseoffset},64*4));
    $huff{basetable} = \@basetable;

    # Little-endian versions aren't used, but are checked against
    # big-endian for corruption
    @lecache = unpack('V[256]',
                      substr($$dataref,$huff{lecacheoffset},256*4));
    @lebasetable = unpack('V[64]',
                          substr($$dataref,$huff{lebaseoffset},64*4));

# Testing to see if the big-endian and little-endian tables are
# identical is really only efficient with the smart-match operator,
# which requires Perl 5.10 or later.
#
# Use of 5.10 features is being delayed until 5.10 is standard on
# MacOSX and Debian.
#
#    unless(@cache ~~ @lecache)
#    {
#        debug(1,"WARNING: big-endian and little-endian HUFF cache",
#              " tables are different in record ",$currentrecord,"!");
#    }
#    unless(@basetable ~~ @lebasetable)
#    {
#        debug(1,"WARNING: big-endian and little-endian HUFF base",
#              " tables are different in record ",$currentrecord,"!");
#    }


    if($huff{headerlength} != 24)
    {
        debug(1,"DEBUG: record ",$currentrecord,
              " is HUFF record with unexpected header length (",
              $huff{headerlength},", expected 24");
        $$self{unknowndata}{$currentrecord} = $$dataref;
    }
    elsif($huff{cacheoffset} != 24)
    {
        deubg(1,"DEBUG: record ",$currentrecord,
              " is HUFF record with unexpected cache offset (",
              $huff{cacheoffset}," expected 24");
        $$self{unknowndata}{$currentrecord} = $$dataref;
    }
    elsif($huff{baseoffset} != 1048)
    {
        debug(1,"DEBUG: record ",$currentrecord,
              " is HUFF record with unexpected base table offset (",
              $huff{baseoffset}," expected 1048)");
        $$self{unknowndata}{$currentrecord} = $$dataref;
    }
    else
    {
        $self->{huff} = \%huff;
        debug(2,"DEBUG: record ",$currentrecord," is HUFF record [",
              length($$dataref)," bytes,",
              " cacheoffset=",$huff{cacheoffset},
              " baseoffset=",$huff{baseoffset},
              " lecacheoffset=",$huff{lecacheoffset},
              " lebaseoffset=",$huff{lebaseoffset},"]");
    }
    return 1;
}


=head2 C<ParseRecordImage(\$dataref)>

Parses image records, updating object attributes, most notably adding
the image data to the hash C<< $self->{imagedata} >>, adding the image
filename to C<< $self->{recindexlinks} >>, and incrementing
C<< $self->{recindex} >>.

Takes as an argument a reference to the record data.  Croaks if it
isn't provided, or isn't a reference.

This is called automatically by L</ParseRecord()> and
L</ParseResource()> as needed.

=cut

sub ParseRecordImage :method
{
    my $self = shift;
    my $dataref = shift;
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    croak($subname,"(): no image data provided\n") unless($dataref);
    croak($subname,"(): image data is not a reference\n") unless(ref $dataref);

    $$self{recindex} = 1 unless(defined $$self{recindex});

    my $currentrecord = scalar @{$$self{records}};
    my ($imagex,$imagey,$imagetype) = imgsize($dataref);
    my $idxstring = sprintf("%04d",$$self{recindex});
    my $imagename = $$self{name} . '-' . $idxstring . '.' . lc($imagetype);

    debug(1,"DEBUG: record ",$currentrecord," is image '",$imagename,
          "' (",$imagex," x ",$imagey,")");
    $$self{imagedata}{$imagename} = $dataref;
    $$self{recindexlinks}{$$self{recindex}} = $imagename;
    $$self{recindex}++;
    return 1;
}


=head2 C<ParseRecordText(\$dataref)>

Parses text records, updating object attributes, most notably
appending text to C<< $self->{text} >>.  Takes as an argument a reference
to the record data.

This is called automatically by L</ParseRecord()> and
L</ParseResource()> as needed.

=cut

sub ParseRecordText :method
{
    my $self = shift;
    my $dataref = shift;
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    my $currentrecord = scalar @{$$self{records}};
    my $compression = $$self{header}{palm}{compression};
    my $recordtext;
    my $extradatasize;

    debug(3,"DEBUG: extradataflags = ",$$self{header}{mobi}{extradataflags});
    if( $$self{header}{mobi}{extradataflags} )
    {
        $extradatasize = record_extradata_size(
            dataref => $dataref,
            extradataflags => $$self{header}{mobi}{extradataflags}
           );
    }

    if($compression == 1)        # No compression
    {
        debug(3,"DEBUG: No compression on record ",$currentrecord);
        if($extradatasize)
        {
            $recordtext = substr($$dataref,0,length($$dataref)-$extradatasize);
            debug(3,"DEBUG: skipping ",$extradatasize," bytes at end of record ",
                  $currentrecord);
        }
        else
        {
            $recordtext = $$dataref;
        }
    }
    elsif($compression == 2)     # PalmDoc compression
    {
        my %args;
        if($extradatasize)
        {
            $args{trailing} = $extradatasize;
            debug(3,"DEBUG: skipping ",$extradatasize," bytes at end of record ",
                  $currentrecord);
        }
        $recordtext = uncompress_palmdoc($$dataref,%args);
    }
    elsif($compression == 17480) # 'Dictionary Huffman' compression
    {
        # This has to be handled in a separate pass, as decompression
        # requires data from records not yet parsed.
        debug(3,"DEBUG: record ",$currentrecord,
              " is HUFF/CDIC-compressed text, deferring decompression");
        return 1;
    }
    else
    {
        croak($subname,"(): unknown compression value (",
              $compression,")\n");
    }

    if($recordtext)
    {
        $self->{text} .= $recordtext;
        debug(3,"DEBUG: parsed text record ",$currentrecord);
    }
    else
    {
        debug(1,"DEBUG: record ",$currentrecord,
              " could not be parsed (",
              length($$dataref)," bytes starting with '",
              substr($$dataref,0,4),"')");
        $$self{unknowndata}{$currentrecord} = $$dataref;
    }
    return 1;
}


=head2 fix_html(%args)

Takes raw Mobipocket text and replaces the custom tags and file
position anchors

=head3 Arguments

=over

=item * C<filename>

The name of the output HTML file (used in generating hrefs).  The
procedure croaks if this is not supplied.

=item * C<nonewlines> (optional)

If this is set to true, the procedure will not attempt to insert
newlines for readability.  This will leave the output in a single
unreadable line, but has the advantage of reducing the processing
time, especially useful if tidy is going to be run on the output
anyway.

=back

=cut

sub fix_html :method   ## no critic (Always unpack @_ first)
{
    my $self = shift;
    my (%args) = @_;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");
    my %valid_args = (
        'filename' => 1,
        'nonewlines' => 1,
        );
    foreach my $arg (keys %args)
    {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }
    my $filename = $args{filename};
    my $encoding = $$self{encoding} || 1252;
    croak($subname,"(): no text found")
        unless($$self{text});
    croak($subname,"(): no filename supplied")
        unless($filename);

    my $tree;
    my @elements;
    my $head_element;
    my $element;
    my $recindex;
    my $link;

    # The very first thing that has to be done is map out all of the
    # filepos references and generate anchors at the referenced
    # positions.  This must be done first because any other
    # modifications to the text will invalidate those positions.
    $self->fix_html_filepos();

    # Convert or remove the Mobipocket-specific tags
    $self->{text} =~ s#<mbp:pagebreak [\s\n]*
                      #<br style="page-break-after: always" #gix;
    $self->{text} =~ s#</mbp:pagebreak>##gix;
    $self->{text} =~ s#</?mbp:nu>##gix;
    $self->{text} =~ s#</?mbp:section>##gix;
    $self->{text} =~ s#</?mbp:frameset##gix;
    $self->{text} =~ s#</?mbp:slave-frame##gix;


    # More complex alterations will require a HTML tree
    $tree = HTML::TreeBuilder->new();
    $tree->ignore_unknown(0);
    $tree->no_expand_entities(1);
    $tree->store_comments(1);

    # If the encoding is UTF-8, we have to note it specially before
    # the parse or the parser will break
    if($encoding == 65001) {
        $tree->utf8_mode(1);
    }
    $tree->parse($self->{text});
    $tree->eof();

    # Update contents of <head>
    $head_element = $tree->find('head');
    if(! $head_element) {
        $self->add_warning("No <head> element found in Mobipocket HTML!");
    }
    else {
        # Fix missing <title>
        $element = $head_element->find('title');
        if(! $element) {
            debug(1,"DEBUG: title element missing, creating as '",
                  $self->{title},"'");
            $head_element->push_content(['title',$self->{title}]);
        }
        else {
            if(! $element->as_trimmed_text) {
                debug(1,"DEBUG: title is empty, setting to '",$self->{title},"'");
                $element->replace_with($self->{title});
            }
        }

        # Set UTF8 content type if necessary
        if($encoding == 65001) {
            $head_element->push_content(
                [ 'meta',
                {'http-equiv' => 'Content-type'},
                {'content' => 'text/html;charset=UTF-8' },
                 ]);
        }
    }

    # Replace img recindex links with img src links
    debug(2,"DEBUG: converting img recindex attributes");
    @elements = $tree->find('img');
    foreach my $el (@elements)
    {
        $recindex = $el->attr('recindex') + 0;
        debug(3,"DEBUG: converting recindex ",$recindex," to src='",
              $self->{recindexlinks}{$recindex},"'");
        $el->attr('recindex',undef);
        $el->attr('hirecindex',undef);
        $el->attr('lorecindex',undef);
        $el->attr('src',$self->{recindexlinks}{$recindex});
    }

    # Replace filepos attributes with href attributes
    debug(2,"DEBUG: converting filepos attributes");
    @elements = $tree->look_down('filepos',qr/.*/x);
    foreach my $el (@elements)
    {
        $link = $el->attr('filepos');
        if($link)
        {
            debug(3,"DEBUG: converting filepos ",$link," to href");
            $link = '#fp' . $link;
            $el->attr('href',$link);
            $el->attr('filepos',undef);
        }
    }

    debug(2,"DEBUG: converting HTML tree");
    # We don't bother specifying an indent here, as the resulting
    # formatting is still broken and we have to insert newlines later
    # anyway.
    #
    # TODO: experiment with using Mojo::DOM instead
    $self->{text} = $tree->as_HTML(undef,'',{});

    croak($subname,"(): HTML tree output is empty")
        unless($self->{text});

    # Strip embedded nulls
    debug(2,"DEBUG: stripping nulls");
    $self->{text} =~ s/\0//gx;

    # HTML::TreeBuilder will not insert all appropriate newlines even
    # specifying indents in as_HTML, so add some back in for
    # readability even if tidy isn't called
    #
    # This is unfortunately quite slow.
    unless($args{nonewlines}) {
        debug(1,"DEBUG: adding newlines");
        $self->{text} =~ s#<(body|html)> \s* \n?
                          #<$1>\n#gix;
        $self->{text} =~ s#\n? <div
                          #\n<div#gix;
        $self->{text} =~ s#</div> \s* \n?
                          #</div>\n#gix;
        $self->{text} =~ s#</h(\d)> \s* \n?
                          #</h$1>\n#gix;
        $self->{text} =~ s#</head> \s* \n?
                          #</head>\n#gix;
        $self->{text} =~ s#\n? <(br|p)([\s>])
                          #\n<$1$2#gix;
        $self->{text} =~ s#</p>\s*
                          #</p>\n#gix;
    }

    return 1;
}


=head2 C<fix_html_filepos()>

Takes the raw HTML text of the object and replaces the filepos
anchors.  This has to be called before any other action that modifies
the text, or the filepos positions will not be valid.

Returns 1 if successful, undef if there was no text to fix.

This is called automatically by L</fix_html()>.

=cut

sub fix_html_filepos :method
{
    # There doesn't appear to be any clearer way of handling this
    # than the if-elsif chain.
    ## no critic (Cascading if-elsif chain)
    my $self = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my @filepos = ($$self{text} =~ /filepos="?([0-9]+)/gix);
    my $length = length($$self{text});
    return unless($length);
    my $atpos;

    debug(1,"DEBUG: creating filepos anchors");
    foreach my $pos (uniq reverse sort @filepos)
    {
        # First, see if we're pointing to a position outside the text
        if($pos >= $length-4)
        {
            debug(1,"DEBUG: filepos ",$pos," outside text, skipping");
            next;
        }

        # Second, figure out what we're dealing with at the filepos
        # offset indicated
        $atpos = substr($$self{text},$pos,5);
        if($atpos =~ /^<mbp/ix)
        {
            # Mobipocket-specific element
            # Insert a whole new <a id> here
            debug(2,"DEBUG: filepos ",$pos," points to '<mbp',",
                  " creating new anchor");
            substr($$self{text},$pos,4,'<a id="fp' . $pos . '"></a><mbp');
        }
        elsif($atpos =~ /^<(a|p)[ >]/ix)
        {
            # 1-character block-level elements
            debug(2,"DEBUG: filepos ",$pos," points to '",$1,"', updating id");
            substr($$self{text},$pos,2,"<$1 id=\"fp" . $pos . '"');
        }
        elsif($atpos =~ /^<(h\d)[ >]/ix)
        {
            # 2-character block-level elements
            debug(2,"DEBUG: filepos ",$pos," points to '",$1,"', updating id");
            substr($$self{text},$pos,3,"<$1 id=\"fp" . $pos . '"');
        }
        elsif($atpos =~ /^<(div)[ >]/ix)
        {
            # 3-character block-level elements
            debug(2,"DEBUG: filepos ",$pos," points to '",$1,"', updating id");
            substr($$self{text},$pos,4,"<$1 id=\"fp" . $pos . '"');
        }
        elsif($atpos =~ /^</ix)
        {
            # All other elements
            debug(2,"DEBUG: filepos ",$pos," points to '",$atpos,
                  "', creating new anchor");
            substr($$self{text},$pos,1,'<a id="fp' . $pos . '"></a><');
        }
        else
        {
            # Not an element
            carp("WARNING: filepos ",$pos," pointing to '",$atpos,
                 "' not handled!");
        }
    }
    return 1;
}


=head2 C<uncompress_dictionaryhuffman_records()>

Uncompresses all text records using
L</uncompress_dictionaryhuffman()>.  This destroys the existing
contents of $self->{text} if any.

This method is called automatically at the end of C<Load()> if
DictionaryHuffman encoding is detected.

=cut

sub uncompress_dictionaryhuffman_records :method
{
    my $self = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my $huffdata = $self->{huff};
    croak($subname,"(): no HUFF record found!\n") unless($huffdata);

    my $lasttextrecord = min($self->{header}{mobi}{indxrecord},
                             $self->{header}{mobi}{firstimagerecord}) - 1;
    my $compressed;

    if($self->{text})
    {
        debug(1,"WARNING: re-parsing HUFF/CDIC-compressed text destroys",
              " existing uncompressed text.");
    }

    $self->{text} = '';

    foreach my $recoffset (1 .. $lasttextrecord)
    {
        local $OUTPUT_AUTOFLUSH = 1;
        print "Uncompressing record ",$recoffset,"/",$lasttextrecord,"\r"
            if($recoffset % 10 == 0);
        $compressed = $self->{records}->[$recoffset]->{data};
        croak($subname,"(): no data found in record ",$recoffset,"!\n")
            unless($compressed);
        $self->{text} .= uncompress_dictionaryhuffman(
            data => $compressed,
            huff => $self->{huff},
            cdics => $self->{cdics});
    }
    print "Finished uncompressing text.\n";
    return 1;
}


################################
########## PROCEDURES ##########
################################

=head1 PROCEDURES

All procedures are exportable, but none are exported by default.  All
procedures can be exported by using the ":all" tag.


=head2 C<find_mobidedrm()>

Attempts to locate a copy of the MobiDeDrm script by searching PATH
and looking in the EBook::Tools user configuration directory (see
L<EBook::Tools/userconfigdir()>.

Returns the complete path to the script, or undef if nothing was found.

This will use package variable C<$mobidedrm_cmd> as its first guess,
and set that variable to the return value as well.

=cut

sub find_mobidedrm
{
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my @guesses;
    my $retval;
    my $confdir = userconfigdir();
    my $pattern = qr/^ MobiDeDrm(-\d+\.\d+)(.py)? $/ix;

    if($mobidedrm_cmd and -f $mobidedrm_cmd) { return $mobidedrm_cmd; }
    $mobidedrm_cmd = find_in_path($pattern,$confdir);
    debug(1,"DEBUG: found mobidedrm as '",$mobidedrm_cmd,"'");
    return $mobidedrm_cmd;
}


=head2 C<find_mobigen()>

Attempts to locate the mobigen executable by making a test execution
on predicted locations (including just checking PATH) and looking in
the EBook::Tools user configuration directory (see
L<EBook::Tools/userconfigdir()>.

Returns the system command used for a successful invocation, or undef
if nothing worked.

This will use package variable C<$mobigen_cmd> as its first guess, and
set that variable to the return value as well.

=cut

sub find_mobigen
{
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my @mobigen_guesses;
    my $retval;
    my $confdir = userconfigdir();

    if($OSNAME eq 'MSWin32')
    {
        @mobigen_guesses = (
            'kindlegen',
            'mobigen',
            'C:\Program Files\Mobipocket.com\kindlegen',
            'C:\Program Files\Mobipocket.com\mobigen',
            );
        if($confdir)
        {
            push(@mobigen_guesses,
                 $confdir . '\kindlegen',
                 $confdir . '\mobigen');
        }
    }
    else
    {
        @mobigen_guesses = (
            'kindlegen',
            'mobigen',
            'mobigen_linux',
            );
        if($confdir)
        {
            push(@mobigen_guesses,
                 $confdir . "/kindlegen",
                 $confdir . "/mobigen_linux",
                 $confdir . "/mobigen");
        }
    }
    unshift(@mobigen_guesses,$mobigen_cmd)
        if($mobigen_cmd);
    undef($mobigen_cmd);

    foreach my $guess (@mobigen_guesses)
    {
        no warnings 'exec';
        `$guess`;
        # MS Windows may use 256 for a not-found code instead of -1
        if($? != -1 && $? != 256)
        {
            debug(2,'DEBUG: `',$guess,'` returned ',$?);
            $mobigen_cmd = $guess;
            last;
        }
    }

    if($mobigen_cmd)
    {
        debug(1,"DEBUG: Found mobigen as '",$mobigen_cmd,"'");
        return $mobigen_cmd;
    }
    else { return; }
}


=head2 C<parse_mobi_exth($headerdata)>

Takes as an argument a scalar containing the variable-length
Mobipocket EXTH data from the first record.  Returns an array of
hashes, each hash containing the data from one EXTH record with values
from that data keyed to recognizable names.

If C<$headerdata> doesn't appear to be an EXTH header, carps a warning
and returns an empty list.

See:

http://wiki.mobileread.com/wiki/MOBI

=head3 Hash keys

=over

=item * C<type>

A numeric value indicating the type of EXTH data in the record.  See
package variable C<%exthtypes>.

=item * C<length>

The length of the C<data> value in bytes

=item * C<data>

The data of the record.

=back

=cut

sub parse_mobi_exth
{
    my ($headerdata) = @_;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    croak($subname,"(): no header data provided")
        unless($headerdata);

    my $length = length($headerdata);
    my @list;
    my $chunk;
    my @exthrecords = ();

    my $offset;
    my $recordcnt;


    $chunk = substr($headerdata,0,12);
    @list = unpack("a4NN",$chunk);
    if($list[0] ne 'EXTH')
    {
        debug(1,"(): Unrecognized Mobipocket EXTH ID '",$list[0],
             "' (expected 'EXTH')");
        return @exthrecords;
    }
    # The EXTH data never seems to be as long as remaining data after
    # the Mobipocket main header, so only check to see if it is
    # shorter, not equal
    if($length < $list[1])
    {
        debug(1,"EXTH header specified length ",$list[1]," but found ",
             $length," bytes.\n");
    }

    $recordcnt = $list[2];
    unless($recordcnt)
    {
        debug(1,"EXTH flag set, but no EXTH records present");
        return @exthrecords;
    }

    $offset = 12;
    debug(2,"DEBUG: Examining ",$recordcnt," EXTH records");
    foreach my $recordpos (1 .. $recordcnt)
    {
        my %exthrecord;

        $chunk = substr($headerdata,$offset,8);
        $offset += 8;
        @list = unpack("NN",$chunk);
        $exthrecord{type} = $list[0];
        $exthrecord{length} = $list[1] - 8;

        unless($exthtypes{$exthrecord{type}})
        {
            carp($subname,"(): EXTH record ",$recordpos," has unknown type ",
                 $exthrecord{type},"\n");
            $offset += $exthrecord{length};
            next;
        }
        unless($exthrecord{length})
        {
            carp($subname,"(): EXTH record ",$recordpos," has zero length\n");
            next;
        }
        if( ($exthrecord{length} + $offset) > $length )
        {
            carp($subname,"(): EXTH record ",$recordpos,
                 " longer than available data");
            last;
        }
        $exthrecord{data} = substr($headerdata,$offset,$exthrecord{length});
        debug(2,"DEBUG: EXTH record ",$recordpos," [",
              $exthtypes{$exthrecord{type}},"] has ",
              $exthrecord{length}, " bytes");
        push(@exthrecords,\%exthrecord);
        $offset += $exthrecord{length};
    }
    debug(1,"DEBUG: Found ",$#exthrecords+1," EXTH records");
    debug(1,"DEBUG: Found ",$length - $offset,
          " remaining bytes of data at EXTH offset ",$offset);
    return \@exthrecords;
}


=head2 parse_mobi_header($headerdata)

Takes as an argument a scalar containing the variable-length
Mobipocket-specific header data from the first record.  Returns a hash
containing values from that data keyed to recognizable names.

See:

http://wiki.mobileread.com/wiki/MOBI

=head3 keys

The returned hash will have the following keys (documented in the
order in which they are encountered in the header):

=over

=item C<identifier>

This should always be the string 'MOBI'.  If it isn't, the procedure
croaks.

=item C<headerlength>

This is the size of the complete header.  If this value is different
from the length of the argument, the procedure croaks.

=item C<type>

A numeric code indicating what category of Mobipocket file this is.

=item C<encoding>

A numeric code representing the encoding.  Expected values are '1252'
(for Windows-1252) and '65001 (for UTF-8).

The procedure carps a warning if an unexpected value is encountered.

=item C<uniqueid>

This is thought to be a unique ID for the book, but its actual use is
unknown.

Use with caution.  This key may be renamed in the future if more
information is found.

=item C<version>

This is thought to be the Mobipocket format version.  A second version
code shows up again later as C<version2> which is usually the same on
unprotected books but different on DRMd books.

Use with caution.  This key may be renamed in the future if more
information is found.

=item C<reserved>

40 bytes of reserved data.

Use with caution.  This key may be renamed in the future if more
information is found.

=item C<indxrecord>

This is thought to be the record offset to the first 'INDX' record, so
named for its first four letters.

Use with caution.  This key may be renamed in the future if more
information is found.

=item C<titleoffset>

Offset in record 0 (not from start of file) of the full title of the
book.

=item C<titlelength>

Length in bytes of the full title of the book

=item C<languageunknown>

16 bits of unknown data thought to be related to the book language.

Use with caution.  This key may be renamed in the future if more
information is found.

=item C<language>

A pseudo-IANA language code string representing the main book language
(i.e. the value of <dc:language>).  See C<%mobilangcodes> for an exact
map of raw values to this string and notes on non-compliant results.

=item C<dilanguageunknown>

16 bits of unknown data thought to be related to the dictionary input
language.

Use with caution.  This key may be renamed in the future if more
information is found.

=item C<dilanguage>

A pseudo-IANA language code string for the DictionaryInLanguage
element.  See C<%mobilangcodes> for an exact map of raw values to this
string and notes on non-compliant results.

=item C<dolanguageunknown>

16 bits of unknown data thought to be related to the dictionary output
language.

Use with caution.  This key may be renamed in the future if more
information is found.

=item C<dolanguage>

A pseudo-IANA language code string for the DictionaryOutLanguage
element.  See C<%mobilangcodes> for an exact map of raw values to this
string and notes on non-compliant results.

=item C<version2>

This is another Mobipocket format version related to DRM.  If no DRM
is present, it should be the same as C<version>.

Use with caution.  This key may be renamed in the future if more
information is found.

=item C<firstimagerecord>

This is thought to be an index to the first record containing image
data.  If there are no images in the book, this value will be
4294967295 (0xffffffff)

Use with caution.  This key may be renamed in the future if more
information is found.

=item C<huffrecord>

This is thought to be the record offset to the 'HUFF' record, used in
HUFF/CDIC decompression.

Use with caution.  This key may be renamed in the future if more
information is found.

=item C<huffreccnt>

This is thought to be the number of HUFF and CDIC records, starting at
C<huffrecord>.

Use with caution.  This key may be renamed in the future if more
information is found.

=item C<datprecord>

This is thought to be the record offset to the first 'DATP' record, so
named for its first four letters.

Use with caution.  This key may be renamed in the future if more
information is found.

=item C<datpreccnt>

This is thought to be the number of 'DATP' records present.

Use with caution.  This key may be renamed in the future if more
information is found.

=item C<exthflags>

A 32-bit bitfield related to the Mobipocket EXTH data.  If bit 6
(0x40) is set, then there is at least one EXTH record.


=item C<unknown116>

36 bytes of unknown data at offset 116.  This value will be undefined
if the header data was not long enough to contain it.

Use with caution.  This key may be renamed in the future if more
information is found.


=item C<drmoffset>

A number thought to be the byte offset inside of the record 0 data in
which DRM data can be found.  If present and no DRM is set, contains
either the value 0xFFFFFFFF (normal books) or 0x00000000 (samples).
This value will be undefined if the header data was not long enough to
contain it.

Use with caution.  This key may be renamed in the future if more
information is found.


=item C<drmcount>

A number thought to be related to DRM.

This value will be undefined if the header data was not long enough to
contain it.

Use with caution.  This key may be renamed in the future if more
information is found.


=item C<drmsize>

A number thought to be the size of the data in bytes after
C<drmoffset> containing DRM keys.

This value will be undefined if the header data was not long enough to
contain it.

Use with caution.  This key may be renamed in the future if more
information is found.


=item C<drmflags>

A number thought to be related to DRM.

This value will be undefined if the header data was not long enough to
contain it.

Use with caution.  This key may be renamed in the future if more
information is found.


=item C<unknown168>

32 bits of unknown data at offset 168, usually zeroes.  This value
will be undefined if the header data was not long enough to contain
it.

Use with caution.  This key may be renamed in the future if more
information is found.

=item C<unknown172>

32 bits of unknown data at offset 172, usually zeroes.  This value
will be undefined if the header data was not long enough to contain
it.

Use with caution.  This key may be renamed in the future if more
information is found.

=item C<unknown176>

16 bits of unknown data at offset 176.  This value will be undefined
if the header data was not long enough to contain it.

Use with caution.  This key may be renamed in the future if more
information is found.

=item C<lastimagerecord>

This is thought to be an index to the last record containing image
data.  If there are no images in the book, this value will be 65535
(0xffff).

Use with caution.  This key may be renamed in the future if more
information is found.

=item C<unknown180>

32 bits of unknown data at offset 180.  This value will be undefined
if the header data was not long enough to contain it.

Use with caution.  This key may be renamed in the future if more
information is found.

=item C<fcisrecord>

This is thought to be an index to a 'FCIS' record, so named because
those are always the first four characters when the record data is
decompressed using uncompress_palmdoc().

This value will be undefined if the header data was not long enough to
contain it.

Use with caution.  This key may be renamed in the future if more
information is found.

=item C<unknown188>

32 bits of unknown data at offset 188.  This value will be undefined
if the header data was not long enough to contain it.

Use with caution.  This key may be renamed in the future if more
information is found.

=item C<flisrecord>

This is thought to be an index to a 'FLIS' record, so named because
those are always the first four characters when the record data is
decompressed using uncompress_palmdoc().

This value will be undefined if the header data was not long enough to
contain it.

Use with caution.  This key may be renamed in the future if more
information is found.

=item C<unknown196>

32 bits of unknown data at offset 180.  This value will be undefined
if the header data was not long enough to contain it.

Use with caution.  This key may be renamed in the future if more
information is found.

=item C<unknown200>

Unknown data of unknown length running to the end of the header.  This
value will be undefined if the header data was not long enough to
contain it.

Use with caution.  This key may be renamed in the future if more
information is found.

=item C<extradataflags>

Two bytes sometimes found inside of C<unknown200>, used to determine
if extra data has been appended to each text record that should not be
used in decompression.

=back

=cut

sub parse_mobi_header   ## no critic (ProhibitExcessComplexity)
{
    # There's no way to refactor this without breaking up chunks into
    # separate subroutines, which is a bad idea.
    my ($headerdata) = @_;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    croak($subname,"(): no header data provided")
        unless($headerdata);

    my $length = length($headerdata);
    my @enckeys = keys(%pdbencoding);
    my $chunk;     # current chunk of headerdata being unpacked
    my @list;      # temporary holding area for unpacked data
    my %header;    # header hash to return;
    my $hexstring; # hexadecimal debugging output string

    croak($subname,"(): header data is too short! (only ",$length," bytes)")
        if($length < 116);

    # The Mobipocket header data is large enough that it's easier to
    # deal with when handled in smaller chunks

    # First chunk is 24 bytes before reserved block
    $chunk = substr($headerdata,0,24);
    @list = unpack("a4NNNNN",$chunk);
    if($list[0] ne 'MOBI')
    {
        croak($subname,
              "(): Unrecognized Mobipocket header ID '",$list[0],
              "' (expected 'MOBI')");
    }
    if($list[1] != $length)
    {
        croak($subname,
              "(): header specified length ",$list[1]," but found ",
              $length," bytes.");
    }

    $header{identifier}   = $list[0]; # Bytes 00-04 (16-20)
    $header{headerlength} = $list[1]; # Bytes 04-08 (20-24)
    $header{type}         = $list[2];
    $header{encoding}     = $list[3];
    $header{uniqueid}     = $list[4];
    $header{version}      = $list[5];

    if(!defined $pdbencoding{$header{encoding}})
    {
        carp($subname,"(): unknown encoding '",$header{encoding},"'");
    }
    else
    {
        debug(1,"DEBUG: Found encoding ",$pdbencoding{$header{encoding}});
    }

    # Second chunk is 40 bytes of reserved data, usually all 0xff
    $header{reserved} = substr($headerdata,24,40);
    $hexstring = hexstring($header{reserved});
    debug(2,"DEBUG: reserved data: 0x",$hexstring)
        if($hexstring ne ('ff' x 40));

    # Third chunk is 12 bytes up to the language block
    $chunk = substr($headerdata,64,12);
    @list = unpack("NNN",$chunk);
    $header{indxrecord}  = $list[0];
    $header{titleoffset} = $list[1];
    $header{titlelength} = $list[2];

    # Fourth chunk is 12 bytes containing the language codes
    $chunk = substr($headerdata,76,12);
    @list = unpack("nCCnCCnCC",$chunk);
    $header{languageunknown}   = $list[0];
    $header{language}          = parse_mobi_language($list[2],$list[1]);
    $header{dilanguageunknown} = $list[3];
    $header{dilanguage}        = parse_mobi_language($list[5],$list[4]);
    $header{dolanguageunknown} = $list[6];
    $header{dolanguage}        = parse_mobi_language($list[8],$list[7]);

    # Fifth chunk is 8 bytes until next unknown block
    $chunk = substr($headerdata,88,8);
    @list = unpack("NN",$chunk);
    $header{version2}         = $list[0];
    $header{firstimagerecord} = $list[1];

    debug(2,"DEBUG: INDX record: ",$header{indxrecord});
    if($header{firstimagerecord} == 0xffffffff)
    {
        debug(2,"DEBUG: no image records present");
    }
    else
    {
        debug(2,"DEBUG: first image record: ",$header{firstimagerecord});
    }

    # Sixth chunk is HUFF/CDIC and DATP record offsets
    $chunk = substr($headerdata,96,16);
    @list = unpack("NNNN",$chunk);
    $header{huffrecord} = $list[0];
    $header{huffreccnt} = $list[1];
    $header{datprecord} = $list[2];
    $header{datpreccnt} = $list[3];

    # Seventh and last chunk guaranteed to be present is the EXTH
    # bitfield
    $chunk = substr($headerdata,112,4);
    $header{exthflags} = unpack("N",$chunk);

    # Remaining chunks are only parsed if the header is long enough

    # Eighth chunk is 36 bytes of unknown data
    if($length >= 152)
    {
        $header{unknown116} = substr($headerdata,116,32);
        $header{unknown148} = unpack('N',substr($headerdata,148,4));
    }

    # Ninth chunk is 16 bytes of DRM-related data
    if($length >= 168)
    {
        $chunk = substr($headerdata,152,16);
        @list = unpack("NNNN",$chunk);
        $header{drmoffset} = $list[0]; # Offset 152 - 155
        $header{drmcount}  = $list[1]; # Offset 156 - 159
        $header{drmsize}   = $list[2]; # Offset 160 - 163
        $header{drmflags}  = $list[3]; # Offset 164 - 167
        debug(1,"DEBUG: Found DRM offset ",
              sprintf("0x%08x",$header{drmoffset}));
    }

    # Tenth chunk is 8 bytes of unknown data, usually zeroes
    if($length >= 176)
    {
        $chunk = substr($headerdata,168,8);
        @list = unpack('NN',$chunk);
        $header{unknown168} = $list[0];
        $header{unknown172} = $list[1];
    }

    # Eleventh chunk is 2 16-bit values and 5 32-bit values, usually nonzero
    if($length >= 200)
    {
        $chunk = substr($headerdata,176,24);
        @list = unpack("nnNNNNN",$chunk);
        $header{unknown176}      = $list[0];
        $header{lastimagerecord} = $list[1];
        $header{unknown180}      = $list[2];
        $header{fcisrecord}      = $list[3];
        $header{unknown188}      = $list[4];
        $header{flisrecord}      = $list[5];
        $header{unknown196}      = $list[6];
    }

    # Last possible chunk is unknown data lasting to the end
    # of the header.
    if($length >= 201)
    {
        $header{unknown200} = substr($headerdata,200,$length-200);
        debug(2,"DEBUG: Found ",$length-200,
              " bytes of unknown final data in Mobipocket header");
        debug(2,"       0x",hexstring($header{unknown200}));
    }

    # Part of that unknown data is the Extra Data Flags
    #
    # This is 16 bits used to determine if extra data has been stuffed
    # at the end of each record that should not be used in
    # decompression.
    if($length >= 228)
    {
        $chunk = substr($headerdata,226,2);
        $header{extradataflags} = unpack("n",$chunk);
        debug(2,"DEBUG: Found Extra Data Flags in Mobipocket header");
        debug(2,"       0x",hexstring($chunk));
    }

    foreach my $key (sort keys %header)
    {
        no warnings;
        my $value;
        if(length($header{$key}) <= 4)
        {
            $value = $header{$key};
        }
        elsif(length($header{$key}) > 10)
        {
            $value = '0x' . hexstring($header{$key});
        }
        elsif(int($header{$key}) > 0x04ff)
        {
            $value = sprintf("0x%08x",$header{$key});
        }
        else
        {
            $value = $header{$key};
        }
        debug(2,'DEBUG: mobi{',$key,'}=',$value);
    }
    return \%header;
}


=head2 C<parse_mobi_language($languagecode, $regioncode)>

Takes the integer values C<$languagecode> and C<$regioncode> unpacked from
the Mobipocket header and returns a language string mostly (but not
entirely) conformant to the IANA language subtag registry codes.

Croaks if C<$languagecode> is not provided.  If C<$regioncode> is not
provided or not recognized, it is disregarded and the base language
string (with no region or script) is returned.

If C<$languagecode> is not provided, the sub croaks.  If it isn't
recognized, a warning is carped and the sub returns undef.  Note that
0,0 is a recognized code returning an empty string.

See C<%mobilanguagecodes> for an exact map of values.  Note that the
bottom two bits of the region code appear to be unused (i.e. the
values are all multiples of 4).

=cut

sub parse_mobi_language
{
    my ($languagecode,$regioncode) = @_;
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    croak($subname,"(): no language code provided\n")
        unless(defined $languagecode);

    my $language = $mobilangcode{$languagecode}{$regioncode};

    if(defined $language)
    {
        debug(2,"DEBUG: found language '",$language,"'",
              " (language code ",$languagecode,",",
              " region code ",$regioncode,")");
    }
    else
    {
        debug(1,"DEBUG: language code ",$languagecode,
              ", region code ",$regioncode," not known",
              " -- ignoring region code");
        $language = $mobilangcode{$languagecode}{0};
        if(!$language)
        {
            carp("WARNING: language code ",$languagecode,
                 " not recognized!\n");
        }
        else
        {
            debug(1,"DEBUG: found downgraded language '",$language,"'",
                  " (language code ",$languagecode,",",
                  " region code 0)");
        }
    } # if($language) / else
    return $language;
}


=head2 C<pid_append_checksum($pid)>

Computes the Mobipocket PID checksum used as the final two bytes of
the PID and appends them to C<$pid>, returning the merged string.

Used by L</pid_is_valid($pid)>.

=cut

sub pid_append_checksum
{
    my $pid = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my $retval = $pid;
    my $crc;
    my $byte;
    my $pos;

    my $letters = "ABCDEFGHIJKLMNPQRSTUVWXYZ123456789";
    my $length = length($letters);
    $crc = ~ String::CRC32::crc32($pid,-1);
    $crc = $crc & 0xffffffff;
    $crc = $crc ^ ($crc >> 16);
    for(0 .. 1)
    {
        $byte = $crc & 0xff;
        $pos = (int($byte / $length)) ^ ($byte % $length);
        $retval .= substr($letters,$pos % $length,1);
        $crc >>= 8;
    }
    return $retval;
}


=head2 C<pid_is_valid($pid)>

Returns 1 if the PID is a valid Mobipocket/Kindle PID and 0 otherwise.

This is determined by first ensuring that C<$pid> is exactly ten bytes
long, and then stripping the final two bytes normally used as a
checksum and recomputing them, returning 1 only if they are recomputed
correctly.

=cut

sub pid_is_valid
{
    my $pid = shift;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    return 0 unless($pid);

    my $pid2 = pid_append_checksum(substr($pid,0,-2));

    return 0 unless(length($pid) == 10);
    if($pid eq $pid2) { return 1; }
    else { return 0; }
}


=head2 C<pukall_cipher_1(%args)>

This is a COMPLETELY UNTESTED implementation of the Pukall Cipher 1
algorithm used for encryption and decryption in Mobipocket files.  It
is a 128-bit stream cipher.  For more information and alternate
implementations, see L<http://membres.lycos.fr/pc1/>.

Use at your own risk.  Bug reports appreciated.

=head3 Arguments

=over

=item * C<key>

16-byte encryption key.  This must be provided, and must be exactly 16
bytes, or the procedure will croak.

=item * C<input>

Input data to be either encrypted or decrypted.  If this is not
provided, the procedure croaks.

=item * C<encrypt> (optional)

If set to true, the cipher will be used to encrypt the input data.  If
not set, or set to false, the cipher will be used to decrypt the input
data.

=back

=cut

sub pukall_cipher_1
{
    my %args = @_;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my %valid_args = (
        'key' => 1,
        'input' => 1,
        'encrypt' => 1,
        );
    foreach my $arg (keys %args)
    {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }

    croak($subname,"(): no key provided!\n")
        unless(defined $args{key});
    croak($subname,"(): no input provided!\n")
        unless(defined $args{input});

    my $key = $args{key};
    my $keylength = length($key);
    my $encrypt = $args{encrypt} || 0;
    my $input = $args{input};
    my $output = '';

    croak($subname,"(): Invalid key length (expected 16, got ",
          $keylength,")!\n")
        unless($keylength == 16);

    my @keyarray;
    my $key_xor = 0;
    my $sum1 = 0;
    my $sum2 = 0;
    my $byte;
    my $byte_xor;
    my $temp_xor;

    foreach my $pos (0 .. 7)
    {
        $byte = ord(substr($key,$pos*2,1) << 8) | ord(substr($key,$pos*2+1,1));
        $keyarray[$pos] = $byte;
    }

    foreach my $offset ( 0 .. length($input) )
    {
        $temp_xor = 0;
        $byte_xor = 0;
        foreach my $keypos (0 .. 7)
        {
            $temp_xor ^= $keyarray[$keypos];
            $sum2 = ($sum2 + $keypos) * 20021 + $sum1;
            $sum1 = ($temp_xor * 346) & 0xFFFF;
            $sum2 = ($sum1 + $sum2) & 0xFFFF;
            $temp_xor = ($temp_xor * 20021 + 1) & 0xFFFF;
            $byte_xor ^= $temp_xor ^ $sum2;
        }
        $byte = ord(substr($input,$offset,1));
        if($encrypt) { $key_xor = $byte * 257; }
        $byte = (($byte ^ ($byte_xor >> 8)) ^ $byte_xor) & 0xFF;
        if(!$encrypt) { $key_xor = $byte * 257; };
        foreach my $keypos (0 .. 7)
        {
            $keyarray[$keypos] ^= $key_xor;
        }
        $output .= chr($byte);
    }
    return $output;
}


=head2 C<record_extradata_size(%args)>

This checks the end of a text record for extra data that should not be
made part of decompression and returns the total size of all data
fields.

=head3 Arguments

=over

=item * C<dataref>

A reference to the record data

=item * C<extradataflags>

16 bits worth of flags indicating which extra data fields are present.

=back

=cut

sub record_extradata_size
{
    my %args = @_;
    my $subname = ( caller(0) )[3];
    debug(3,"DEBUG[",$subname,"]");

    my %valid_args = (
        'dataref' => 1,
        'extradataflags' => 1,
        );
    foreach my $arg (keys %args)
    {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }

    my $dataref = $args{dataref};
    croak($subname,"(): no record data provided!\n")
        unless(defined $dataref);
    croak($subname,"(): record data is not a reference\n") unless(ref $dataref);
    croak($subname,"(): no extra data flags provided!\n")
        unless(defined $args{extradataflags});

    my $datalength = length($$dataref);

    my $totalsize = 0;
    my $trailpos = 0;

    foreach my $flagbit (reverse 0..15)
    {
        if($args{extradataflags} & (1 << $flagbit))
        {
            my $bitpos = 0;
            my $startpos = $trailpos;
            my $traildata;
            my $trailsize = 0;
            my $byte;

            # Bit 0 is the multi-byte character overlap flag, and has
            # a different format from all other flags, where the size
            # is the first two bits of the last unparsed byte of
            # record data (i.e. the extra data bytes closest to the
            # actual record text), plus one for the byte containing
            # the size itself.
            if($flagbit == 0)
            {
                $trailpos += 1;
                $trailsize = ord(substr($$dataref,$datalength-$trailpos,1)) & 0x03;
                $trailsize += 1; # The above line doesn't include the size byte itself
                debug(3,"DEBUG: ",$trailsize," bytes of trailing data at flagbit ",
                      $flagbit,", startpos ",$startpos);
                $totalsize += $trailsize;
                last;
            }

            # For all other bits, the size is a backward-encoded
            # variable-width integer at the end of the record data.
            do
            {
                $trailpos += 1;
                $byte = ord(substr($$dataref,$datalength-$trailpos,1));
                $trailsize |= (($byte & 0x7f) << $bitpos);
                $bitpos += 7;
            }
            while( !($byte & 0x80) && ($bitpos < 28) && ($trailpos < $datalength) );
            $traildata = substr($$dataref,$datalength-$trailsize,$trailsize);
            debug(3,"DEBUG: ",$trailsize," bytes of trailing data at flagbit ",
                  $flagbit,", startpos ",$startpos);
            $totalsize += $trailsize;
        }
    }
    return $totalsize;
}


=head2 C<system_mobidedrm(%args)>

Runs python on a copy of C<MobiDeDrm.py> if it is available (not
included with this distribution) to downconvert a Mobipocket file.

Returns the output filename on success, or undef otherwise.


=head3 Arguments

=over

=item * C<infile>

The input filename.  If not specified or invalid, the procedure
returns undef.

=item * C<outfile>

The output filename.  If not specified, the program will use a name
based on the input file, appending '-nodrm' to the basename and
keeping the extension.  In the special case of Mobipocket files ending
in '-sm', the '-sm' portion of the basename is simply removed, and
nothing else is appended.

=item * C<pid>

The PID to use to decrypt the file.  If not specified or invalid, the
procedure returns undef.

=back

=cut

sub system_mobidedrm
{
    my %args = @_;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my %valid_args = (
        'infile' => 1,
        'outfile' => 1,
        'pid' => 1,
        );
    foreach my $arg (keys %args)
    {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }

    if(!$args{infile})
    {
        debug(1,$subname,"(): no input file specified!");
        return;
    }

    if(! -f $args{infile})
    {
        debug(1,$subname,"(): input file '",$args{infile},"' not found!");
        return;
    }

    if(! pid_is_valid($args{pid}))
    {
        debug(1,$subname,"(): pid '",$args{pid},"' is not valid!");
        return;
    }

    if( !find_mobidedrm() )
    {
        debug(1,$subname,"(): MobiDeDRM is not available!");
        return;
    }

    my $outfile = $args{outfile};
    my $suffix;
    if(!$outfile)
    {
        ($outfile,undef,$suffix) = fileparse($args{infile},'\.\w+$');
        if($outfile =~ /-sm$/ix)
        {
            $outfile =~ s/-sm$//ix;
            $outfile .= $suffix;
        }
        else
        {
            $outfile .= '-nodrm' . $suffix;
        }
    }

    my $retval = system('python',$mobidedrm_cmd,
                        $args{infile},$outfile,$args{pid});

    if($retval == -1 or $retval == 256)
    {
        debug(1,$subname,"(): python not available!");
        return;
    }

    if(-z $outfile)
    {
        debug(1,$subname,"(): MobiDeDRM produced 0-sized output!");
        unlink($outfile);
        return;
    }
    return $outfile;
}


=head2 C<system_mobigen(%args)>

Runs C<mobigen> to convert OPF, HTML, or ePub input into a Mobipocket
.prc/.mobi book.  The procedure L<find_mobigen()> is called to locate
the executable.

Returns the return value from mobigen, or undef if no filename was
specified or the file did not exist.  Also returns undef if mobigen
could not be found.

=head3 Arguments

=over

=item * C<infile>

The input filename.  If not specified or invalid, the procedure
returns undef.

=item * C<outfile>

The output filename.  The mobigen executable will choose its own
filename for direct output, but if this argument is specified, the
output file will be renamed to the specified filename instead.

If not specified, the default output will be left in place.

=item * C<dir>

The directory in which to place the output file.  The mobigen
executable itself will always place its output into the current
working directory, but if this argument is specified, the output file
will be moved into the specified directory, creating that directory if
necessary.

=item * C<compression>

Compression level from 0-2, where 0 is no compression, 1 is PalmDoc
compression, and 2 is HUFF/CDIC compression.  If not specified,
defaults to 1 (PalmDoc compression).

=back

=cut

sub system_mobigen
{
    my %args = @_;
    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    my %valid_args = (
        'infile' => 1,
        'outfile' => 1,
        'dir' => 1,
        'compression' => 1,
        );
    foreach my $arg (keys %args)
    {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }

    if(!$args{infile})
    {
        debug(1,$subname,"(): no input file specified!");
        return;
    }

    if(! -f $args{infile})
    {
        debug(1,$subname,"(): input file '",$args{infile},"' not found!");
        return;
    }

    find_mobigen();
    if(!$mobigen_cmd)
    {
        debug(1,$subname,"(): mobigen command not specified!");
        return;
    }

    my @mobigen = ($mobigen_cmd);
    my $mobigenoutput = fileparse($args{infile},'\.\w+$') . '.mobi';
    my $outfile = $args{outfile} || $mobigenoutput;
    my $compression = $args{compression};
    my $retval;

    if(defined $compression)
    {
        unless($compression >= 0 and $compression <= 2)
        {
            croak($subname,"(): invalid compression level ",
                  $compression,"!\n");
        }
    }
    else { $compression = 1; }

    push(@mobigen,"-c$compression",$args{infile});
    debug(2,"DEBUG: Compiling '",$args{infile},"' into '",$mobigenoutput,
          "' using compression level ",$compression);

    $retval = system(@mobigen);
    if($retval)
    {
        debug(1,"WARNING: mobigen exited ",$retval);
    }
    if(! -f $mobigenoutput)
    {
        carp($subname,"(): expected output file '",$mobigenoutput,
              "' not found!\n");
    }
    if($args{outfile})
    {
        rename($mobigenoutput,$args{outfile})
            or carp($subname,"(): unable to rename '",$mobigenoutput,"' to '",
                    $args{outfile},"'!\n");
    }
    if($args{dir})
    {
        if(! -d $args{dir})
        {
            mkpath($args{dir})
                or carp($subname,"(): unable to create directory '",
                        $args{dir},"'!\n");
        }
        rename($outfile,"$args{dir}/$outfile")
            or carp($subname,"(): unable to move '",$outfile,"' into '",
                    $args{dir},"'!\n");
    }
    return $retval;
}


=head2 C<uncompress_dictionaryhuffman(%args)>

Uncompresses text compressed with the DictionaryHuffman compression
scheme.

=head3 Arguments

=over

=item * C<data>

A scalar containing the compressed data to uncompress.

=item * C<huff>

A hashref pointing to the HUFF record data

=item * C<cdics>

An arrayref pointing to the CDIC record data

=item * C<depth>

The current depth of the huffman tree, currently only used in
debugging.

=back

=cut

sub uncompress_dictionaryhuffman
{
    my (%args) = @_;
    my $subname = (caller(0))[3];
    debug(3,"DEBUG[",$subname,"]");

    my %valid_args = (
        'data' => 1,
        'huff' => 1,
        'cdics' => 1,
        'depth' => 1,
        );
    foreach my $arg (keys %args)
    {
        croak($subname,"(): invalid argument '",$arg,"'")
            if(!$valid_args{$arg});
    }

    croak($subname,"(): no data provided!\n")
        unless($args{data});

    # Why does $data have to be zero-terminated this way?  Sometimes it
    # runs out of bits otherwise, though.
    my $data = $args{data} . "\x00\x00";
    my $octets = length($data);
    my $depth = $args{depth} || 0;
    debug(3,"DEBUG: uncompressing ",$octets," octets at depth ",$depth);

    my $huffref = $args{huff};
    my $cdicref = $args{cdics};
    my $cdic;
    my $dataoffset = 0;
    my ($bits, $nextbits);
    my ($cacheoffset, $cacheval);

    my $codeword;       # CDIC codeword
    my $codebits;       # Extra bits at the end of $codeword
    my $codelength;     # number of bits in the code
    my $index;          # CDIC index key

    my $branch;
    my $branchcode;
    my $branchsize;
    my $branchoffset;

    my $text = '';

    my $bitsize = length($data) * 8;
    my $bitvector = Bit::Vector->new($bitsize);
    my $bitoffset;
    my $bitpos = 0;

    # Unfortunately, the bitstream needs to be processed from left to
    # right, and Bit::Vector really likes to process from right to
    # left, so we have to process by chunk instead of using
    # Block_Store
    while($bitpos < $bitsize)
    {
        $bitoffset = $bitsize-$bitpos;
        $bits = unpack('C',substr($data,$dataoffset,1));
        $bitvector->Chunk_Store(8,$bitoffset-8,$bits);
        $dataoffset++;
        $bitpos += 8;
    }


    # Debugging code inside the loop is commented out because each
    # subroutine call incurs substantial overhead (even when the
    # debugging level is low enough that nothing is printed).

    $bitpos = 0;
    do
    {
        $bitoffset = $bitsize-$bitpos;
#        debug(4,"\nDEBUG: DEPTH ",$depth," BITPOS ",$bitpos,
#              " [bitoffset=",$bitoffset,"]");
        $nextbits = min(8,$bitoffset);
        $cacheoffset = $bitvector->Chunk_Read($nextbits,$bitoffset-$nextbits);
        if($cacheoffset > $#{$huffref->{cache}})
        {
            croak($subname,"(): invalid HUFF cache offset ",$cacheoffset,
                  " found at bit position ",$bitpos,"!\n");
            #return $text;
        }
        $cacheval = $huffref->{cache}->[$cacheoffset];
#        debug(4,"## cacheval[",$cacheoffset,"]=",$cacheval);
        $codelength = $cacheval & 0x1F; # low 5 bits
#        debug(4,"## codelength=",$codelength);
        if(!$codelength)
        {
            croak($subname,"(): HUFF cache found zero codelength",
                  " at bit position ",$bitpos,"!\n");
            #return $text;
        }

        $nextbits = min(32,$bitoffset);
        $bits = $bitvector->Chunk_Read($nextbits,$bitoffset-$nextbits);
#        debug(4,"## bits=",sprintf("%0${nextbits}b",$bits));

        if(!$bits)
        {
#            debug(2,"DEBUG: no more data, returning from depth ",
#                  $depth," with:");
#            debug(2,"       '",excerpt_line($text),"'");
            return $text;
        }
        if($codelength > $bitoffset)
        {
            carp($subname,"():\n",
                 "WARNING: ran out of bits at depth ",$depth,"!\n");

            if($bits)
            {
                carp($subname,"():\n",
                     "supposedly out of bits, but bit data still exists!\n");
            }
#            debug(2,"DEBUG: returning from depth ",$depth," with '",$text,"'");
            return $text;
        }

        $codebits = $bitvector->Chunk_Read($codelength,$bitoffset-$codelength);
#        debug(4,"## codebits=",$codebits);
        if($cacheval & 0x80)
        {
            # Codeword is unique and in the short codewords cache
            $codeword = ($cacheval >> 8) - $codebits;
        }
        unless($cacheval & 0x80)
        {
            # Code is not in the cache, must be looked up from base
            # table.  The problem is, the codelength is not known, so
            # we have to iterate through the basetable adding bits to
            # the code until the code is larger than the table value.
            #
            # There has to be a better way to do this?
#            debug(4,"## code not in cache");
            while($codebits < $huffref->{basetable}->[($codelength-1)*2])
            {
                $codelength++;
#                debug(4,"## codelength extended to ",$codelength);
                $codebits = $bitvector->Chunk_Read($codelength,$bitoffset-$codelength);
            }
            $codeword = $huffref->{basetable}->[($codelength-1)*2+1];
            $codeword -= $codebits;
        }
#        debug(4,"## codeword=",$codeword);
        $cdic = $codeword >> $huffref->{codelength};
        if($cdic > $#{$cdicref})
        {
            croak($subname,"(): \n HUFF entry referenced invalid CDIC ",$cdic,
                  " at bit position ",$bitpos,", depth ",$depth,"!\n");
            #return $text;
        }

#        debug(4,"## cdic=",$cdic);
        $index = $codeword - ($cdic << $huffref->{codelength});
#        debug(4,"## cdic[",$cdic,"][",$index,"]=",
#              $cdicref->[$cdic]->{indexes}->[$index]);
        $branchoffset = 16 + $cdicref->[$cdic]->{indexes}->[$index];
#        debug(4,"## branchoffset=",$branchoffset);

        # 15 lowest bits of $branchcode are the size of the leaf in
        # bytes -- however, only sizes 1-127 are ever used?
        # 16th bit is set if the leaf is the end of the tree and no
        # recursion is needed
        $branchcode = unpack('n',substr($cdicref->[$cdic]->{data},
                                           $branchoffset,2) );
        $branchsize = $branchcode & 0x7fff;
#        debug(4,"## branchcode=",$branchcode,"  branchsize=",$branchsize,
#              "  branchcode&0x8000=",$branchcode & 0x8000);
        if(!$branchsize || $branchsize > 127)
        {
            carp($subname,"():\n",
                 " HUFF branch at bit position ",$bitpos,", depth ",$depth,
                 " has size ",$branchsize," (expected 1-127)\n");
        }
        $branch = substr($cdicref->[$cdic]->{data},$branchoffset+2,$branchsize);
        if($branchcode & 0x8000)
        {
            # End of tree.  Append branch to text.
#            debug(4,"## branch='",$branch,"'");
            $text .= $branch;
        }
        else
        {
#            debug(2,"DEBUG: recursing at depth ",$depth,
#                  " with:");
#            debug(2,"       '",excerpt_line($text),"'");
            $text .= uncompress_dictionaryhuffman(
                data => $branch,
                huff => $args{huff},
                cdics => $args{cdics},
                depth => $depth + 1);
        }
        $bitpos += $codelength;
    } while($bitpos < length($data) * 8);
#    debug(2,"DEBUG: returning from depth ",$depth," with:");
#    debug(2,"       '",excerpt_line($text),"'");
    return $text;
}


=head2 C<unpack_mobi_language($data)>

Takes as an argument 4 bytes of data.  If less data is provided, the
sub croaks.  If more, a debug warning is provided, but the sub
continues.

In scalar context returns a language string mostly (but not entirely)
conformant to the IANA language subtag registry codes.

In list context, returns the language string, an unknown code integer,
a region code integer, and a language code integer, with the last
three being directly unpacked values.

See C<%mobilangcodes> for an exact map of values.  Note that the
bottom two bits of the region code appear to be unused (i.e. the
values are all multiples of 4).  The unknown code integer appears to
be unused, and is generally zero.

The original implementation by Mobipocket may have been via
Microsoft's .NET CultureInfo class.  See:
L<http://msdn.microsoft.com/en-us/library/system.globalization.cultureinfo(VS.71).aspx>

=cut

sub unpack_mobi_language
{
    my $data = shift;

    my $subname = ( caller(0) )[3];
    debug(2,"DEBUG[",$subname,"]");

    croak($subname,"(): no language data provided")
        unless($data);

    croak($subname,"(): language data is too short (only ",length($data),
          " bytes, need 4\n")
        if(length($data) < 4);

    debug(1,$subname,"(): expected 4 bytes of data, but received ",
          length($data))
        if(length($data) > 4);

    my ($unknowncode,$regioncode,$languagecode) = unpack('nCC',$data);
    my $language = parse_mobi_language($languagecode,$regioncode);

    my @returnlist = ($language,$unknowncode,$regioncode,$languagecode);
    if(wantarray) { return @returnlist; }
    else { return $returnlist[0]; }
}


########## END CODE ##########

=head1 BUGS AND LIMITATIONS

=over

=item * Unpacking DRM-protected text isn't supported.  Although
infrastructure may be added later to make use of external helpers and
plugins, direct DRM support will never be added to the main code for
legal reasons.

=item * Repacking a .prc without fully extracting to OPF and
completely converting back isn't supported.  This will have to be
implemented before an interface to perform minor metadata alterations
can be implemented.

=item * Mobipocket HUFF/CDIC decoding (used mostly on dictionaries)
isn't well documented.

=item * Not all Mobipocket data is understood, so a conversion from
OPF to Mobipocket .prc back to OPF will not result in all data being
retained.  Patches welcome.

=item * Mobipocket INDX, DATP, FCIS, and FLIS records are not
understood and are completely ignored

=item * Mobipocket EXTH subjectcode records may not end up attached to
the correct subject element if the number of subject records differs
from the number of subjectcode records.  This is because the
Mobipocket format leaves the EXTH subjectcode records completely
unlinked from the subject records, and there is no way to detect if a
subject with no associated subjectcode comes before a subject with an
associated subjectcode.

Fortunately, this should rarely be a problem with real data, as
Mobipocket Creator only allows a single subject to be set, and the
only other way to have a subjectcode attached to a subject is to
manually edit the OPF file and insert an additional dc:Subject element
with a BASICCode attribute.

Mobipocket has indicated that they may move data currently in their
custom elements and attributes to the standard <meta> elements in a
future release, so this problem may become moot then.

=back

=head1 AUTHOR

Zed Pobre <zed@debian.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2008 Zed Pobre

Licensed to the public under the terms of the GNU GPL, version 2

=cut

1;
