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

### CONSTANTS ###
#
# Makes constants possible
use Const::Fast;

# Keys to get configuration for
# Should be sync'ed with Debug::Fork::Tmux::Config->get_all_config_keys
const my @CONF_KEYS =>
    qw/tmux_fqfn tmux_cmd_neww_exec tmux_cmd_neww tmux_cmd_tty/;

# Keys to put environment into
const my %CONF_PAIRS => map { $_ => $_ . "_value" } @CONF_KEYS;

# Environment variables those influence configuration settings
# Depends   :   On @CONF_KEYS, @CONF_VALUES package lexicals
my %ENV_VARS;

# %ENV_VARS are based on %CONF_PAIRS but keys are uppercase and with the
# 'DF' prefix
while ( my ( $key => $value ) = each %CONF_PAIRS ) {
    $key = "DF" . uc $key;
    $ENV_VARS{$key} = $value;
}

const %ENV_VARS => %ENV_VARS;

### MAIN ###
# Require   :   Test::Most, Debug::Fork::Tmux::Config
#
# Set up environment, localize it first
# Test for deprecation warning also
# Depends   :   On %ENV global of main::, %ENV_VARS package lexical
# Changes   :   %ENV localized global of main::
warning_is {

    # Set environment variables
    # keep from change the system environment
    my $key   = 'tmux_cmd_tty';
    my $value = $CONF_PAIRS{$key};
    local $ENV{ 'SPUNGE_' . uc $key } = $value;    # This generates warning

    # does not generate warning
    local $ENV{'DFTMUX_FQFN'} = $CONF_PAIRS{$key};

    # Loads main app module
    use_ok('Debug::Fork::Tmux::Config');  # Environment variables set up clean

    # Test if SPUNGE_* variable works
    ok( $value = Debug::Fork::Tmux::Config->get_config($key) =>
            "Get config for '$key'" );
    is( ref($value) => '', "Value for '$key' is a scalar" );
    ok( length($value) => "Value for '$key' is non-empty" );

    # Compare ->get_config() result with %ENV element
    is( $value => $CONF_PAIRS{$key},
        "Value for '$key' from config is as expected from %ENV",
    );
}
'SPUNGE_TMUX_CMD_TTY is deprecated and will be unsupported',
    'SPUNGE_* variable warns';

# Continues till this point
done_testing();
