#!/usr/local/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################


use Test::Simple tests => 3;

use Image::WMF;
ok(1); # If we made it this far, we're ok.

my $im = new Image::WMF(300,100);
my $red = $im->colorAllocate(255,0,0);
my $blue = $im->colorAllocate(0,0,255);
my $green = $im->colorExact(0,255,0);
$im->filledRectangle(20,20,50,50,$red);
my $p = new Image::WMF::Polygon();
$p->addPt(10,20);
$p->addPt(30,30);
$p->addPt(50,100);
$im->filledPolygon($p,$green);
$im->string(gdSmallFont,20,20,"My first WMF!", $blue);
$wmfdata = $im->wmf;

ok( length($wmfdata) > 0);

open(OUT, ">test.wmf") or die "Can't create WMF file: !$\n";
print OUT $wmfdata;
close(OUT);

ok(-e "test.wmf" && -s "test.wmf" > 0);
