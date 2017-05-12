#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: 40wbmp.t,v 1.2 2003/05/29 23:03:48 eserte Exp $
# Author: Slaven Rezic
#

use strict;
use vars qw($old_wbmp);

use GD;
BEGIN {
    if (defined &GD::Image::wbmp) {
	$old_wbmp = \&GD::Image::wbmp; # remember old wbmp method
    }
    $GD::VERSION = 1.25; # emulate old GD
}
use GD::Convert qw(wbmp);

BEGIN {
    if (!eval q{
	use Test;
	1;
    }) {
	print "1..0 # skip: no Test module\n";
	exit;
    }
}

BEGIN { plan tests => 2 }

my $im = new GD::Image(90,50);
my $white = $im->colorAllocate(255,255,255);
my $black = $im->colorAllocate(0,0,0);
$im->rectangle(30,10,60,40, $black);
my $wbmp = $im->wbmp($black);
ok($wbmp =~ /^\0\0Z2/);

if ($old_wbmp) {
    my $wbmp2 = $old_wbmp->($im, $black);
    ok($wbmp eq $wbmp2);
} else {
    skip("No original GD::Image::wbmp", 1);
}

__END__
