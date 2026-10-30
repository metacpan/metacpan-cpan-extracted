#!/usr/bin/env perl
# ABSTRACT: Scenario suite: a scripted model drives the real raider and its real tools (t/scenarios/*.yml)
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

# Each F<t/scenarios/NN-name.yml> is one step of what raider has to do end to
# end; the keys of a scenario are documented in Test::Raider::Scenario.

my @files = sort glob "$FindBin::Bin/scenarios/*.yml";
ok( scalar @files, 'there are scenarios' );

run_scenario_files(@files);

done_testing;
