#!/usr/bin/perl -w
use strict;
use Test;
BEGIN { plan tests => 70 }
use Lingua::Slavic::Numbers qw( LANG_BG );
use Lingua::BG::Numbers qw( number_to_bg ordinate_to_bg );

# switch off warnings
$SIG{__WARN__} = sub {};

use vars qw(%numbers);
do 't/numbers';
do 't/rig.pm';

rig($numbers{LANG_BG()}, \&number_to_bg);
