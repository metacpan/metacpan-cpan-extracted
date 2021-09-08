package HTML::HTML5::Parser::Charset::Info;
## skip Test::Tabs
use strict;
use warnings;
our $VERSION='0.992';

## TODO: Certain encodings MUST NOT be implemented [HTML5].

## ISSUE: Should we convert unassigned code point with trivial Unicode
## mapping into U+FFFD?  Or, should we return that Unicode character
## with an error?  (For example, Windows-1252's 0x81 should be converted
## to U+FFFD or U+0081?)

sub UNREGISTERED_CHARSET_NAME () { 0b1 }
    ## Names for non-standard encodings/implementations for Perl encodings
sub REGISTERED_CHARSET_NAME () { 0b10 }
    ## Names for standard encodings for Perl encodings
sub PRIMARY_CHARSET_NAME () { 0b100 }
    ## "Name:" field for IANA names
    ## Canonical name for Perl encodings
sub PREFERRED_CHARSET_NAME () { 0b1000 }
    ## "preferred MIME name" for IANA names

sub FALLBACK_ENCODING_IMPL () { 0b10000 }
    ## For Perl encodings: Not a name of the encoding, the encoding
    ## for the name might be useful as a fallback when the correct
    ## encoding is not supported.
sub NONCONFORMING_ENCODING_IMPL () { FALLBACK_ENCODING_IMPL }
    ## For Perl encodings: Not a conforming implementation of the encoding,
    ## though it seems that the intention was to implement that encoding.
sub SEMICONFORMING_ENCODING_IMPL () { 0b1000000 }
    ## For Perl encodings: The implementation itself (returned by
    ## |get_perl_encoding|) is non-conforming.  The decode handle
    ## implementation (returned by |get_decode_handle|) is conforming.
sub ERROR_REPORTING_ENCODING_IMPL () { 0b100000 }
    ## For Perl encodings: Support error reporting via |manakai_onerror|
    ## handler when the encoding is handled with decode handle.

## iana_status
sub STATUS_COMMON () { 0b1 }
sub STATUS_LIMITED_USE () { 0b10 }
sub STATUS_OBSOLETE () { 0b100 }

## category
sub CHARSET_CATEGORY_BLOCK_SAFE () { 0b1 }
    ## NOTE: Stateless
sub CHARSET_CATEGORY_EUCJP () { 0b10 }
sub CHARSET_CATEGORY_SJIS () { 0b100 }
sub CHARSET_CATEGORY_UTF16 () { 0b1000 }
    ## NOTE: "A UTF-16 encoding" in HTML5.
sub CHARSET_CATEGORY_ASCII_COMPAT () { 0b10000 }
    ## NOTE: "superset of US-ASCII (specifically, ANSI_X3.4-1968)
    ## for bytes in the range 0x09-0x0A, 0x0C-0x0D, 0x20-0x22, 0x26, 0x27,
    ## 0x2C-0x3F, 0x41-0x5A, and 0x61-0x7A" [HTML5]
sub CHARSET_CATEGORY_EBCDIC () { 0b100000 }
    ## NOTE: "based on EBCDIC" in HTML5.
sub CHARSET_CATEGORY_MIME_TEXT () { 0b1000000 }
    ## NOTE: Suitable as MIME text.

## ISSUE: Shift_JIS is a superset of US-ASCII?  ISO-2022-JP is?
## ISSUE: 0x5F (_) should be added to the range?

my $Charset; ## TODO: this is obsolete.

our $IANACharset;
    ## NOTE: Charset names used where IANA charset names are allowed, either
    ## registered or not.
our $HTMLCharset;
    ## NOTE: Same as charset names in $IANACharset, except all ASCII
    ## punctuations are dropped and letters/digits only names are not included.

$Charset->{'us-ascii'}
= $IANACharset->{'ansi_x3.4-1968'}
= $IANACharset->{'iso-ir-6'}
= $IANACharset->{'ansi_x3.4-1986'}
= $IANACharset->{'iso_646.irv:1991'}
= $IANACharset->{'ascii'}
= $IANACharset->{'iso646-us'}
= $IANACharset->{'us-ascii'}
= $IANACharset->{'us'}
= $IANACharset->{'ibm367'}
= $IANACharset->{'cp367'}
= $IANACharset->{'csascii'}
= $HTMLCharset->{'ansix341968'}
= $HTMLCharset->{'isoir6'}
= $HTMLCharset->{'ansix341986'}
= $HTMLCharset->{'iso646irv1991'}
= $HTMLCharset->{'iso646us'}
= $HTMLCharset->{'usascii'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_ASCII_COMPAT,
  iana_names => {
    'ansi_x3.4-1968' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'iso-ir-6' => REGISTERED_CHARSET_NAME,
    'ansi_x3.4-1986' => REGISTERED_CHARSET_NAME,
    'iso_646.irv:1991' => REGISTERED_CHARSET_NAME,
    'ascii' => REGISTERED_CHARSET_NAME,
    'iso646-us' => REGISTERED_CHARSET_NAME,
    'us-ascii' => PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'us' => REGISTERED_CHARSET_NAME,
    'ibm367' => REGISTERED_CHARSET_NAME,
    'cp367' => REGISTERED_CHARSET_NAME,
    'csascii' => REGISTERED_CHARSET_NAME,
  },
  perl_names => {
    'web-latin1-us-ascii' => UNREGISTERED_CHARSET_NAME |
        SEMICONFORMING_ENCODING_IMPL | ERROR_REPORTING_ENCODING_IMPL,
    'cp1252' => FALLBACK_ENCODING_IMPL, # part of standard Perl distribution
  },
  fallback => {
    "\x80" => "\x{20AC}",
    "\x81" => undef,
    "\x82" => "\x{201A}",
    "\x83" => "\x{0192}",
    "\x84" => "\x{201E}",
    "\x85" => "\x{2026}",
    "\x86" => "\x{2020}",
    "\x87" => "\x{2021}",
    "\x88" => "\x{02C6}",
    "\x89" => "\x{2030}",
    "\x8A" => "\x{0160}",
    "\x8B" => "\x{2039}",
    "\x8C" => "\x{0152}",
    "\x8D" => undef,
    "\x8E" => "\x{017D}",
    "\x8F" => undef,
    "\x90" => undef,
    "\x91" => "\x{2018}",
    "\x92" => "\x{2019}",
    "\x93" => "\x{201C}",
    "\x94" => "\x{201D}",
    "\x95" => "\x{2022}",
    "\x96" => "\x{2013}",
    "\x97" => "\x{2014}",
    "\x98" => "\x{02DC}",
    "\x99" => "\x{2122}",
    "\x9A" => "\x{0161}",
    "\x9B" => "\x{203A}",
    "\x9C" => "\x{0153}",
    "\x9D" => undef,
    "\x9E" => "\x{017E}",
    "\x9F" => "\x{0178}",
    "\xA0" => "\xA0", "\xA1" => "\xA1", "\xA2" => "\xA2", "\xA3" => "\xA3",
    "\xA4" => "\xA4", "\xA5" => "\xA5", "\xA6" => "\xA6", "\xA7" => "\xA7",
    "\xA8" => "\xA8", "\xA9" => "\xA9", "\xAA" => "\xAA", "\xAB" => "\xAB",
    "\xAC" => "\xAC", "\xAD" => "\xAD", "\xAE" => "\xAE", "\xAF" => "\xAF",
    "\xB0" => "\xB0", "\xB1" => "\xB1", "\xB2" => "\xB2", "\xB3" => "\xB3",
    "\xB4" => "\xB4", "\xB5" => "\xB5", "\xB6" => "\xB6", "\xB7" => "\xB7",
    "\xB8" => "\xB8", "\xB9" => "\xB9", "\xBA" => "\xBA", "\xBB" => "\xBB",
    "\xBC" => "\xBC", "\xBD" => "\xBD", "\xBE" => "\xBE", "\xBF" => "\xBF",
    "\xC0" => "\xC0", "\xC1" => "\xC1", "\xC2" => "\xC2", "\xC3" => "\xC3",
    "\xC4" => "\xC4", "\xC5" => "\xC5", "\xC6" => "\xC6", "\xC7" => "\xC7",
    "\xC8" => "\xC8", "\xC9" => "\xC9", "\xCA" => "\xCA", "\xCB" => "\xCB",
    "\xCC" => "\xCC", "\xCD" => "\xCD", "\xCE" => "\xCE", "\xCF" => "\xCF",
    "\xD0" => "\xD0", "\xD1" => "\xD1", "\xD2" => "\xD2", "\xD3" => "\xD3",
    "\xD4" => "\xD4", "\xD5" => "\xD5", "\xD6" => "\xD6", "\xD7" => "\xD7",
    "\xD8" => "\xD8", "\xD9" => "\xD9", "\xDA" => "\xDA", "\xDB" => "\xDB",
    "\xDC" => "\xDC", "\xDD" => "\xDD", "\xDE" => "\xDE", "\xDF" => "\xDF",
    "\xE0" => "\xE0", "\xE1" => "\xE1", "\xE2" => "\xE2", "\xE3" => "\xE3",
    "\xE4" => "\xE4", "\xE5" => "\xE5", "\xE6" => "\xE6", "\xE7" => "\xE7",
    "\xE8" => "\xE8", "\xE9" => "\xE9", "\xEA" => "\xEA", "\xEB" => "\xEB",
    "\xEC" => "\xEC", "\xED" => "\xED", "\xEE" => "\xEE", "\xEF" => "\xEF",
    "\xF0" => "\xF0", "\xF1" => "\xF1", "\xF2" => "\xF2", "\xF3" => "\xF3",
    "\xF4" => "\xF4", "\xF5" => "\xF5", "\xF6" => "\xF6", "\xF7" => "\xF7",
    "\xF8" => "\xF8", "\xF9" => "\xF9", "\xFA" => "\xFA", "\xFB" => "\xFB",
    "\xFC" => "\xFC", "\xFD" => "\xFD", "\xFE" => "\xFE", "\xFF" => "\xFF",
  },
  ## NOTE: Treated as |windows-1252|.  Properties of this charset
  ## should be consistent with those of that charset.
});

$Charset->{'iso-8859-1'}
= $IANACharset->{'iso_8859-1:1987'}
= $IANACharset->{'iso-ir-100'}
= $IANACharset->{'iso_8859-1'}
= $IANACharset->{'iso-8859-1'}
= $IANACharset->{'latin1'}
= $IANACharset->{'l1'}
= $IANACharset->{'ibm819'}
= $IANACharset->{'cp819'}
= $IANACharset->{'csisolatin1'}
= $HTMLCharset->{'iso885911987'}
= $HTMLCharset->{'isoir100'}
= $HTMLCharset->{'iso88591'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_ASCII_COMPAT,
  iana_names => {
    'iso_8859-1:1987' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'iso-ir-100' => REGISTERED_CHARSET_NAME,
    'iso_8859-1' => REGISTERED_CHARSET_NAME,
    'iso-8859-1' => PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'latin1' => REGISTERED_CHARSET_NAME,
    'l1' => REGISTERED_CHARSET_NAME,
    'ibm819' => REGISTERED_CHARSET_NAME,
    'cp819' => REGISTERED_CHARSET_NAME,
    'csisolatin1' => REGISTERED_CHARSET_NAME,
  },
  perl_names => {
    'web-latin1' => UNREGISTERED_CHARSET_NAME | SEMICONFORMING_ENCODING_IMPL |
        ERROR_REPORTING_ENCODING_IMPL,
    'cp1252' => FALLBACK_ENCODING_IMPL, # part of standard Perl distribution
  },
  fallback => {
    "\x80" => "\x{20AC}",
    "\x81" => undef,
    "\x82" => "\x{201A}",
    "\x83" => "\x{0192}",
    "\x84" => "\x{201E}",
    "\x85" => "\x{2026}",
    "\x86" => "\x{2020}",
    "\x87" => "\x{2021}",
    "\x88" => "\x{02C6}",
    "\x89" => "\x{2030}",
    "\x8A" => "\x{0160}",
    "\x8B" => "\x{2039}",
    "\x8C" => "\x{0152}",
    "\x8D" => undef,
    "\x8E" => "\x{017D}",
    "\x8F" => undef,
    "\x90" => undef,
    "\x91" => "\x{2018}",
    "\x92" => "\x{2019}",
    "\x93" => "\x{201C}",
    "\x94" => "\x{201D}",
    "\x95" => "\x{2022}",
    "\x96" => "\x{2013}",
    "\x97" => "\x{2014}",
    "\x98" => "\x{02DC}",
    "\x99" => "\x{2122}",
    "\x9A" => "\x{0161}",
    "\x9B" => "\x{203A}",
    "\x9C" => "\x{0153}",
    "\x9D" => undef,
    "\x9E" => "\x{017E}",
    "\x9F" => "\x{0178}",
  },
  ## NOTE: Treated as |windows-1252|.  Properties of this charset
  ## should be consistent with those of that charset.
});

$Charset->{'iso-8859-2'}
= $IANACharset->{'iso_8859-2:1987'}
= $IANACharset->{'iso-ir-101'}
= $IANACharset->{'iso_8859-2'}
= $IANACharset->{'iso-8859-2'}
= $IANACharset->{'latin2'}
= $IANACharset->{'l2'}
= $IANACharset->{'csisolatin2'}
= $HTMLCharset->{'iso885921987'}
= $HTMLCharset->{'isoir101'}
= $HTMLCharset->{'iso88592'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_ASCII_COMPAT,
  iana_names => {
    'iso_8859-2:1987' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'iso-ir-101' => REGISTERED_CHARSET_NAME,
    'iso_8859-2' => REGISTERED_CHARSET_NAME,
    'iso-8859-2' => PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'latin2' => REGISTERED_CHARSET_NAME,
    'l2' => REGISTERED_CHARSET_NAME,
    'csisolatin2' => REGISTERED_CHARSET_NAME,
  },
});

$Charset->{'iso-8859-3'}
= $IANACharset->{'iso_8859-3:1988'}
= $IANACharset->{'iso-ir-109'}
= $IANACharset->{'iso_8859-3'}
= $IANACharset->{'iso-8859-3'}
= $IANACharset->{'latin3'}
= $IANACharset->{'l3'}
= $IANACharset->{'csisolatin3'}
= $HTMLCharset->{'iso885931988'}
= $HTMLCharset->{'isoir109'}
= $HTMLCharset->{'iso88593'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_ASCII_COMPAT,
  iana_names => {
    'iso_8859-3:1988' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'iso-ir-109' => REGISTERED_CHARSET_NAME,
    'iso_8859-3' => REGISTERED_CHARSET_NAME,
    'iso-8859-3' => PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'latin3' => REGISTERED_CHARSET_NAME,
    'l3' => REGISTERED_CHARSET_NAME,
    'csisolatin3' => REGISTERED_CHARSET_NAME,
  },
  error_level => {
    'unassigned-code-point-error' => 'iso_shall',
        ## NOTE: I didn't check whether ISO/IEC 8859-3 prohibits the use of
        ## unassigned code points, but ECMA-94:1986 (whose content considered
        ## as equivalent to ISO 8859/1-4) disallows the use of them.
  },
});

$Charset->{'iso-8859-4'}
= $IANACharset->{'iso_8859-4:1988'}
= $IANACharset->{'iso-ir-110'}
= $IANACharset->{'iso_8859-4'}
= $IANACharset->{'iso-8859-4'}
= $IANACharset->{'latin4'}
= $IANACharset->{'l4'}
= $IANACharset->{'csisolatin4'}
= $HTMLCharset->{'iso885941988'}
= $HTMLCharset->{'isoir110'}
= $HTMLCharset->{'iso88594'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_ASCII_COMPAT,
  iana_names => {
    'iso_8859-4:1988' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'iso-ir-110' => REGISTERED_CHARSET_NAME,
    'iso_8859-4' => REGISTERED_CHARSET_NAME,
    'iso-8859-4' => PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'latin4' => REGISTERED_CHARSET_NAME,
    'l4' => REGISTERED_CHARSET_NAME,
    'csisolatin4' => REGISTERED_CHARSET_NAME,
  },
  error_level => {
    'unassigned-code-point-error' => 'iso_shall',
        ## NOTE: I didn't check whether ISO/IEC 8859-3 prohibits the use of
        ## unassigned code points, but ECMA-94:1986 (whose content considered
        ## as equivalent to ISO 8859/1-4) disallows the use of them.
  },
});

$Charset->{'iso-8859-5'}
= $IANACharset->{'iso_8859-5:1988'}
= $IANACharset->{'iso-ir-144'}
= $IANACharset->{'iso_8859-5'}
= $IANACharset->{'iso-8859-5'}
= $IANACharset->{'cyrillic'}
= $IANACharset->{'csisolatincyrillic'}
= $HTMLCharset->{'iso885951988'}
= $HTMLCharset->{'isoir144'}
= $HTMLCharset->{'iso88595'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_ASCII_COMPAT,
  iana_names => {
    'iso_8859-5:1988' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'iso-ir-144' => REGISTERED_CHARSET_NAME,
    'iso_8859-5' => REGISTERED_CHARSET_NAME,
    'iso-8859-5' => PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'cyrillic' => REGISTERED_CHARSET_NAME,
    'csisolatincyrillic' => REGISTERED_CHARSET_NAME,
  },
});

$Charset->{'iso-8859-6'}
= $IANACharset->{'iso_8859-6:1987'}
= $IANACharset->{'iso-ir-127'}
= $IANACharset->{'iso_8859-6'}
= $IANACharset->{'iso-8859-6'}
= $IANACharset->{'ecma-114'}
= $IANACharset->{'asmo-708'}
= $IANACharset->{'arabic'}
= $IANACharset->{'csisolatinarabic'}
= $HTMLCharset->{'iso885961987'}
= $HTMLCharset->{'isoir127'}
= $HTMLCharset->{'iso88596'}
= $HTMLCharset->{'ecma114'}
= $HTMLCharset->{'asmo708'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_ASCII_COMPAT,
      ## NOTE: 3/0..3/9 have different semantics from U+0030..0039,
      ## but have same character names (maybe).
      ## NOTE: According to RFC 2046, charset left-hand half of "iso-8859-6"
      ## is same as "us-ascii".
## TODO: RFC 1345 def?
  iana_names => {
    'iso_8859-6:1987' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'iso-ir-127' => REGISTERED_CHARSET_NAME,
    'iso_8859-6' => REGISTERED_CHARSET_NAME,
    'iso-8859-6' => PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'ecma-114' => REGISTERED_CHARSET_NAME,
    'asmo-708' => REGISTERED_CHARSET_NAME,
    'arabic' => REGISTERED_CHARSET_NAME,
    'csisolatinarabic' => REGISTERED_CHARSET_NAME,
  },
  ## TODO: |error_level|
});

$Charset->{'iso-8859-7'}
= $IANACharset->{'iso_8859-7:1987'}
= $IANACharset->{'iso-ir-126'}
= $IANACharset->{'iso_8859-7'}
= $IANACharset->{'iso-8859-7'}
= $IANACharset->{'elot_928'}
= $IANACharset->{'ecma-118'}
= $IANACharset->{'greek'}
= $IANACharset->{'greek8'}
= $IANACharset->{'csisolatingreek'}
= $HTMLCharset->{'iso885971987'}
= $HTMLCharset->{'isoir126'}
= $HTMLCharset->{'iso88597'}
= $HTMLCharset->{'elot928'}
= $HTMLCharset->{'ecma118'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_ASCII_COMPAT,
  iana_names => {
    'iso_8859-7:1987' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'iso-ir-126' => REGISTERED_CHARSET_NAME,
    'iso_8859-7' => REGISTERED_CHARSET_NAME,
    'iso-8859-7' => PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'elot_928' => REGISTERED_CHARSET_NAME,
    'ecma-118' => REGISTERED_CHARSET_NAME,
    'greek' => REGISTERED_CHARSET_NAME,
    'greek8' => REGISTERED_CHARSET_NAME,
    'csisolatingreek' => REGISTERED_CHARSET_NAME,
  },
  ## TODO: |error_level|
});

$Charset->{'iso-8859-8'}
= $IANACharset->{'iso_8859-8:1988'}
= $IANACharset->{'iso-ir-138'}
= $IANACharset->{'iso_8859-8'}
= $IANACharset->{'iso-8859-8'}
= $IANACharset->{'hebrew'}
= $IANACharset->{'csisolatinhebrew'}
= $HTMLCharset->{'iso885981988'}
= $HTMLCharset->{'isoir138'}
= $HTMLCharset->{'iso88598'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_ASCII_COMPAT,
  iana_names => {
    'iso_8859-8:1988' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'iso-ir-138' => REGISTERED_CHARSET_NAME,
    'iso_8859-8' => REGISTERED_CHARSET_NAME,
    'iso-8859-8' => PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'hebrew' => REGISTERED_CHARSET_NAME,
    'csisolatinhebrew' => REGISTERED_CHARSET_NAME,
  },
  ## TODO: |error_level|
});

$Charset->{'iso-8859-9'}
= $IANACharset->{'iso_8859-9:1989'}
= $IANACharset->{'iso-ir-148'}
= $IANACharset->{'iso_8859-9'}
= $IANACharset->{'iso-8859-9'}
= $IANACharset->{'latin5'}
= $IANACharset->{'l5'}
= $IANACharset->{'csisolatin5'}
= $HTMLCharset->{'iso885991989'}
= $HTMLCharset->{'isoir148'}
= $HTMLCharset->{'iso88599'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_ASCII_COMPAT,
  iana_names => {
    'iso_8859-9:1989' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'iso-ir-148' => REGISTERED_CHARSET_NAME,
    'iso_8859-9' => REGISTERED_CHARSET_NAME,
    'iso-8859-9' => PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'latin5' => REGISTERED_CHARSET_NAME,
    'l5' => REGISTERED_CHARSET_NAME,
    'csisolatin5' => REGISTERED_CHARSET_NAME,
  },
  perl_names => {
    'web-latin5' => UNREGISTERED_CHARSET_NAME | SEMICONFORMING_ENCODING_IMPL |
        ERROR_REPORTING_ENCODING_IMPL,
    'cp1254' => FALLBACK_ENCODING_IMPL, # part of standard Perl distribution
  },
  fallback => {
    "\x80" => "\x{20AC}",
    "\x81" => undef,
    "\x82" => "\x{201A}",
    "\x83" => "\x{0192}",
    "\x84" => "\x{201E}",
    "\x85" => "\x{2026}",
    "\x86" => "\x{2020}",
    "\x87" => "\x{2021}",
    "\x88" => "\x{02C6}",
    "\x89" => "\x{2030}",
    "\x8A" => "\x{0160}",
    "\x8B" => "\x{2039}",
    "\x8C" => "\x{0152}",
    "\x8D" => undef,
    "\x8E" => undef,
    "\x8F" => undef,
    "\x90" => undef,
    "\x91" => "\x{2018}",
    "\x92" => "\x{2019}",
    "\x93" => "\x{201C}",
    "\x94" => "\x{201D}",
    "\x95" => "\x{2022}",
    "\x96" => "\x{2013}",
    "\x97" => "\x{2014}",
    "\x98" => "\x{02DC}",
    "\x99" => "\x{2122}",
    "\x9A" => "\x{0161}",
    "\x9B" => "\x{203A}",
    "\x9C" => "\x{0153}",
    "\x9D" => undef,
    "\x9E" => undef,
    "\x9F" => "\x{0178}",
  },
  ## NOTE: Treated as |windows-1254|.  Properties of this charset
  ## should be consistent with those of that charset.
});

$Charset->{'iso-8859-10'}
= $IANACharset->{'iso-8859-10'}
= $IANACharset->{'iso-ir-157'}
= $IANACharset->{'l6'}
= $IANACharset->{'iso_8859-10:1992'}
= $IANACharset->{'csisolatin6'}
= $IANACharset->{'latin6'}
= $HTMLCharset->{'iso885910'}
= $HTMLCharset->{'isoir157'}
= $HTMLCharset->{'iso8859101992'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_ASCII_COMPAT,
  iana_names => {
    'iso-8859-10' => PRIMARY_CHARSET_NAME | PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'iso-ir-157' => REGISTERED_CHARSET_NAME,
    'l6' => REGISTERED_CHARSET_NAME,
    'iso_8859-10:1992' => REGISTERED_CHARSET_NAME,
    'csisolatin6' => REGISTERED_CHARSET_NAME,
    'latin6' => REGISTERED_CHARSET_NAME,
  },
  ## TODO: |error_level|
});

$Charset->{'iso_6937-2-add'}
= $IANACharset->{'iso_6937-2-add'}
= $IANACharset->{'iso-ir-142'}
= $IANACharset->{'csisotextcomm'}
= $HTMLCharset->{'iso69372add'}
= $HTMLCharset->{'isoir142'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_ASCII_COMPAT,
  iana_names => {
    'iso_6937-2-add' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'iso-ir-142' => REGISTERED_CHARSET_NAME,
    'csisotextcomm' => REGISTERED_CHARSET_NAME,
  },
  ## TODO: |error_level|
});

$Charset->{'jis_x0201'}
= $IANACharset->{'jis_x0201'}
= $IANACharset->{'x0201'}
= $IANACharset->{'cshalfwidthkatakana'}
= $HTMLCharset->{'jisx0201'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_ASCII_COMPAT,
  iana_names => {
    'jis_x0201' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'x0201' => REGISTERED_CHARSET_NAME,
    'cshalfwidthkatakana' => REGISTERED_CHARSET_NAME,
  },
  ## TODO: |error_level|
});

$Charset->{'jis_encoding'}
= $IANACharset->{'jis_encoding'}
= $IANACharset->{'csjisencoding'}
= $HTMLCharset->{'jisencoding'}
= __PACKAGE__->new ({
  category => 0,
  iana_names => {
    'jis_encoding' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'csjisencoding' => REGISTERED_CHARSET_NAME,
  },
  ## NOTE: What is this?
});

$Charset->{'shift_jis'}
= $IANACharset->{'shift_jis'}
= $IANACharset->{'ms_kanji'}
= $IANACharset->{'csshiftjis'}
= $HTMLCharset->{'shiftjis'}
= $HTMLCharset->{'mskanji'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_SJIS | CHARSET_CATEGORY_BLOCK_SAFE |
      CHARSET_CATEGORY_MIME_TEXT | CHARSET_CATEGORY_ASCII_COMPAT,
  iana_names => {
    'shift_jis' => PREFERRED_CHARSET_NAME | PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'ms_kanji' => REGISTERED_CHARSET_NAME,
    'csshiftjis' => REGISTERED_CHARSET_NAME,
  },
  perl_names => {
    'shift-jis-1997' => UNREGISTERED_CHARSET_NAME |
        SEMICONFORMING_ENCODING_IMPL | ERROR_REPORTING_ENCODING_IMPL,
    shiftjis => PRIMARY_CHARSET_NAME | NONCONFORMING_ENCODING_IMPL |
        ERROR_REPORTING_ENCODING_IMPL,
        ## NOTE: Unicode mapping is wrong.
  },
  ## TODO: |error_level|
});

$Charset->{'x-sjis'}
= $IANACharset->{'x-sjis'}
= $HTMLCharset->{'xsjis'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_SJIS | CHARSET_CATEGORY_BLOCK_SAFE |
      CHARSET_CATEGORY_ASCII_COMPAT,
  iana_names => {
    'x-sjis' => UNREGISTERED_CHARSET_NAME,
  },
  perl_names => {
    'shift-jis-1997' => FALLBACK_ENCODING_IMPL | ERROR_REPORTING_ENCODING_IMPL,
  },
  ## TODO: |error_level|
});

$Charset->{shift_jisx0213}
= $IANACharset->{shift_jisx0213}
= $HTMLCharset->{shiftjisx0213}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_SJIS | CHARSET_CATEGORY_BLOCK_SAFE |
      CHARSET_CATEGORY_MIME_TEXT,
  iana_names => {
    shift_jisx0213 => UNREGISTERED_CHARSET_NAME,
  },
  perl_names => {
    #shift_jisx0213 (non-standard - i don't know its conformance)
    'shift-jis-1997' => FALLBACK_ENCODING_IMPL | ERROR_REPORTING_ENCODING_IMPL,
    'shiftjis' => FALLBACK_ENCODING_IMPL | ERROR_REPORTING_ENCODING_IMPL,
  },
  ## TODO: |error_level|
});

$Charset->{'euc-jp'}
= $IANACharset->{'extended_unix_code_packed_format_for_japanese'}
= $IANACharset->{'cseucpkdfmtjapanese'}
= $IANACharset->{'euc-jp'}
= $HTMLCharset->{'extendedunixcodepackedformatforjapanese'}
= $HTMLCharset->{'cseucpkdfmtjapanese'}
= $HTMLCharset->{'eucjp'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_EUCJP | CHARSET_CATEGORY_BLOCK_SAFE |
      CHARSET_CATEGORY_MIME_TEXT | CHARSET_CATEGORY_ASCII_COMPAT,
  iana_names => {
    'extended_unix_code_packed_format_for_japanese' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'cseucpkdfmtjapanese' => REGISTERED_CHARSET_NAME,
    'euc-jp' => PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
  },
  perl_names => {
    'euc-jp-1997' => UNREGISTERED_CHARSET_NAME |
        SEMICONFORMING_ENCODING_IMPL | ERROR_REPORTING_ENCODING_IMPL,
        ## NOTE: Though the IANA definition references the 1990 version
        ## of EUC-JP, the 1997 version of JIS standard claims that the version
        ## is same coded character set as the 1990 version, such that we
        ## consider the EUC-JP 1990 version is same as the 1997 version.
    'euc-jp' => PREFERRED_CHARSET_NAME | NONCONFORMING_ENCODING_IMPL |
        ERROR_REPORTING_ENCODING_IMPL,
        ## NOTE: Unicode mapping is wrong.
  },
  ## TODO: |error_level|
});

$Charset->{'x-euc-jp'}
= $IANACharset->{'x-euc-jp'}
= $HTMLCharset->{'xeucjp'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_EUCJP | CHARSET_CATEGORY_BLOCK_SAFE |
      CHARSET_CATEGORY_MIME_TEXT | CHARSET_CATEGORY_ASCII_COMPAT,
  iana_names => {
    'x-euc-jp' => UNREGISTERED_CHARSET_NAME,
  },
  perl_names => {
    'euc-jp-1997' => FALLBACK_ENCODING_IMPL | ERROR_REPORTING_ENCODING_IMPL,
    'euc-jp' => FALLBACK_ENCODING_IMPL | ERROR_REPORTING_ENCODING_IMPL,
  },
});

$Charset->{'extended_unix_code_fixed_width_for_japanese'}
= $IANACharset->{'extended_unix_code_fixed_width_for_japanese'}
= $IANACharset->{'cseucfixwidjapanese'}
= $HTMLCharset->{'extendedunixcodefixedwidthforjapanese'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE,
  iana_names => {
    'extended_unix_code_fixed_width_for_japanese' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'cseucfixwidjapanese' => REGISTERED_CHARSET_NAME,
  },
  ## TODO: |error_level|
});

## TODO: ...

$Charset->{'euc-kr'}
= $IANACharset->{'euc-kr'}
= $IANACharset->{'cseuckr'}
= $HTMLCharset->{'euckr'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_ASCII_COMPAT,
  iana_names => {
    'euc-kr' => PRIMARY_CHARSET_NAME | PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'cseuckr' => REGISTERED_CHARSET_NAME,
  },
  perl_names => {
    ## TODO: We need a parse error generating wrapper for the decoder.
    'cp949' => FALLBACK_ENCODING_IMPL, # part of standard Perl distribution
  },
  ## NOTE: |euc-kr| is handled as |windows-949|, such that properties 
  ## should be consistent with that encoding's properties.
});

$Charset->{'iso-2022-jp'}
= $IANACharset->{'iso-2022-jp'}
= $IANACharset->{'csiso2022jp'}
= $IANACharset->{'iso2022jp'}
= $IANACharset->{'junet-code'}
= $HTMLCharset->{'iso2022jp'}
= $HTMLCharset->{'junetcode'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_MIME_TEXT | CHARSET_CATEGORY_ASCII_COMPAT,
  iana_names => {
    'iso-2022-jp' => PREFERRED_CHARSET_NAME | PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'csiso2022jp' => REGISTERED_CHARSET_NAME,
    'iso2022jp' => UNREGISTERED_CHARSET_NAME,
    'junet-code' => UNREGISTERED_CHARSET_NAME,
  },
  ## TODO: |error_level|
});

$Charset->{'iso-2022-jp-2'}
= $IANACharset->{'iso-2022-jp-2'}
= $IANACharset->{'csiso2022jp2'}
= $HTMLCharset->{'iso2022jp2'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_MIME_TEXT,
  iana_names => {
    'iso-2022-jp-2' => PREFERRED_CHARSET_NAME | PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'csiso2022jp2' => REGISTERED_CHARSET_NAME,
  },
  ## TODO: |error_level|
});

## TODO: ...

$IANACharset->{'gb_2312-80'}
= $IANACharset->{'iso-ir-58'}
= $IANACharset->{chinese}
= $HTMLCharset->{gb231280}
= $HTMLCharset->{isoir58}
= __PACKAGE__->new ({
  ## NOTE: What is represented by this charset is unclear...  I don't 
  ## understand what RFC 1945 describes...
  category => 0,
  iana_names => {
    'gb_2312-80' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'iso-ir-58' => REGISTERED_CHARSET_NAME,
    'chinese' => REGISTERED_CHARSET_NAME,
    'csiso58gb231280' => REGISTERED_CHARSET_NAME,
  },
  perl_names => {
    ## TODO: GB2312->GBK Parse Error wrapper
    'cp936' => FALLBACK_ENCODING_IMPL,
  },
  ## NOTE: |gb2312| is handled as |gbk|, such that properties should be
  ## consistent.
});

## TODO: ...

$Charset->{'utf-8'}
= $IANACharset->{'utf-8'}
= $IANACharset->{'x-utf-8'}
= $HTMLCharset->{'utf8'}
= $HTMLCharset->{'xutf8'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_ASCII_COMPAT |
      CHARSET_CATEGORY_MIME_TEXT,
  iana_names => {
    'utf-8' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
        ## NOTE: IANA name "utf-8" references RFC 3629.  According to the RFC,
        ## the definitive definition is one specified in the Unicode Standard.
    'x-utf-8' => UNREGISTERED_CHARSET_NAME,
        ## NOTE: We treat |x-utf-8| as an alias of |utf-8|, since unlike
        ## other charset like |x-sjis| or |x-euc-jp|, there is no major
        ## variant for the UTF-8 encoding.
                 ## TODO: We might ought to reconsider this policy, since
                 ## there are UTF-8 variant in fact, such as 
                 ## Unicode's UTF-8, ISO/IEC 10646's UTF-8, UTF-8n, and as
                 ## such.
  },
  perl_names => {
    'utf-8-strict' => PRIMARY_CHARSET_NAME | SEMICONFORMING_ENCODING_IMPL |
        ERROR_REPORTING_ENCODING_IMPL,
        ## NOTE: It does not support non-Unicode UCS characters (conforming).
        ## It does detect illegal sequences (conforming).
        ## It does not support surrpgate pairs (conforming).
        ## It does not support BOMs (non-conforming).
  },
  ## TODO: |error_level|
  bom_pattern => qr/\xEF\xBB\xBF/,
});

$Charset->{'utf-8n'}
= $IANACharset->{'utf-8n'}
= $HTMLCharset->{'utf-8'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_MIME_TEXT |
      CHARSET_CATEGORY_ASCII_COMPAT,
  iana_names => {
    'utf-8n' => UNREGISTERED_CHARSET_NAME,
        ## NOTE: Is there any normative definition for the charset?
        ## What variant of UTF-8 should we use for the charset?
  },
  perl_names => {
    'utf-8-strict' => PRIMARY_CHARSET_NAME | ERROR_REPORTING_ENCODING_IMPL,
  },
  ## TODO: |error_level|
});

## TODO: ...

$Charset->{'gbk'}
= $IANACharset->{'gbk'}
= $IANACharset->{'cp936'}
= $IANACharset->{'ms936'}
= $IANACharset->{'windows-936'}
= $HTMLCharset->{'windows936'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_MIME_TEXT,
  iana_names => {
    'gbk' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'cp936' => REGISTERED_CHARSET_NAME,
    'ms936' => REGISTERED_CHARSET_NAME,
    'windows-936' => REGISTERED_CHARSET_NAME,
  },
  ## TODO: |error_level|
  iana_status => STATUS_COMMON | STATUS_OBSOLETE,
});

$Charset->{'gb18030'}
= $IANACharset->{'gb18030'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_MIME_TEXT,
  iana_names => {
    'gb18030' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
  },
  iana_status => STATUS_COMMON,
  mime_text_suitable => 1,
});

## TODO: ...

$Charset->{'utf-16be'}
= $IANACharset->{'utf-16be'}
= $HTMLCharset->{'utf16be'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_UTF16,
  iana_names => {
    'utf-16be' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
  },
  ## TODO: |error_level|
});

$Charset->{'utf-16le'}
= $IANACharset->{'utf-16le'}
= $HTMLCharset->{'utf16le'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_UTF16,
  iana_names => {
    'utf-16le' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
  },
  ## TODO: |error_level|
});

$Charset->{'utf-16'}
= $IANACharset->{'utf-16'}
= $HTMLCharset->{'utf16'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_UTF16,
  iana_names => {
    'utf-16' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
  },
  ## TODO: |error_level|
});

## TODO: ...

$Charset->{'windows-31j'}
= $IANACharset->{'windows-31j'}
= $IANACharset->{'cswindows31j'}
= $HTMLCharset->{'windows31j'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_SJIS | CHARSET_CATEGORY_BLOCK_SAFE |
      CHARSET_CATEGORY_MIME_TEXT,
  iana_names => {
    'windows-31j' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'cswindows31j' => REGISTERED_CHARSET_NAME,
  },
  iana_status => STATUS_LIMITED_USE, # maybe
  ## TODO: |error_level|
});

$Charset->{'gb2312'}
= $IANACharset->{'gb2312'}
= $IANACharset->{'csgb2312'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_MIME_TEXT |
      CHARSET_CATEGORY_ASCII_COMPAT,
  iana_names => {
    'gb2312' => PRIMARY_CHARSET_NAME | PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'csgb2312' => REGISTERED_CHARSET_NAME,
  },
  perl_names => {
    ## TODO: GB2312->GBK Parse Error wrapper
    'cp936' => FALLBACK_ENCODING_IMPL,
  },
  ## NOTE: |gb2312| is handled as |gbk|, such that properties should be
  ## consistent.
});

$Charset->{'big5'}
= $IANACharset->{'big5'}
= $IANACharset->{'csbig5'}
= $IANACharset->{'x-x-big5'}
= $HTMLCharset->{xxbig5}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_MIME_TEXT,
  iana_names => {
    'big5' => PRIMARY_CHARSET_NAME | PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME,
    'csbig5' => REGISTERED_CHARSET_NAME,
    'x-x-big5' => UNREGISTERED_CHARSET_NAME,
        ## NOTE: In HTML5, |x-x-big5| is defined as an alias of |big5|.
        ## According to that spec, if there is any difference between 
        ## input and replacement encodings, the result is parse error.
        ## However, since there is no formal definition for |x-x-big5|
        ## charset, we cannot raise such errors.
  },
  ## TODO: |error_level|
});

## TODO: ...

$Charset->{'big5-hkscs'}
= $IANACharset->{'big5-hkscs'}
= $HTMLCharset->{'big5hkscs'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_MIME_TEXT,
  iana_names => {
    'big5-hkscs' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
  },
  ## TODO: |error_level|
});

## TODO: ...

$Charset->{'windows-1252'}
= $IANACharset->{'windows-1252'}
= $HTMLCharset->{'windows1252'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_ASCII_COMPAT |
      CHARSET_CATEGORY_MIME_TEXT,
  iana_names => {
    'windows-1252' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
  },
  ## TODO: Check whether use of 0x81 is conforming or not...
});

$Charset->{'windows-1253'}
= $IANACharset->{'windows-1253'}
= $HTMLCharset->{'windows1253'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_ASCII_COMPAT |
      CHARSET_CATEGORY_MIME_TEXT,
  iana_names => {
    'windows-1253' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
  },
  ## TODO: Check whether use of 0x81 is conforming or not...
});

$Charset->{'windows-1254'}
= $IANACharset->{'windows-1254'}
= $HTMLCharset->{'windows1254'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_ASCII_COMPAT |
      CHARSET_CATEGORY_MIME_TEXT,
  iana_names => {
    'windows-1254' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
  },
  ## TODO: Check whether use of 0x81 is conforming or not...
});

## TODO: ...

$Charset->{'tis-620'}
= $IANACharset->{'tis-620'}
= $HTMLCharset->{'tis620'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_ASCII_COMPAT,
  iana_names => {
    'tis-620' => PRIMARY_CHARSET_NAME | REGISTERED_CHARSET_NAME,
  },
  perl_names => {
    'web-tis-620' => UNREGISTERED_CHARSET_NAME | ERROR_REPORTING_ENCODING_IMPL,
    'windows-874' => FALLBACK_ENCODING_IMPL | ERROR_REPORTING_ENCODING_IMPL,
  },
  fallback => {
    "\x80" => "\x{20AC}",
    "\x81" => undef, "\x82" => undef, "\x83" => undef, "\x84" => undef,
    "\x85" => "\x{2026}",
    "\x86" => undef, "\x87" => undef, "\x88" => undef, "\x89" => undef,
    "\x8A" => undef, "\x8B" => undef, "\x8C" => undef, "\x8D" => undef,
    "\x8E" => undef, "\x8F" => undef, "\x90" => undef,
    "\x91" => "\x{2018}",
    "\x92" => "\x{2019}",
    "\x93" => "\x{201C}",
    "\x94" => "\x{201D}",
    "\x95" => "\x{2022}",
    "\x96" => "\x{2013}",
    "\x97" => "\x{2014}",
    "\x98" => undef, "\x99" => undef, "\x9A" => undef, "\x9B" => undef,
    "\x9C" => undef, "\x9D" => undef, "\x9E" => undef, "\x9F" => undef,
    "\xA0" => "\xA0",
  },
  ## NOTE: |tis-620| is treated as |windows-874|, so ensure that
  ## they are consistent.
});

$Charset->{'iso-8859-11'}
= $IANACharset->{'iso-8859-11'}
= $HTMLCharset->{'iso885911'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_ASCII_COMPAT,
  iana_names => {
    'iso-8859-11' => UNREGISTERED_CHARSET_NAME,
        ## NOTE: The Web Thai encoding, i.e. windows-874.
  },
  perl_names => {
    'web-thai' => UNREGISTERED_CHARSET_NAME | ERROR_REPORTING_ENCODING_IMPL,
    'windows-874' => FALLBACK_ENCODING_IMPL | ERROR_REPORTING_ENCODING_IMPL,
  },
  fallback => {
    "\x80" => "\x{20AC}",
    "\x81" => undef, "\x82" => undef, "\x83" => undef, "\x84" => undef,
    "\x85" => "\x{2026}",
    "\x86" => undef, "\x87" => undef, "\x88" => undef, "\x89" => undef,
    "\x8A" => undef, "\x8B" => undef, "\x8C" => undef, "\x8D" => undef,
    "\x8E" => undef, "\x8F" => undef, "\x90" => undef,
    "\x91" => "\x{2018}",
    "\x92" => "\x{2019}",
    "\x93" => "\x{201C}",
    "\x94" => "\x{201D}",
    "\x95" => "\x{2022}",
    "\x96" => "\x{2013}",
    "\x97" => "\x{2014}",
    "\x98" => undef, "\x99" => undef, "\x9A" => undef, "\x9B" => undef,
    "\x9C" => undef, "\x9D" => undef, "\x9E" => undef, "\x9F" => undef,
  },
  ## NOTE: |iso-8859-11| is treated as |windows-874|, so ensure that
  ## they are consistent.
});

$Charset->{'windows-874'}
= $IANACharset->{'windows-874'}
= $HTMLCharset->{'windows874'}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_ASCII_COMPAT,
  iana_names => {
    'windows-874' => UNREGISTERED_CHARSET_NAME,
  },
  perl_names => {
    'windows-874' => REGISTERED_CHARSET_NAME | ERROR_REPORTING_ENCODING_IMPL,
  },
  ## TODO: |error_level|
});

$IANACharset->{'windows-949'}
= $HTMLCharset->{windows949}
= __PACKAGE__->new ({
  category => CHARSET_CATEGORY_BLOCK_SAFE | CHARSET_CATEGORY_MIME_TEXT,
  iana_names => {
    'windows-949' => UNREGISTERED_CHARSET_NAME,
  },
  perl_names => {
    'cp949' => PREFERRED_CHARSET_NAME | NONCONFORMING_ENCODING_IMPL |
        ERROR_REPORTING_ENCODING_IMPL,
        ## TODO: Is this implementation conforming?
  },
  ## NOTE: |error_level| is same as default, since we can't find any formal
  ## definition for this charset.
});

sub new ($$) {
  return bless $_[1], $_[0];
} # new

## NOTE: A class method
sub get_by_html_name ($$) {
  my $name = $_[1];
  $name =~ tr/A-Z/a-z/; ## ASCII case-insensitive
  my $iana_name = $name;
  $name =~ s/[\x09-\x0D\x20-\x2F\x3A-\x40\x5B-\x60\x7B-\x7E]//g;
      ## NOTE: U+000B is included.
  unless ($HTMLCharset->{$name} || $IANACharset->{$name}) {
    $IANACharset->{$iana_name} =
    $HTMLCharset->{$name} = __PACKAGE__->new ({
      iana_names => {
        $iana_name => UNREGISTERED_CHARSET_NAME,
      },
    });
  }
  return $HTMLCharset->{$name} || $IANACharset->{$name};
} # get_by_html_name

## NOTE: A class method
sub get_by_iana_name ($$) {
  my $name = $_[1];
  $name =~ tr/A-Z/a-z/; ## ASCII case-insensitive
  unless ($IANACharset->{$name}) {
    $IANACharset->{$name} = __PACKAGE__->new ({
      iana_names => {
        $name => UNREGISTERED_CHARSET_NAME,
      },
    });
  }
  return $IANACharset->{$name};
} # get_by_iana_name

sub get_decode_handle ($$;%) {
  my $self = shift;
  my $byte_stream = shift;
  my %opt = @_;

  my $obj = {
    category => $self->{category},
    char_buffer => \(my $s = ''),
    char_buffer_pos => 0,
    character_queue => [],
    filehandle => $byte_stream,
    charset => '', ## TODO: We set a charset name for input_encoding (when we get identify-by-URI nonsense away)
    byte_buffer => $opt{byte_buffer} ? ${$opt{byte_buffer}} : '', ## TODO: ref, instead of value, should be used
    onerror => $opt{onerror} || sub {},
    #onerror_set
    level => $opt{level} || {
      must => 'm',
      charset_variant => 'm',
      charset_fact => 'm',
      iso_shall => 'm',
    },
    error_level => $self->{error_level} || {
      ## HTML5 charset name aliases
          ## NOTE: Use of code points in the variant whose definition differs
          ## from the original charset is a parse error in HTML5.  However,
          ## it does not affect the document conformance; the HTML5 spec
          ## does not define the conformance of the input stream against the
          ## charset in use.
      'fallback-char-error' => 'charset_variant',
      #'fallback-illegal-error' => 'charset_variant',
      'fallback-unassigned-error' => 'charset_variant',
          ## NOTE: An appropriate error level should be set for each charset
          ## (many charset prohibits use of unassigned code points).

      'illegal-octets-error' => 'charset_fact',
      'unassigned-code-point-error' => 'charset_fact',
      'invalid-state-error' => 'charset_fact',
    },
  };

  require HTML::HTML5::Parser::Charset::DecodeHandle;
  if ($self->{iana_names}->{'iso-2022-jp'}) {
    $obj->{state_2440} = 'gl-jis-1978';
    $obj->{state_2442} = 'gl-jis-1983';
    $obj->{state} = 'state_2842';
    eval {
      require Encode::GLJIS1978;
      require Encode::GLJIS1983;
    };
    if (Encode::find_encoding ($obj->{state_2440}) and
        Encode::find_encoding ($obj->{state_2442})) {
      return ((bless $obj, 'HTML::HTML5::Parser::Charset::DecodeHandle::ISO2022JP'),
              PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME);
    }
  } elsif ($self->{xml_names}->{'iso-2022-jp'}) {
    $obj->{state_2440} = 'gl-jis-1997-swapped';
    $obj->{state_2442} = 'gl-jis-1997';
    $obj->{state} = 'state_2842';
    eval {
      require Encode::GLJIS1997Swapped;
      require Encode::GLJIS1997;
    };
    if (Encode::find_encoding ($obj->{state_2440}) and
        Encode::find_encoding ($obj->{state_2442})) {
      return ((bless $obj, 'HTML::HTML5::Parser::Charset::DecodeHandle::ISO2022JP'),
              PREFERRED_CHARSET_NAME | REGISTERED_CHARSET_NAME);
    }
  }

  my ($e, $e_status) = $self->get_perl_encoding
      (%opt, allow_semiconforming => 1);
  if ($e) {
    $obj->{perl_encoding_name} = $e->name;
    unless ($self->{category} & CHARSET_CATEGORY_BLOCK_SAFE) {
      $e_status |= FALLBACK_ENCODING_IMPL;
    }
    $obj->{bom_pattern} = $self->{bom_pattern};
    $obj->{fallback} = $self->{fallback};
    return ((bless $obj, 'HTML::HTML5::Parser::Charset::DecodeHandle::Encode'), $e_status);
  } else {
    return (undef, 0);
  }
} # get_decode_handle

sub get_perl_encoding ($;%) {
  my ($self, %opt) = @_;
  
  require Encode;
  my $load_encode = sub {
    my $name = shift;
    if ($name eq 'euc-jp-1997') {
      require Encode::EUCJP1997;
    } elsif ($name eq 'shift-jis-1997') {
      require Encode::ShiftJIS1997;
    } elsif ({'web-latin1' => 1,
              'web-latin1-us-ascii' => 1,
              'web-latin5' => 1}->{$name}) {
      require HTML::HTML5::Parser::Charset::WebLatin1;
    } elsif ($name eq 'web-thai' or $name eq 'web-tis-620') {
      require HTML::HTML5::Parser::Charset::WebThai;
    }
  }; # $load_encode

  if ($opt{allow_error_reporting}) {
    for my $perl_name (keys %{$self->{perl_names} or {}}) {
      my $perl_status = $self->{perl_names}->{$perl_name};
      next unless $perl_status & ERROR_REPORTING_ENCODING_IMPL;
      next if $perl_status & FALLBACK_ENCODING_IMPL;
      next if $perl_status & SEMICONFORMING_ENCODING_IMPL and
          not $opt{allow_semiconforming};
      
      $load_encode->($perl_name);
      my $e = Encode::find_encoding ($perl_name);
      if ($e and $e->name eq $perl_name) {
        ## NOTE: Don't return $e unless $e eq $perl_name, since
        ## |find_encoding| resolves e.g. |foobarlatin-1| to |iso-8859-1|,
        ## which might return wrong encoding object when a dedicated
        ## implementation not part of the standard Perl distribution is
        ## desired.
        return ($e, $perl_status);
      }
    }
  }
  
  for my $perl_name (keys %{$self->{perl_names} or {}}) {
    my $perl_status = $self->{perl_names}->{$perl_name};
    next if $perl_status & ERROR_REPORTING_ENCODING_IMPL;
    next if $perl_status & FALLBACK_ENCODING_IMPL;
    next if $perl_status & SEMICONFORMING_ENCODING_IMPL and
        not $opt{allow_semiconforming};

    $load_encode->($perl_name);
    my $e = Encode::find_encoding ($perl_name);
    if ($e) {
      return ($e, $perl_status);
    }
  }
  
  if ($opt{allow_fallback}) {
    for my $perl_name (keys %{$self->{perl_names} or {}}) {
      my $perl_status = $self->{perl_names}->{$perl_name};
      next unless $perl_status & FALLBACK_ENCODING_IMPL or
          $perl_status & SEMICONFORMING_ENCODING_IMPL;
      ## NOTE: We don't prefer semi-conforming implementations to 
      ## non-conforming implementations, since semi-conforming implementations
      ## will never be conforming without assist of the callee, and in such
      ## cases the callee should set the |allow_semiconforming| option upon
      ## the invocation of the method anyway.
  
      $load_encode->($perl_name);
      my $e = Encode::find_encoding ($perl_name);
      if ($e) {
        return ($e, $perl_status);
      }
    }

    for my $iana_name (keys %{$self->{iana_names} or {}}) {
      $load_encode->($iana_name);
      my $e = Encode::find_encoding ($iana_name);
      if ($e) {
        return ($e, FALLBACK_ENCODING_IMPL);
      }
    }
  }
  
  return (undef, 0);
} # get_perl_encoding

sub get_iana_name ($) {
  my $self = shift;
  
  my $primary;
  my $other;
  for my $iana_name (keys %{$self->{iana_names} or {}}) {
    my $name_status = $self->{iana_names}->{$iana_name};
    if ($name_status & PREFERRED_CHARSET_NAME) {
      return $iana_name;
    } elsif ($name_status & PRIMARY_CHARSET_NAME) {
      $primary = $iana_name;
    } elsif ($name_status & REGISTERED_CHARSET_NAME) {
      $other = $iana_name;
    } else {
      $other ||= $iana_name;
    }
  }

  return $primary || $other;
} # get_iana_name

## NOTE: A non-method function
sub is_syntactically_valid_iana_charset_name ($) {
  my $name = shift;
  return $name =~ /\A[\x20-\x7E]{1,40}\z/;

  ## NOTE: According to IANAREG, "The character set names may be up to 40 
  ## characters taken from the printable characters of US-ASCII.  However,
  ## no distinction is made between use of upper and lower case letters.".
} # is_suntactically_valid_iana_charset_name

1;
## $Date: 2008/09/15 07:19:33 $

