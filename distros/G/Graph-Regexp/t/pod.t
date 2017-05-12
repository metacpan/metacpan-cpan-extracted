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
  skip( 'Test::Pod not installed on this system', 1 )
    unless do
      {
      eval "use Test::Pod";
      $@ ? 0 : 1;
      };
  pod_file_ok( '../lib/Graph/Regexp.pm' );
  }
