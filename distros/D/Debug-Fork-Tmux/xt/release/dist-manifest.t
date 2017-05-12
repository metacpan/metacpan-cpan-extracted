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

eval "use Test::DistManifest";
plan skip_all => "Test::DistManifest required for testing the manifest"
    if $@;
manifest_ok();
