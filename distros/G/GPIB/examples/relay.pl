#!/usr/bin/perl

# Jeff Mock
# 1859 Scott St.
# San Francisco, CA 94115
#
# jeff@mock.com
# (c) 1999

#
# This is a really simple Tk + GPIB example.
#
# An HP59306A is a GPIB box with 6 relays.  I bought one
# for $50 on Ebay to control my Christmas lights.  This
# example creates a control panel with a check box to 
# control each relay.  This is a little bit clever by
# using an anonymous sub with a lexical to create a closure
# for each relay,  I love Perl.
#
# This runs on both NT and Linux, with local or remote 
# GPIB connections.
#
# Exercise for the reader to add a button to flash the lights
# in a festive manner.
#

use Tk;
use GPIB::hp59306a;

$device = "HP59306A";

# Open the relay box
$g = GPIB::hp59306a->new($device);

# Initial state for relays
@cv = (0,0,0,0,0,0,0);

# Create a window
$mw = MainWindow->new();
$mw->title("HP59306A Demo");

for (1..6) {
    # Create a checkbox for each window
    my $i = $_;     # Need a lexical to create a closure for -command
    $mw->Checkbutton(
        -text               => "Relay $i",
        -variable           => \${cv[$i]},
        -command            => sub { $g->setRelay($i, $cv[$i]); },
    )->pack;
}

# Tk takes care of everything else
MainLoop;
