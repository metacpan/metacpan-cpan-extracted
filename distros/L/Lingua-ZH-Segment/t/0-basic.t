#!/usr/bin/perl
use strict;
use Test::More tests => 2;

BEGIN { use_ok('Lingua::ZH::Segment'); }
ok($Lingua::ZH::Segment::VERSION) if $Lingua::ZH::Segment::VERSION or 1;
