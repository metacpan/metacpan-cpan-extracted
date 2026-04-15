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

use_ok("MOP4Import::Base::CLI_JSON");

my $modulinoFn = $INC{"MOP4Import/Base/CLI_JSON.pm"};

unless ($modulinoFn) {
  bail_out("CLI_JSON.pm is not loaded");
}

unless (-r $modulinoFn) {
  bail_out("CLI_JSON.pm is not readable($modulinoFn)");
}

my $dist_lib = dirname(dirname(dirname($modulinoFn)));

my @run = ($^X, "-I$dist_lib");

command {
  args => [@run, $modulinoFn]
    , status => 255
    , stderr => qr/^Usage: /
};

SKIP: {
  skip "unknown error in perl 5.16-buster", 1
    if $] <= 5.018;

  command {
    args => [@run, $modulinoFn, qw(cli_xargs_json cli_array)]
      , stdin => qq{{}},
      , stdout => qq{[{}]\n}
    };
}

done_testing();
