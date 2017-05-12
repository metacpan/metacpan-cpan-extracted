#!/usr/bin/perl -w

use strict;
use Test::More tests => 16;

use_ok('Encode');
use_ok('Encode::HanExtra');

my $char = chr(20154); # 'Human' in Chinese

is_code('big5-1984'   => "\xA4\x48");
is_code(big5ext       => "\xA4\x48");
is_code(big5plus      => "\xA4\x48");
is_code(cccii         => "\x21\x30\x64");
is_code('cns11643-1'  => "\x44\x29");
is_code('euc-tw'      => "\x8E\xA1\xC4\xA9");
is_code(gb18030       => "\xC8\xCB");

sub is_code {
    is(Encode::decode($_[0] => $_[1]), $char, "$_[0] - decode");
    is(Encode::encode($_[0] => $char), $_[1], "$_[0] - encode");
}
