#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: 20import.t,v 1.2 2002/02/27 23:03:59 eserte Exp $
# Author: Slaven Rezic
#

use strict;

use GD;

BEGIN {
    if (!eval q{
	use GD::Convert 'gif=any';
	use Test;
	1;
    }) {
	print "# tests only work with installed Test module and some gif converter on your system\n";
	print "1..1\n";
	print "ok 1\n";
	exit;
    }
}

BEGIN { plan tests => 1 }

my $im = new GD::Image 200,200;
my $white = $im->colorAllocate(255,255,255);
my $black = $im->colorAllocate(0,0,0);
my $red = $im->colorAllocate(255,0,0);
my $blue = $im->colorAllocate(0,0,255);
$im->rectangle(0,0,99,99,$black);
$im->arc(50,50,95,75,0,360,$blue);
$im->fill(50,50,$red);

ok($im->gif =~ /GIF/, 1);

__END__
