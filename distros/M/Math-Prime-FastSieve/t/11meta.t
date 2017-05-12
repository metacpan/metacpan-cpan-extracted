use strict;
use warnings;

use Test::More;

plan skip_all => 'Author tests skipped unless RELEASE_TESTING set.'
  unless $ENV{RELEASE_TESTING};

eval 'use Test::CPAN::Meta'; ## no critic (eval)
plan skip_all => 'Test::CPAN::Meta required for testing META.yml' if $@;

meta_yaml_ok();
