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
# Tests commands issued from Debug::Fork::Tmux.
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
use Test::More;    # Continues till done_testing()

# Loads main app module
use Debug::Fork::Tmux;

# Catches exceptions
use Test::Exception;

# Withholds a perl binary fully qualified file name
use Config;

### CONSTANTS ###
#
# Makes constants possible
use Const::Fast;

# Fully qualified file name of the perl binary
# Requires  :   Config
const my $PERL_BIN_FQFN => $Config{'perlpath'};

# All of the command line parameters comman for every perl command run
# Depends   :   On PERL_BIN_FQFN package lexical
const my @PERL_RUN_COMMON => ( $PERL_BIN_FQFN, '-Mstrict', '-we' );

# Empty command to test croak()ing
const my $EMPTY_COMMAND => 'There were no any command';

# Empty command message to test croak()ing
const my $EMPTY_COMMAND_MSG => 'Trial of croak_on_cmd';

# Empty command result regex
# Depends   :   On $EMPTY_COMMAND, $EMPTY_COMMAND_RGX package lexicals
my $EMPTY_COMMAND_RGX = join ' ', "The command", $EMPTY_COMMAND,
    $EMPTY_COMMAND_MSG, "child exited with value 0 at $0 line \\d+\\.?\$";
const $EMPTY_COMMAND_RGX => qr/$EMPTY_COMMAND_RGX/;

# Single line to print in a one-liner
const my $ONE_LINER_SINGLE_LINE => 'Single line of a text';

# Double line to print in a one-liner
# Depends   :   On $ONE_LINER_SINGLE_LINE
const my $ONE_LINER_DOUBLE_LINE =>
    "$ONE_LINER_SINGLE_LINE\\nSecond line of a text";

### Message to throw in a one-liner printing double line
# Depends   :   On @PERL_RUN_COMMON, $ONE_LINER_DOUBLE_LINE package lexicals
my $ONE_LINER_DOUBLE_LINE_RGX = join ' ', '^The command', @PERL_RUN_COMMON,
    "print \"$ONE_LINER_DOUBLE_LINE\\n\"";

# For one-liner to match 'perl -e "\n"'
$ONE_LINER_DOUBLE_LINE_RGX =~ s/\\/\\\\/g;
$ONE_LINER_DOUBLE_LINE_RGX = join ' ', $ONE_LINER_DOUBLE_LINE_RGX,
    'did not finish: .* child exited with value 0 at', $0, 'line \d+\.?$';
const $ONE_LINER_DOUBLE_LINE_RGX => qr/$ONE_LINER_DOUBLE_LINE_RGX/;

# Emptyness print command result regex
# Depends   :   On $EMPTY_COMMAND, $EMPTY_COMMAND_RGX, @PERL_RUN_COMMON package lexicals
my $EMPTYNESS_COMMAND_RGX = join ' ', "The command", @PERL_RUN_COMMON,
    ';', "didn't write a line",
    "child exited with value 0 at $0 line \\d+\\.?\$";
const $EMPTYNESS_COMMAND_RGX => qr/$EMPTYNESS_COMMAND_RGX/;

# Emptyness print command result regex
# Depends   :   On $EMPTY_COMMAND, $EMPTY_COMMAND_RGX, @PERL_RUN_COMMON package lexicals
my $EMPTY_STR_COMMAND_RGX = join ' ', "The command", @PERL_RUN_COMMON,
    'print "\\n";', "provided empty string",
    "child exited with value 0 at $0 line \\d+\\.?\$";
const $EMPTY_STR_COMMAND_RGX => qr/$EMPTYNESS_COMMAND_RGX/;

### SUBS ###
#
# Function
# Croaks on an unexistent command
# Takes     :   n/a
# Depends   :   On $EMPTY_COMMAND, $EMPTY_COMMAND_MSG package lexicals
# Throws    :   In Debug::Fork::Tmux
# Returns   :   n/a
sub croak_without_cmd {
    Debug::Fork::Tmux::_croak_on_cmd( $EMPTY_COMMAND => $EMPTY_COMMAND_MSG );
}

### MAIN ###
# Require   :   Test::Most, Test::Exception
#
# Checks if perl binary runs
BAIL_OUT("died unexpectedly: $!")
    unless lives_ok { system @PERL_RUN_COMMON, ';' } 'Perl binary runs ok';

# Empty command dying
BAIL_OUT("didn't die  unexpectedly")
    unless dies_ok { croak_without_cmd(); } '_croak_on_cmd() dies';
throws_ok { croak_without_cmd(); }
( $EMPTY_COMMAND_RGX, 'croak_on_cmd() throws correct string', );

# Reads a single line correctly
BAIL_OUT("died unexpectedly: $!")
    unless lives_ok {
    Debug::Fork::Tmux::_read_from_cmd( @PERL_RUN_COMMON,
        "print \"$ONE_LINER_SINGLE_LINE\\n\"" );
}
'One-liner survives reading single line';

# Dies reading a double line
BAIL_OUT("didn't die  unexpectedly")
    unless dies_ok {
    Debug::Fork::Tmux::_read_from_cmd( @PERL_RUN_COMMON,
        "print \"$ONE_LINER_DOUBLE_LINE\\n\"" );
}
'One-liner causes Debug::Fork::Tmux to die reading double line';

# Dies with a correct message reading a double line
throws_ok {
    Debug::Fork::Tmux::_read_from_cmd( @PERL_RUN_COMMON,
        "print \"$ONE_LINER_DOUBLE_LINE\\n\"" );
}
$ONE_LINER_DOUBLE_LINE_RGX,
    'One-liner causes Debug::Fork::Tmux to throw correct string reading double line';

# Dies reading emptyness
BAIL_OUT("didn't die  unexpectedly")
    unless dies_ok {
    Debug::Fork::Tmux::_read_from_cmd( @PERL_RUN_COMMON, ";" );
}
'One-liner causes Debug::Fork::Tmux to die reading emptyness';

# Dies with a correct message reading emptyness
throws_ok {
    Debug::Fork::Tmux::_read_from_cmd( @PERL_RUN_COMMON, ";" );
}
$EMPTYNESS_COMMAND_RGX,
    'One-liner causes Debug::Fork::Tmux to throw correct string reading emptyness';

# Dies reading empty string
BAIL_OUT("didn't die  unexpectedly")
    unless dies_ok {
    Debug::Fork::Tmux::_read_from_cmd( @PERL_RUN_COMMON, 'print "\n";' );
}
'One-liner causes Debug::Fork::Tmux to die reading empty string';

# Dies with a correct message reading empty string
throws_ok {
    Debug::Fork::Tmux::_read_from_cmd( @PERL_RUN_COMMON, ";" );
}
$EMPTY_STR_COMMAND_RGX,
    'One-liner causes Debug::Fork::Tmux to throw correct string reading empty string';

BAIL_OUT("died unexpectedly: $!")
    unless lives_and {
    is( my $str
            = Debug::Fork::Tmux::_read_from_cmd( @PERL_RUN_COMMON,
            "print \"$ONE_LINER_SINGLE_LINE\\n\"" ) => $ONE_LINER_SINGLE_LINE,
        'One-liner supplies correct string'
    );
}
'One-liner supplies correct string without exception';

# Continues till this point
# Requires  :   Test::More
done_testing();
