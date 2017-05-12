#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 1;
   chdir 't' if -d 't';
   use lib '../lib';
   };

SKIP:
  {
  skip("Test::Pod::Coverage 1.00 required for testing POD coverage", 1)
    unless do {
    eval "use Test::Pod::Coverage 1.00";
    $@ ? 0 : 1;
    };
  for my $m (qw/
    Graph::Regexp
   /)
    {
    pod_coverage_ok( $m, "$m is covered" );
    }
  }

