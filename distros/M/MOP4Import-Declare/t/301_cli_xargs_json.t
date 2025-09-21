#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }

use Test::More;
use Test2::Tools::Command;

ok chdir("$FindBin::Bin/../Base"), "chdir to MOP4Import/Base";

command {
  args => [qw(./CLI_JSON.pm)]
    , status => 255
    , stderr => qr/^Usage: /
};

SKIP: {
  skip "unknown error in perl 5.16-buster", 1
    if $] <= 5.018;

  command {
    args => [qw(./CLI_JSON.pm cli_xargs_json cli_array)]
      , stdin => qq{{}},
      , stdout => qq{[{}]\n}
    };
}

done_testing();
