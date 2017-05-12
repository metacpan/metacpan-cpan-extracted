#!/usr/bin/perl -w

use Test::More tests => 10;
use strict;

BEGIN
  {
  $| = 1;
  use blib;
  unshift @INC, '../lib';
  unshift @INC, '../blib/arch';
  chdir 't' if -d 't';
  use_ok ('Games::Irrlicht');
  }

can_ok ('Games::Irrlicht', qw/ 
  new _next_frame _init
  hide_mouse_cursor

  getIrrlichtDevice
  getFileSystem
  getGUIEnvironment
  getSzeneManager
  getVideoDriver
  
  /);

my $app = Games::Irrlicht->new( disable_log => 1 );

is (ref($app), 'Games::Irrlicht');

my $i = 0;
while ($i++ < 2)
  {
  $app->_next_frame();
  }

#############################################################################
# IrrlichDevice

my $device = $app->getIrrlichtDevice();

is ($device->setVisible(0), undef, 'set cursor to invisible');
is (($device->getVersion() + 0) >= 0.6, 1, 'getVersion() >= 0.6');
is ($device->isWindowActive(), 1, 'window is active');

#############################################################################
# VideoDriver

my $driver = $app->getVideoDriver();

is ($driver->getPrimitiveCountDrawn(), 0, 'no primitives drawn yet');

#############################################################################
# FileSystem

my $filesystem = $app->getFileSystem();

is ($filesystem->addZipFileArchive('media/test.zip'), 1,
  'Could add zip file');

# TODO: does not work in Irrlicht v0.6 in Linux (segfault due to Irrlicht bug)
#is ($filesystem->getWorkingDirectory(), '',
#  'get pwd');

# TODO: these fail under Linux?
#is ($filesystem->changeWorkingDirectoryTo('media'), 1,
#  'Could change dir to media');
#is ($filesystem->changeWorkingDirectoryTo('..'), 1,
#  'Could change dir back');

#############################################################################
# SzeneManager

my $szmgr = $app->getSzeneManager();

is ($szmgr->addCameraSceneNodeFPS(), 1,
  'Could add FPS camera');

#############################################################################
# GUIEnvironment

my $gui = $app->getGUIEnvironment();

#############################################################################
# OSOperator

my $os = $app->getOSOperator();

if ($^O =~ /linux/)
  {
  is ($os->getOperationSystemVersion(), 'Linux', 'getOSVersion()'); 
  }
else
  {
  # on every other system, check that it returns a non-empty string
  is (length($os->getOperationSystemVersion()) != 0, 1, 'getOSVersion()'); 
  }


