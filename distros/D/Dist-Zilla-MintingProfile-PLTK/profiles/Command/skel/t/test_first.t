#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../lib";

use Test::More;
use App::Cmd::Tester;
use File::Slurp;

use Text::Toolkit::PLTK;

#  use_ok etc. here

done_testing();