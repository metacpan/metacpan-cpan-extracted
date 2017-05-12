use strict;
use warnings;

use Test::More tests => 1;
use MARC::Charset qw(marc8_to_utf8);
use MARC::Charset::Constants qw(:all);

my $marc8 = 
    'a ' . 
    ESCAPE . MULTI_G0_A . CJK .          # escape to CJK for G0
    chr(0x21) . chr(0x20) . chr(0x3d) .  # horizontal ellipsis
    chr(0x21) . chr(0x20) . chr(0x40) .  # left double quotation mark
    chr(0x7f) . chr(0x20) . chr(0x14) .  # em dash
    chr(0x7f) . chr(0x20) . chr(0x19) .  # right single quotation mark
    chr(0x7f) . chr(0x20) . chr(0x20) .  # right double quotation mark
    chr(0x7f) . chr(0x21) . chr(0x22) .  # trade mark sign
    ESCAPE . SINGLE_G0_A . BASIC_LATIN . # back to latin
    ' z';
   
my $expected = 'a '. 
               chr(0x2026) .
               chr(0x201c) .
               chr(0x2014) .
               chr(0x2019) .
               chr(0x201d) .
               chr(0x2122) .
               ' z';
is($expected, marc8_to_utf8($marc8), 'III non-standard');


