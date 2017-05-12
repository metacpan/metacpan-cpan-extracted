#!/usr/bin/perl -w
#
# This file is part of Debug-Fork-Tmux
#
# This software is Copyright (c) 2013 by Peter Vereshagin.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
# test that files do not contain soft breakpoints

use strict;
use warnings;

use Test::More;

eval "use Test::NoBreakpoints 0.10";    ## no critic
plan skip_all => "Test::NoBreakpoints 0.10 required for testing" if $@;

all_files_no_breakpoints_ok();

done_testing();
