#!/usr/bin/perl -w

use Test::More;
use strict;

my $tests;

BEGIN
   {
   $tests = 2;
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
  for my $m (qw/
    Graph::Flowchart
   /)
    {
    pod_coverage_ok( $m, "$m is covered" );
    }

  # Define the global CONSTANTS for internal usage
  my $trustme = { trustme => [ qr/^(
	N_BLOCK|
	N_BODY|
	N_CONTINUE|
	N_ELSE|
	N_END|
	N_FOR|
	N_IF|
	N_JOINT|
	N_START|
	N_THEN|
	N_BREAK|
	N_GOTO|
	N_LAST|
	N_NEXT|
	N_RETURN|
	N_SUB|
	N_USE
    )\z/x ] };
  pod_coverage_ok( "Graph::Flowchart::Node", $trustme );
  }

