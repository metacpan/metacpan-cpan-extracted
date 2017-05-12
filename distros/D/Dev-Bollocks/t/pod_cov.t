#!/usr/bin/perl -w

use Test::More;
use strict;

my $tests;

BEGIN
   {
   $tests = 1;
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
  my $trustparents = { coverage_class => 'Pod::Coverage::CountParents' };
  for my $m (qw/
    Dev::Bollocks
   /)
    {
    pod_coverage_ok( $m, $trustparents, "$m is covered" );
    }
  }
