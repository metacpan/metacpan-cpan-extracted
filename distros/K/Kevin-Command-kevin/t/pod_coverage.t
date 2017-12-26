use Mojo::Base -strict;

use Test::More 0.88;

plan skip_all => 'set TEST_POD to enable this test (developer only!)'
  unless $ENV{TEST_POD};
plan skip_all => 'Test::Pod::Coverage 1.04+ required for this test!'
  unless eval 'use Test::Pod::Coverage 1.04; 1';

#all_pod_coverage_ok();
pod_coverage_ok('Kevin::Command::kevin');
pod_coverage_ok('Kevin::Command::kevin::jobs');
pod_coverage_ok('Kevin::Command::kevin::worker');
pod_coverage_ok('Kevin::Command::kevin::workers');
pod_coverage_ok('Mojolicious::Plugin::Kevin::Commands');

TODO: {
  local $TODO = 'Internal use';
  pod_coverage_ok('Kevin::Commands::Util');
}
TODO: {
  local $TODO = 'No pod yet';
  pod_coverage_ok('Minion::Worker::Role::Kevin');
}

done_testing;
