#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
   {
   plan tests => 2;
   chdir 't' if -d 't';
   use lib '../lib';
   use_ok ("Graph::Dependency") or die($@);
   };

#############################################################################

is (-f '../graph.pl', 1, 'main graph exists');

