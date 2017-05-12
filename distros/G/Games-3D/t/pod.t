#!/usr/bin/perl -w

use Test::More;
use strict;
   
my $tests;

BEGIN
   {
   $tests = 7;
   plan tests => $tests;
   chdir 't' if -d 't';
   use lib '../lib';
   };

SKIP:
  {
  skip( 'Test::Pod not installed on this system', $tests )
    unless do
      {
      eval "use Test::Pod;";
      $@ ? 0 : 1;
      };
  pod_file_ok( '../lib/Games/3D.pm' );
  pod_file_ok( '../lib/Games/3D/Link.pm' );
  pod_file_ok( '../lib/Games/3D/Signal.pm' );
  pod_file_ok( '../lib/Games/3D/Sensor.pm' );
  pod_file_ok( '../lib/Games/3D/Template.pm' );
  pod_file_ok( '../lib/Games/3D/Thingy.pm' );
  pod_file_ok( '../lib/Games/3D/World.pm' );
  }

