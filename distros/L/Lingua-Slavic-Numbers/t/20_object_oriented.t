#!/usr/bin/perl -w
use strict;
use Test;
BEGIN { plan tests => 140 }
use Lingua::Slavic::Numbers;

use vars qw(%numbers);
do 't/numbers';
do 't/rig.pm';

rig($numbers{LANG_BG()}, sub
    {
     my $num = Lingua::Slavic::Numbers->new(shift, Lingua::Slavic::Numbers::LANG_BG);
     ok( defined $num );
     return $num->get_string();
    });
