#!/usr/bin/perl

# Simple example to create an inlay card for a given directory, or the current
# directory if no directory is specified.
#
# $Id: createinlay.pl 444 2008-09-04 18:55:10Z davidp $

use strict;
use Cwd;
use MP3::CreateInlayCard;


print MP3::CreateInlayCard::create_inlay({
    dir => $ARGV[0] || getcwd, 
    template => $ARGV[1],
});
