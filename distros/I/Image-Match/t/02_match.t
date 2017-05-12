#! /usr/bin/perl
# $Id: 02_match.t,v 1.1 2008/09/01 09:26:28 dk Exp $

use strict;
use warnings;

use Test::More tests => 4;

use File::Basename;
use Image::Match;

my $f;

# 1
$f = dirname($0) . '/02.png';
ok( -f $f, 'have png file');
die "Can't find 02.png, go away" unless -f _;

# 2
my $i = Prima::Image-> load( $f);
ok( $i, "can load png " . ($@ ? ": $@" : ''));
die "Can't load png, go away" unless $i;

my $s = $i-> extract( 7, $i-> height - 7 - 16, 16, 16);
ok( $s && $s-> width == 16 && $s-> height == 16, "extracted ok");

my ( $x, $y) = $i-> match( $s);
ok( defined($x) && $x == 7 && $y == 7, "matched ok");
