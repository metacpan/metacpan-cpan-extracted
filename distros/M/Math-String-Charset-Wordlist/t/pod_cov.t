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
  skip("Test::Pod::Coverage 1.08 and Pod::Coverage 0.19 required for testing POD coverage", $tests)
    unless do {
    eval "use Test::Pod::Coverage 1.08";
    my $r = ($@ ? 0 : 1);
    eval "use Pod::Coverage 0.19";	# need this on newer Perls to avoid false-fails
    $r & ($@ ? 0 : 1);			# only return true if we have both
    };
  my $trustparents = { coverage_class => 'Pod::Coverage::CountParents' };
  for my $m (qw/
    Math::String::Charset::Wordlist
   /)
    {
    pod_coverage_ok( $m, $trustparents, "$m is covered" );
    }

  }

