#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

require_ok( 'LightWaveRF' );

my $lw = new_ok "LightWaveRF";

done_testing();