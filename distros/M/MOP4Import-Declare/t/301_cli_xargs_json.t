#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
use File::Basename qw(dirname);

use Test::More;
use Test2::Tools::Command;

my $dist_root = dirname($FindBin::Bin);

command {
  args => ["$dist_root/Base/CLI_JSON.pm"]
    , status => 255
    , stderr => qr/^Usage: /
};

SKIP: {
  skip "unknown error in perl 5.16-buster", 1
    if $] <= 5.018;

  command {
    args => ["$dist_root/Base/CLI_JSON.pm", qw(cli_xargs_json cli_array)]
      , stdin => qq{{}},
      , stdout => qq{[{}]\n}
    };
}

done_testing();
