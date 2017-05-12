use strict;
use warnings;
use utf8;

use Test::More tests => 2;
use MARC::Charset qw(marc8_to_utf8);
use MARC::Charset::Constants qw(:all);

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my $marc8 = 
    ESCAPE . SINGLE_G0_A . BASIC_CYRILLIC .
    'sAMYE WES' .
    ESCAPE . SINGLE_G0_A . EXTENDED_CYRILLIC .
    'D' . 
    ESCAPE . SINGLE_G0_A . BASIC_CYRILLIC .
    'LYE SKAZKI' .
    ESCAPE . SINGLE_G0_A . BASIC_LATIN .
    ', ' .
    ESCAPE . SINGLE_G0_A . BASIC_CYRILLIC .
    'STIHI I PESNI ' .
    ESCAPE . SINGLE_G0_A . BASIC_LATIN .
    '/'
;
   
is(marc8_to_utf8($marc8), 'Самые весёлые сказки, стихи и песни /', 'check Extended Cyrillic');

# This test is adapted from Asko Ohmann's bug report in
# https://rt.cpan.org/Public/Bug/Display.html?id=63271

$marc8 = chr(0x1B).'(NsEM'.chr(0x1B).'(B'.chr(0x1B).'(QD'.chr(0x1B).'(B'.chr(0x1B).'(NNOWA'.chr(0x1B).'(B';
is(marc8_to_utf8($marc8), 'Семёнова', 'another Extended Cyrillic check');
