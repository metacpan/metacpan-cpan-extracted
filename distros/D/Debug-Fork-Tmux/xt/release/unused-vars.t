#!perl
#
# This file is part of Debug-Fork-Tmux
#
# This software is Copyright (c) 2013 by Peter Vereshagin.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#

use Test::More;

eval "use Test::Vars";
plan skip_all => "Test::Vars required for testing unused vars"
    if $@;
all_vars_ok();
