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

use_ok("MOP4Import::Util");

BEGIN {
  local @INC = ("$FindBin::Bin/examples", @INC);
  require t_Case05;
  import t_Case05;
}

is_deeply [MOP4Import::Util::list_validator("t_Case05::Foo")]
  , [name => +{isa => 'Str', default => 'unknown'},
     age => +{isa => 'Int', default => 20},
   ], "list_validator(t_Case05::Foo)";

done_testing();
