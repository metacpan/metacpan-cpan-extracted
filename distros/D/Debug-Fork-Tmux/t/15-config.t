#!/usr/bin/env perl
#
# This file is part of Debug-Fork-Tmux
#
# This software is Copyright (c) 2013 by Peter Vereshagin.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
# Tests configuration variables and their correspondence to environment.
#
# Copyright (C) 2012 Peter Vereshagin <peter@vereshagin.org>
# All rights reserved.
#

# Helps you to behave
use strict;
use warnings;

### MODULES ###
#
# Makes this test a test
use Test::Most qw/bail/;    # BAIL_OUT() on any failure

# Block with localized %ENV to load Debug::Fork::Tmux::Config
{

    # Clean up environment, localize it first
    # Depends   :   On %ENV global of main::
    local %ENV;    # keep from change the system environment and empty it

    # Loads main app module
    use_ok('Debug::Fork::Tmux::Config');    # No special requirements

}

### CONSTANTS ###
#
# Makes constants possible
use Const::Fast;

# Keys to get configuration for
const my @CONF_KEYS => Debug::Fork::Tmux::Config->get_all_config_keys;

ok( 0 + @CONF_KEYS => 'Configuration has keys' );

### MAIN ###
# Require   :   Test::Most, Debug::Fork::Tmux::Config
#

foreach my $key (@CONF_KEYS) {
    my $value;
    ok( $value = Debug::Fork::Tmux::Config->get_config($key) =>
            "Get config for '$key'" );
    is( ref($value) => '', "Value for '$key' is a scalar" );
    ok( length($value) => "Value for '$key' is non-empty" );
}

# Continues till this point
done_testing();

