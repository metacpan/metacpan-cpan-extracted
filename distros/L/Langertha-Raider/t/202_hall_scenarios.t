#!/usr/bin/env perl
# ABSTRACT: Hall scenario suite: a real hall in its own process, real raiders on the scripted model (t/scenarios/hall/*.yml)
use strict;
use warnings;
use utf8;
use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/lib";
use Path::Tiny;
use YAML::PP;
BEGIN {
  eval { require Langertha::Engine::Virtual; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504 or later)';
}
use Test::Raider::HallScenario qw( free_port run_hall_scenario );

# Each F<t/scenarios/hall/NN-name.yml> is one story of a hall end to end: a
# hall in a process of its own, real raider processes started by it that
# answer from rules instead of a model (-e mock), driven over the control
# socket and an ACP connection. The format is described in
# Test::Raider::HallScenario ("SCENARIO FORMAT"). A new scenario is a new
# file; nothing here changes. Only scenarios with `skip:` (a reason) are
# skipped, so a known gap stays visible. HALL_SCENARIO_DEBUG=1 prints the hall's
# events and logs of every scenario.

free_port() or plan skip_all => "cannot bind local TCP socket: $!";

my $yaml  = YAML::PP->new( boolean => 'JSON::PP' );
my @files = sort glob "$FindBin::Bin/scenarios/hall/*.yml";
# HALL_SCENARIO_ONLY=regex runs only the scenario files whose name matches.
@files = grep { path($_)->basename =~ /$ENV{HALL_SCENARIO_ONLY}/ } @files if $ENV{HALL_SCENARIO_ONLY};
ok( scalar @files, 'there are hall scenarios' );

for my $file (@files) {
  my $s    = $yaml->load_file($file);
  my $name = path($file)->basename;
  subtest "$name: " . ( $s->{title} // '' ) => sub {
    skip_all $s->{skip} if $s->{skip};
    run_hall_scenario($s);
  };
}

done_testing;
