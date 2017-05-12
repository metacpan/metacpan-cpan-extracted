use strict;
use warnings;

use Test::More tests => 1;
use MARC::Charset qw(marc8_to_utf8);
use MARC::Charset::Constants qw(:all);

my $marc8 = 
    'a ' . 
    ESCAPE . MULTI_G0_A . CJK .          # escape to CJK for G0
    chr(0x21) . chr(0x75) . chr(0x60) .  # CJK char
    chr(0x21) . chr(0x2A) . chr(0x2A) .  # Another CJK char
    ESCAPE . SINGLE_G0_A . BASIC_LATIN . # back to latin
    ' z';
   
my $expected = 'a '. chr(0x57C7) . chr(0xE8D8) . ' z';
is($expected, marc8_to_utf8($marc8), 'cjk');


