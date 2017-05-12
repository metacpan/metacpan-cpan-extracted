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
  skip("Test::Pod::Coverage 1.00 required for testing POD coverage", $tests)
    unless do {
    eval "use Test::Pod::Coverage 1.00";
    $@ ? 0 : 1;
    };
  # all "FOO" should be ignored:
  my $trustme = { trustme => [qr/^[A-Z0-9_]+\z/] };
  for my $m (qw/
    Games::3D
    Games::3D::Link
    Games::3D::Signal
    Games::3D::Sensor
    Games::3D::Template
    Games::3D::Thingy
    Games::3D::World
   /)
    {
    pod_coverage_ok( $m, $trustme, "$m is covered" );
    }
  }
