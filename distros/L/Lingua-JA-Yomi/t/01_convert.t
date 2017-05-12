#!/usr/bin/env perl
use strict;
use warnings;
use Test::More qw/no_plan/;
use utf8;

use Lingua::JA::Yomi;

my $converter = new Lingua::JA::Yomi;
is( $converter->convert('aerosmith'), 'エアロウスミス','aerosmith');
