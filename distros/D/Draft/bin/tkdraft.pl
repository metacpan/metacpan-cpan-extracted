#!/usr/bin/perl

use strict;
use warnings;
use lib 'lib';
use Draft;
use Draft::TkGui;

# Reads a drawing from disk and displays it in a Tk window.

$Draft::PATH = $ARGV[0] || die "Usage: $0 /path/to/data.drawing/\n";

Draft->Read;

my $canvas = Draft::TkGui->new;

$canvas->viewAll;

$canvas->MainLoop;

1;
