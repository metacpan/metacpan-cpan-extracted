#!/usr/bin/perl

# $Id$
#
# This is just a crude example of how to use Lyrics::Fetcher.
# David Precious, <davidp@preshweb.co.uk> / http://blog.preshweb.co.uk/

use strict;
use lib './lib/';


use Lyrics::Fetcher;
$Lyrics::Fetcher::debug = 1;


print "Lyrics::Fetcher version: " . $Lyrics::Fetcher::VERSION . "\n";
my ($artist, $song) = ('Oasis', 'Some Might Say');
print "Looking for lyrics for $song by $artist\n";
print Lyrics::Fetcher->fetch($artist, $song, [qw(AZLyrics LyricWiki AstraWeb)]);

print "\n\nLyrics returned by fetcher $Lyrics::Fetcher::Fetcher\n";
