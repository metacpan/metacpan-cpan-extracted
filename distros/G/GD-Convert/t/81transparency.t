#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: 81transparency.t,v 1.11 2008/07/23 18:52:18 eserte Exp $
# Author: Slaven Rezic
#

use strict;

use GD;
use GD::Convert;

my $mw0;

BEGIN {
    if (!eval q{
	use Test::More;
        use Tk;
	use Tk::Config;
	die "No DISPLAY" if $win_arch eq 'x' && !$ENV{DISPLAY};
	1;
    }) {
	print "1..0 # skip: no Test::More and/or Tk modules\n";
	CORE::exit;
    }
}

BEGIN {
    if (!eval { $mw0 = MainWindow->new; }) {
	print "1..0 # skip: cannot create main Tk window\n";
	diag($@) if $@;
	CORE::exit;
    }
}

use Getopt::Long;

GetOptions("d!" => \$GD::Convert::DEBUG)
    or die "usage: $0 [-d]";

plan tests => 4;

my $images = 4;

my $mw = $mw0->Frame->pack;
my $c = $mw->Canvas(-width => $images*200, -height => 200,
		    -highlightthickness => 0)->pack;

my $im = new GD::Image 200,200;
my $white = $im->colorAllocate(255,255,255);
my $black = $im->colorAllocate(0,0,0);
my $red = $im->colorAllocate(255,0,0);
my $blue = $im->colorAllocate(0,0,255);
$im->rectangle(0,0,99,99,$black);
$im->arc(50,50,95,75,0,360,$blue);
$im->fill(50,50,$red);
$im->transparent($white);

$c->createLine(0,0,$c->cget(-width),$c->cget(-height),-width=>3,-fill=>"blue");
$c->createLine(0,$c->cget(-height),$c->cget(-width),0,-width=>3,-fill=>"blue");

 SKIP: {
     skip("No ppmtogif available, no gif_netpbm check", 1)
	 if !GD::Convert::_can_gif_netpbm();
     
     skip("No -transparent option with ppmtogif, no transparencyhack", 1)
	 if !GD::Convert::_can_gif_netpbm_transparencyhack();

     my $gif = $im->gif_netpbm(-transparencyhack => 1);
     ok($gif =~ /GIF/, "Detected GIF file");
     if (eval 'require MIME::Base64; 1') {
	 my $p4 = $mw->Photo(-data => MIME::Base64::encode_base64($gif));
	 $c->createImage(0,0,-anchor=>"nw", -image => $p4);
     }
 }

 SKIP: {
     skip("No convert (ImageMagick) available, no gif_imagemagick check", 1)
	 if !GD::Convert::_can_gif_imagemagick();
     
     my $gif2 = $im->gif_imagemagick(-transparencyhack => 1);
     ok($gif2 =~ /GIF/, "Detected GIF file");
     if (eval 'require MIME::Base64; 1') {
	 my $p5 = $mw->Photo(-data => MIME::Base64::encode_base64($gif2));
	 $c->createImage(200,0,-anchor=>"nw", -image => $p5);
     }
 }

my $xpm = $im->xpm;
ok($xpm =~ /XPM/, "Detected XPM file");
my $p6 = $mw->Photo(-data => $xpm);
$c->createImage(400,0,-anchor=>"nw", -image => $p6);

 SKIP: {
     skip("No convert (ImageMagick) available, no gif_imagemagick check", 1)
	 if !GD::Convert::_can_gif_imagemagick();

     my $gif3 = $im->gif_imagemagick;
     ok($gif3 =~ /GIF/, "Detected GIF file");
     if (eval 'require MIME::Base64; 1') {
	 my $p7 = $mw->Photo(-data => MIME::Base64::encode_base64($gif3));
	 $c->createImage(600,0,-anchor=>"nw", -image => $p7);
     }
 }

$mw0->Button(-text => "OK", -command => sub { $mw0->destroy })->pack
    if $ENV{PERL_TEST_INTERACTIVE};

if (!$ENV{PERL_TEST_INTERACTIVE}) { $mw0->after(1000, sub { $mw0->destroy }) }

MainLoop;

__END__
