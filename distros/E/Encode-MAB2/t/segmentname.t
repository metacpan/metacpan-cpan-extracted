# -*- coding: utf-8; mode: cperl -*-

use strict;
use Test::More tests => 3;

use_ok('MAB2::Record::titel');
# Add more test here!

my $s = MAB2::Record::titel->segmentname(123);
like($s, qr/KOERPERSCHAFT, BEI DER DIE 6/, "123 enthaelt nicht KOERPERSCHAFT...");
$s = MAB2::Record::titel->segmentname(513);
is($s,"AENDERUNGEN IM IMPRESSUM");
