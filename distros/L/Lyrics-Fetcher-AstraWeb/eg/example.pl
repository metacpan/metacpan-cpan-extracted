#!/usr/bin/perl


# A quick, simple example of using this module via Lyrics::Fetcher.
# 
#
# $Id: example.pl 248 2008-02-19 19:37:57Z davidp $

use strict;
use warnings;
use Lyrics::Fetcher;

my ($artist, $title) = @ARGV;

if (!$artist || !$title) {
    print "Usage: $0 artist title\n";
    exit;
}

print "Fetching lyrics for $title by $artist\n";

if (my $lyrics = Lyrics::Fetcher->fetch($artist, $title, 'AstraWeb')) 
{
    print "Got lyrics:\n$lyrics\n";
} else {
    die "Failed to fetch lyrics ($Lyrics::Fetcher::Error)\n";
}
