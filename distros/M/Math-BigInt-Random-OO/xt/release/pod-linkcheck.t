# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;

foreach my $env_skip (qw(
                            SKIP_POD_LINKCHECK
                       ))
{
    plan skip_all => "\$ENV{$env_skip} is set, skipping"
      if $ENV{$env_skip};
}

eval "use Test::Pod::LinkCheck";
plan skip_all => 'Test::Pod::LinkCheck required for testing POD links'
  if $@;

Test::Pod::LinkCheck -> new() -> all_pod_ok();
