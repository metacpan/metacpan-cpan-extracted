#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use TestBadges;

my $content = 'readme';

sub content {
  build_dist(shift, { content => $content })->{readme}->slurp_raw;
}

like content(), qr{\A\[.+\)\n+$content\Z}s,
  'badges at top';

like content({ place => 'bottom' }), qr{\A$content\n*\[.+\)\Z}s,
  'badges at bottom';

done_testing;
