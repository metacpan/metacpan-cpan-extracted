#!/usr/bin/perl
# vim:set filetype=perl:

use warnings;
use strict;

use Test::More tests => 11;

use Hardware::Simulator::MIX;

ok(mix_char_code( mix_char(0) ) == 0);
ok(mix_char_code( mix_char(1) ) == 1);
ok(mix_char_code( mix_char(11) ) == 11);
ok( mix_char(10) eq "^" );
ok( mix_char(20) eq "^" );
ok( mix_char(21) eq "^" );
ok(mix_char_code( mix_char(30) ) == 30);
ok( mix_char(55)  eq "'" );
ok( !defined(mix_char(56)) );
ok( !defined(mix_char(-1)) );
ok( mix_char_code("^") == -1 );
