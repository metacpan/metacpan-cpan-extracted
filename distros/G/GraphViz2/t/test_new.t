#!/usr/bin/env perl

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use Test::More;

# ------------------------------------------------

BEGIN{ use_ok('GraphViz2'); }

my($count)  = 1; # Counting the use_ok above.

$count++;

my $GraphViz2 = new_ok('GraphViz2');

done_testing($count);
