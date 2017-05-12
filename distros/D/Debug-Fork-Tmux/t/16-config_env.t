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
use Test::Most;    # Continues till done_testing();

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
# Test if DFTMUX_* variables do not warn
# Depends   :   On %ENV global of main::, %ENV_VARS package lexical
# Changes   :   %ENV localized global of main::
warning_is {

    # keep from change the system environment
    local %ENV = %ENV_VARS;

    # Loads main app module
    use_ok('Debug::Fork::Tmux::Config');  # Environment variables set up clean

    # Check if config keys are in sync
    my @all_config_keys = Debug::Fork::Tmux::Config->get_all_config_keys;
    cmp_bag(
        \@all_config_keys => \@CONF_KEYS,
        'This test keeps config keys in sync'
    );

    while ( my ( $key => $value ) = each %CONF_PAIRS ) {
        ok( $value = Debug::Fork::Tmux::Config->get_config($key) =>
                "Get config for '$key'" );
        is( ref($value) => '', "Value for '$key' is a scalar" );
        ok( length($value) => "Value for '$key' is non-empty" );

        # Compare ->get_config() result with %ENV element
        is( $value => $CONF_PAIRS{$key},
            "Value for '$key' from config is as expected from %ENV",
        );
    }
}
undef, 'DFTMUX_* variables do not warn';

# Test reading from environment to config
# particular arbitrary variables to particular config
warning_is {
    my %conf   = qw{lorem ipsum dolor sit};
    my $prefix = 'AMET_';
    local $ENV{'AMET_LOREM'} = 'consectetur';

    # Run sub with test arguments
    Debug::Fork::Tmux::Config::_env_to_conf( \%conf, $prefix );

    # Compare with result required
    my $conf_required = {qw{lorem consectetur dolor sit}};
    cmp_deeply(
        \%conf => $conf_required,
        'Configured from AMET_LOREM environment variable as required',
    );

}
undef, 'AMET_* prefix reads from environment without warnings';

# Test reading from deprecated environment to config
# particular arbitrary variables to particular config
warning_like {
    my %conf   = qw{lorem ipsum dolor sit};
    my $prefix = 'ADIPISICING_';
    local $ENV{'ADIPISICING_LOREM'} = 'consectetur';

    # Run sub with test arguments
    Debug::Fork::Tmux::Config::_env_to_conf(
        \%conf,
        $prefix,
        sub {
            warn sprintf(
                "%s is deprecated and will be unsupported" => shift );
        }
    );

    # Compare with result required
    my $conf_required = {qw{lorem consectetur dolor sit}};
    cmp_deeply(
        \%conf => $conf_required,
        'Configured from ADIPISICING_LOREM environment variable as required',
    );

}
qr{deprecated},
    'ADIPISICING_* prefix reads from environment with deprecation warning';

# Test paths
is( Debug::Fork::Tmux::Config::_default_tmux_path() => 2,
    'For no PATH, the _default_tmux_path() still find 2 directories',
);

# Continues till this point
done_testing();
