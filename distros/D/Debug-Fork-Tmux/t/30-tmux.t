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
# Tests tmux-related stuff for Debug::Fork::Tmux.
#
# Copyright (C) 2012 Peter Vereshagin <peter@vereshagin.org>
# All rights reserved.
#

# Helps you to behave
use strict;
use warnings;

# Throws exceptions on i/o
use autodie;

### MODULES ###
#
# Makes this test a test
use Test::Most qw/bail/;    # BAIL_OUT() on any failure

# Loads main app module
use Debug::Fork::Tmux;

# Catches exceptions
use Test::Exception;

# Can compare version numbers
use Sort::Versions;

# Can name anonymous subroutines for stack traces
use Sub::Name;

### CONSTANTS ###
#
# Makes constants possible
use Const::Fast;

# Match 'tmux -V' to get a version number
const my $TMUX_VERSION_RGX => qr/^(.*[-\s])?((\d+\.\d+)(\.\d+)*)$/;

# Minimum tmux version for Debug::Fork::Tmux to work with
const my $TMUX_MIN_VERSION => 1.6;

# The what the device name returned from Tmuxs hould look like
const my $TMUX_TTY_RGX =>
    qr/^(([\w\d\/]*[\w\d]\/)?\w+ty[\w\d]+)|((\/dev\/pts\/)?\d+)$/;

### SUBS ###
#
# Function
# Tests condition and ok() it, otherwise skip_all()
# Takes     :   Bool to be the argument for ok() test,
#               Str explanation for ok() test or for skip_all() control
#               structure
# Requires  :   Test::More (or Test::Most) module
# Throws    :   Does skip_all() if sub{} result isn't true
# Outputs   :   Str explanation to TAP and the 'Not ' prefix is added if
#               CodeRef supplied resulted to false
# Returns   :   n/a
sub skip_all_unless_ok {
    my ( $rv => $descr ) = @_;

    plan( 'skip_all' => "Not $descr", ) unless $rv;

}

### MAIN ###
# Require   :   Test::Most, Test::Exception
#
# Determine if it's not under tmux
# Depends   :   On %ENV global
skip_all_unless_ok(
    ( defined( $ENV{'TERM'} ) and $ENV{'TERM'} eq 'screen' ) =>
        "Inappropriate environment for tmux: TERM=" . $ENV{'TERM'}, );
skip_all_unless_ok( ( defined( $ENV{'TMUX'} ) and $ENV{'TMUX'} ) =>
        "Inppropriate environment for tmux: TERM=" . $ENV{'TERM'}, );

### Find out if tmux executes
lives_ok { system "tmux -V 2>&1 > /dev/null"; } 'tmux is found in the system';

# Compare $? with known cases
my $exit_status;
my $failure;

if ( $? == -1 ) {

    # Could not execute or find a binary
    $exit_status = $?;
    $failure     = "failed to execute: $!\n";
}
elsif ( $? & 127 ) {

    # Binary was killed with a signal, e. g. due to ulimit's
    $exit_status = $? & 127;
    $failure     = sprintf "child died with signal %d, %s coredump\n",
        $exit_status, ( $? & 128 ) ? 'with' : 'without';
}
else {

    # Binary provided an exit status
    $exit_status = $? >> 8;
    $failure = sprintf "child exited with value %d\n", $exit_status;
}

# Skip further if no binary found
skip_all_unless_ok( ( $exit_status == 0 ) =>
        "Exit status: $exit_status while executing tmux: $failure", );

# Reads output of 'tmux' for various situations
lives_and {
    my ( $buf_str => @buf_strings, $fh );

    # Read version number
    open $fh => '-|', 'tmux' => '-V';    # autodie
    $buf_str = do { local $/ = undef; <$fh>; };    # autodie
    close $fh;

    # Read the version
    # Depends   :   On Test::Most->import qw/bail/ );
    @buf_strings = split /\r*\n\r*/, $buf_str;

    # Test if output is teh single line
    skip_all_unless_ok( ( @buf_strings == 1 ) =>
            "The command 'tmux -V' doesn't provide a single line of the text",
    );
    $buf_str = shift @buf_strings;

    # Test if output is defined
    skip_all_unless_ok(
        defined($buf_str) =>
            "The command 'tmux -V' doesn't provide a defined value", );
    chomp $buf_str;

    # Test if output is non-empty
    skip_all_unless_ok(
        length($buf_str) =>
            "The command 'tmux -V' doesn't output a non-empty string", );

    # Test if output is a version
    skip_all_unless_ok( ( $buf_str =~ $TMUX_VERSION_RGX ) =>
            "The command 'tmux -V' doesn't match a version regex", );

    # Ensure the minimum Tmux version requirement
    # $2 is defined according to regex
    # Requires  :   Sort::Versions
    $buf_str =~ $TMUX_VERSION_RGX;    # tested with like() already
    my $version = $2;
    isnt(
        Sort::Versions::versioncmp( $version => $TMUX_MIN_VERSION ) => -1,
        "Tmux version '$version' is not less than the minimum"
            . " '$TMUX_MIN_VERSION'"
    );

    # Read session info
    open $fh => '-|', 'tmux' => 'info';    # autodie
    $buf_str = do { local $/ = undef; <$fh>; };    # autodie
    close $fh;

    # Test if output is a multiline
    @buf_strings = split /\r*\n\r*/, $buf_str;
    cmp_ok( @buf_strings, '>', 1,
        "The command 'tmux info' provides several lines of the text" );
}
'Tmux commands execution';

lives_and {
    my ( $window_id => $window_tty );

    # Create window and kill it
    ok( $window_id = Debug::Fork::Tmux::_read_from_cmd( qw/tmux neww -P/,
            'sleep 1000000' ) => "Created window: $window_id"
    );
    ok( length($window_id) => 'window id is not empty' );
    ok( $window_tty = Debug::Fork::Tmux::_read_from_cmd(
            qw/tmux lsp -F/ => '#{pane_tty}',
            '-t'            => $window_id,
        ) => "Found a tty $window_tty for a Tmux window: $window_id"
    );

    system( qw/tmux killw -t/, $window_id );
    is( ${^CHILD_ERROR_NATIVE} => 0, "killed window: $window_id" );

    # Create window with Spounge::DB and kill it
    ok( $window_id = Debug::Fork::Tmux::_tmux_new_window(),
        "Debug::Fork::Tmux created a Tmux window: $window_id",
    );
    ok( $window_tty = Debug::Fork::Tmux::_tmux_window_tty($window_id),
        "Debug::Fork::Tmux found a tty $window_tty for a Tmux window: $window_id",
    );
    ok( length($window_id)  => 'window id is not empty' );
    ok( length($window_tty) => 'window tty is not empty' );
    like(
        $window_tty => $TMUX_TTY_RGX,
        "window tty '$window_tty' looks like a pseudo-terminal device"
    );

    system( qw/tmux killw -t/, $window_id );
    is( ${^CHILD_ERROR_NATIVE} => 0, "killed window: $window_id" );
}
'Tmux window manipulation';

# Continues till this point
# Requires  :   Test::Most
done_testing();
