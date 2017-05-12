use Test::More tests=>4;

use MARC::Charset::Constants qw(:all);

## this test will exercise the first type of character escapes 
## as documents at http://lcweb.loc.gov/marc/specifications/speccharmarc8.html
## "Technique 2: Other Alternate Graphic Character Sets"

use strict;
use MARC::Charset qw(marc8_to_utf8);

## test some ASCII & Greek mixed together

my $test = 
    'this is greek' .			    ## regular ASCII
    ESCAPE . SINGLE_G0_A . BASIC_GREEK .    ## set G0 to Greek
    chr(0x49) .				    ## zeta
    ESCAPE . SINGLE_G0_A . BASIC_LATIN .    ## set GO to ASCII
    'this is not';			    ## regular ASCII

my $expected = 'this is greek' . chr(0x0396) . 'this is not';
is(marc8_to_utf8($test), $expected, 'escape type 2 to Greek');

## test some arabic, which never returns to ASCII

$test = 
    ESCAPE . SINGLE_G0_A . BASIC_ARABIC .   ## set G0 to ArabicBasic
    ESCAPE . SINGLE_G1_A . EXTENDED_ARABIC. ## set G1 to ArabicExtended
    chr(0x4d) .				    ## HAH (from Basic)
    chr(0xBA);				    ## DUL (from Extended)

$expected = chr(0x062D) . chr(0x068E);
is(marc8_to_utf8($test), $expected, 'escape type 2 to Basic+Ext Arabic');

## test some Hebrew and Arabic mixed together

$test = 
    ESCAPE . SINGLE_G0_A . BASIC_ARABIC .   ## set G0 to ArabicBasic
    ESCAPE . SINGLE_G1_A . EXTENDED_ARABIC. ## set G1 to ArabicExtended
    chr(0x47) .				    ## ALEF (Arabic Basic) 
    ESCAPE . SINGLE_G0_A . BASIC_HEBREW .   ## replace ArabicBasic with Hebrew
    chr(0x71) .				    ## SAMEKH (Hebrew)
    chr(0xE9); 				    ## RNOON (ArabicExtended)

$expected = chr(0x0627) . chr(0x05E1) . chr(0x06BB);
is(marc8_to_utf8($test), $expected, 'escape type 2 Arabic + Hebrew mixed');

## test some greek with spaces
$test = 
    ESCAPE . SINGLE_G0_A . BASIC_GREEK .    ## set G0 to Greek
    chr(0x49) .                             ## ZETA
    chr(0x4B) .                             ## THETA
    ' ' .                                   ## SPACE
    chr(0x4E) .                             ## LAMBDA
    ESCAPE . SINGLE_G0_A . BASIC_LATIN;     ## Back to ASCII 

$expected = chr(0x0396) . chr(0x0398) . ' ' . chr(0x039B);
is(marc8_to_utf8($test), $expected, 'greek with internal space');


