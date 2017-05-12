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
eval 'use Test::CPAN::Meta::JSON';
plan skip_all => 'Test::CPAN::Meta::JSON required for testing META.json'
    if $@;
meta_json_ok();
