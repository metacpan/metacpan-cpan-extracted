#!/usr/bin/env perl
# ABSTRACT: The MCP scenarios (t/scenarios/180-*.yml upward, ADR 0029) on their own
use strict;
use warnings;
use utf8;
use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN {
  eval { require Langertha::Engine::Virtual; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504 or later)';
}
use Test::Raider::Scenario qw( run_scenario_files );

# t/200_scenarios.t runs these too, with all the others; this file runs only
# the configured-MCP-server ones (real stdio servers: t/lib/mcp-test-server.pl).

my @files = sort glob "$FindBin::Bin/scenarios/{18[0-9],21[0-9]}-mcp-*.yml";
ok( scalar @files, 'there are MCP scenarios' );

run_scenario_files(@files);

done_testing;
