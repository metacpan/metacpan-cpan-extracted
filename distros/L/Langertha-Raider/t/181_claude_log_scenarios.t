#!/usr/bin/env perl
# ABSTRACT: Scenarios curated from Claude Code sessions (t/scenarios/claude-logs/*.yml)
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

# Each F<t/scenarios/claude-logs/NN-name.yml> replays a piece of a real Claude
# Code session (drafted by maint/claude-log-to-scenario, then curated) against
# raider; the keys are those of t/200_scenarios.t, documented in
# Test::Raider::Scenario.

my @files = sort glob "$FindBin::Bin/scenarios/claude-logs/*.yml";
ok( scalar @files, 'there are scenarios' );

run_scenario_files(@files);

done_testing;
