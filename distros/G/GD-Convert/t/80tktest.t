#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: 80tktest.t,v 1.15 2008/07/23 18:52:15 eserte Exp $
# Author: Slaven Rezic
#

use strict;

use GD;

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
	exit;
    }

    if (!eval q{
	use GD::Convert qw(gif=any);
	1;
    }) {
	print "1..0 # skip: $@";
	exit;
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

plan tests => 10;

my $wait = 0;
$mw0->Button(-text => "OK", -command => sub { $wait = 1 })->pack(-side => "bottom")
    if $ENV{PERL_TEST_INTERACTIVE};

for my $transparency (0 .. 1) {
    my $mw = $mw0->Frame->pack;
    my $im = new GD::Image 200,200;
    my $white = $im->colorAllocate(255,255,255);
    my $black = $im->colorAllocate(0,0,0);
    my $red = $im->colorAllocate(255,0,0);
    my $blue = $im->colorAllocate(0,0,255);
    $im->rectangle(0,0,99,99,$black);
    $im->arc(50,50,95,75,0,360,$blue);
    $im->fill(50,50,$red);
    if ($transparency) {
	$im->transparent($white);
	$im->string(gdMediumBoldFont, 10,100, "transparent background", $blue);
    } else {
	$im->string(gdMediumBoldFont, 10,100, "white background", $blue);
    }
    $im->string(gdMediumBoldFont, 10,110, "black rectangle", $blue);
    $im->string(gdMediumBoldFont, 10,120, "black oval with blue outline", $blue);

    #open(TEST, ">/tmp/80tktest.gd");print TEST $im->gd;close TEST;system("gdtopng /tmp/80tktest.gd /tmp/80tktest.png"); system("display /tmp/80tktest.png &");

    my $ppm = $im->ppm;
    is(substr($ppm, 0, 2), "P6", "Detected PPM file (transparency=$transparency)");
    my $ppm_file = "test.ppm";
    open(PPM, "> $ppm_file") or die "Can't write to $ppm_file: $!";
    binmode PPM;
    print PPM $ppm;
    close PPM;

    my $p = $mw->Photo(-file => $ppm_file);
    unlink $ppm_file;

    my $row = 0;
    my $col = 0;
    $mw->Label(-text => "ppm")->grid(-row=>$row+1,-column=>$col);
    $mw->Label(-image => $p)->grid(-row=>$row,-column=>$col++);

    my $xpm = $im->xpm;
    like((split /\n/, $xpm)[0], qr/XPM/, "Detected XPM file");
    my $p2 = $mw->Photo(-data => $xpm);
    $mw->Label(-text => "xpm photo")->grid(-row=>$row+1,-column=>$col);
    $mw->Label(-image => $p2)->grid(-row=>$row,-column=>$col++);

    my $p3 = $mw->Pixmap(-data => $xpm);
    $mw->Label(-text => "xpm pixmap")->grid(-row=>$row+1,-column=>$col);
    $mw->Label(-image => $p3)->grid(-row=>$row,-column=>$col++);

    my $gif;
    
  SKIP: {
      skip("No ppmtogif available, no gif_netpbm check", 1)
	  if !GD::Convert::_can_gif_netpbm();

      skip("No -transparent option with ppmtogif, no transparencyhack", 1)
	  if !GD::Convert::_can_gif_netpbm_transparencyhack();

      $gif = $im->gif_netpbm(-transparencyhack => $transparency);
      ok($gif =~ m/^GIF8[79]/, "Detected GIF file"); # no like because of binary!
      if (eval 'require MIME::Base64; 1') {
	  my $p4 = $mw->Photo(-data => MIME::Base64::encode_base64($gif));
	  $mw->Label(-text => "gif (netpbm)")->grid(-row=>$row+1,-column=>$col);
	  $mw->Label(-image => $p4)->grid(-row=>$row,-column=>$col++);
      }
  }

    my $gif2 = $im->gif(-transparencyhack => $transparency);
  SKIP: {
      skip("Probably no netpbm installed", 2)
	  if (!defined $gif || $gif eq '');
      ok($gif eq $gif2, "Both GIFs the same"); # no is because of binary!

      skip("No convert (ImageMagick) available, no gif_imagemagick check", 1)
	  if !GD::Convert::_can_gif_imagemagick();

      my $gif3 = $im->gif_imagemagick(-transparencyhack => $transparency);

      skip("convert seems to be available, but generates no usable output", 1)
	  if (!defined $gif3 || $gif3 eq '');

      ok($gif3 =~ m{^GIF8[79]}, "Detected GIF file"); # no like because of binary!
      if (eval 'require MIME::Base64; 1') {
	  my $p5 = $mw->Photo(-data => MIME::Base64::encode_base64($gif));
	  $mw->Label(-text => "gif (imagemagick)")->grid(-row=>$row+1,-column=>$col);
	  $mw->Label(-image => $p5)->grid(-row=>$row,-column=>$col++);
      }
  }

    $wait = 0;
    if (!$ENV{PERL_TEST_INTERACTIVE}) {
	$mw0->after(1000, sub { $wait = 1 });
    }
    $mw0->waitVariable(\$wait);
    $mw->destroy;
}

__END__
