#!/usr/bin/perl -w

# Games::Irrlicht::Techdemo
# ' q' for quit, 'f' for fullscreen

use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, './lib';
  unshift @INC, '../lib';
  unshift @INC, '../blib/arch/';
  }

use Games::Irrlicht::TechDemo;

my $options = { width => 800, height => 640, max_fps => 15, fullscreen => 1};

print
  "Irrlicht TechDemo v0.01 (C) 2004 by Tels <http://Bloodgate.com/>\n\n";
  "Based on the TechDemo from http://irrlicht.sf.net\n\n";

my $app = Games::Irrlicht::TechDemo->new( $options );
$app->main_loop();

print "Running time was ", int($app->now() / 10)/100, " seconds.\n";
print "Drawn ", $app->frames()," frames\n";
print "Minimum framerate ",int($app->min_fps()*10)/10,
      " fps, maximum framerate ",int($app->max_fps()*10)/10," fps\n";
print "Minimum time per frame ", $app->min_frame_time(),
      " ms, maximum time per frame ", $app->max_frame_time()," ms\n";
print "Thank you for playing!\n";
