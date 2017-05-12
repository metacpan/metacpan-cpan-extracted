#!/usr/bin/perl -w

# Copyright (c) 2000 Mark Summerfield. All Rights Reserved.
# May be used/distributed under the GPL.


use strict ;

use File::Temp qw(tempfile);
use Test::More tests => 15 ;

use Image::Xbm ;
pass 'loaded module' ;

my(undef, $fp) = tempfile('image-xbm-XXXXXXXX', SUFFIX => '.xbm', UNLINK => 1);

my $i = Image::Xbm->new_from_string( "#####\n#---#\n-###-\n--#--\n--#--\n#####" ) ;
isa_ok $i, 'Image::Xbm' ;
is $i->as_binstring, '11111100010111000100001001111100', 'expected new_from_string result' ;

my $j = $i->new ;
isa_ok $j, 'Image::Xbm' ;
is $j->as_binstring, '11111100010111000100001001111100', 'expected clone result' ;

$i->save( $fp ) ;
ok -e $fp, 'saved xbm file exists' ;

my $s = $i->serialise ;
ok $s, 'call serialiase' ;

my $k = Image::Xbm->new_from_serialised( $s ) ;
isa_ok $k, 'Image::Xbm' ;
ok $k->is_equal( $i ), 'new_from_serialised is_equal' ;

$i = undef ;
ok !defined $i, 'destroy image' ;

$i = Image::Xbm->new( -file => $fp ) ;
isa_ok $i, 'Image::Xbm' ;
is $i->as_binstring, '11111100010111000100001001111100', 'loaded image from file' ;
is $i->get( -file ), $fp, '-file accessor' ;
is $i->get( -width ), 5, '-width accessor' ;
is $i->get( -height ), 6, '-height accessor' ;
