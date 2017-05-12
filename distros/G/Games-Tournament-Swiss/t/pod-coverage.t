#!perl -T

BEGIN {
    $Games::Tournament::Swiss::Config::firstround = 1;
    $Games::Tournament::Swiss::Config::algorithm  =
      'Games::Tournament::Swiss::Procedure::Dummy';
}

use Games::Tournament::Contestant::Swiss;
use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage"
  if $@;
all_pod_coverage_ok();
