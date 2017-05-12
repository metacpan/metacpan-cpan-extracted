#! /usr/bin/perl
# $Id: 03_multiple.t,v 1.2 2008/09/02 10:55:56 dk Exp $

use strict;
use warnings;

use Test::More tests => 6;

use Image::Match;

sub points
{
	my @p;
	for ( my $i = 0; $i < @_; $i+=2) {
		push @p, [ @_[$i,$i+1] ];
	}
	@p = map { @$_ } sort {
		$a->[0] <=> $b->[0] or
		$a->[1] <=> $b->[1]
	} @p;
	return join(',', @p);
}

my $r;
my $big = Prima::Image-> new(
	width    => 8,
	height   => 8,
	type     => im::Byte,
	lineSize => 8,
	reverse  => 1,
	data     => 
"        ".
" ##     ".
" ##     ".
"        ".
"    ##  ".
"    ##  ".
"        ".
"        "
);

my $small = Prima::Image-> new(
	width    => 2,
	height   => 2,
	lineSize => 2,
	reverse  => 1,
	type     => im::Byte,
	data     => "####",
);

$r = points $big-> match( $small, multiple => 1, mode => 'geom');
ok( $r eq '1,5,4,2', "non-overlapped / geom");
$r = points $big-> match( $small, multiple => 1, mode => 'screen');
ok( $r eq '1,1,4,4', "non-overlapped / screen");

$big-> set(
	type     => im::Byte,
	lineSize => 8,
	reverse  => 1,
	data     => 
"        ".
"        ".
"        ".
"        ".
"        ".
" ##     ".
" ###    ".
"  ##    "
);
$r = points $big-> match( $small, multiple => 1, mode => 'geom');
ok( $r eq '1,1,2,0', "overlapped / geom");
$r = points $big-> match( $small, multiple => 1, mode => 'geom', overlap => 'none');
ok( $r =~ /^(1,1|2,0)$/, "overlapped / none");
$r = points $big-> match( $small, multiple => 1, mode => 'screen');
ok( $r eq '1,5,2,6', "overlapped / screen");

$big-> set(
	type     => im::Byte,
	lineSize => 8,
	reverse  => 1,
	data     => 
"        ".
"        ".
"        ".
"        ".
"        ".
" ###    ".
" ###    ".
" ###    "
);
$r = points $big-> match( $small, multiple => 1, mode => 'geom', overlap => 'all');
ok( $r eq '1,0,1,1,2,0,2,1', "overlapped / all matches");
