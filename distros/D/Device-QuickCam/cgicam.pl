#!/usr/bin/perl

#Basic HTTP Example
#To get this running, you'll most likely will have to 
#  chown root.root cgicam.pl
#  chmod 0755 cgicam.pl
#  chmod +s cgicam.pl

use Device::QuickCam;

my $cam = Device::QuickCam->new();
$cam->set_quality(100);
$cam->set_bpp(32);
$cam->set_width(640);
$cam->set_height(480);
$cam->set_http(1);
$cam->grab();
