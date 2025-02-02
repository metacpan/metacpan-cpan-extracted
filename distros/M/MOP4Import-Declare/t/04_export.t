#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }

use File::Basename;
use File::Spec;

use Test::More;
use Test::Output;
use Capture::Tiny qw(capture_stdout);

use_ok("MOP4Import::Util::Inspector");


{
  BEGIN {
    local @INC = ("$FindBin::Bin/examples", @INC);
    require t_Case04;
    import t_Case04;
  }

  is foo().bar().baz(), "FOOBARBAZ", "\@EXPORT worked"
}

done_testing;
