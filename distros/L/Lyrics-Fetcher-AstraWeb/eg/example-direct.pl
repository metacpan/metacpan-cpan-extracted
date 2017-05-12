#!/usr/bin/perl


# A quick, simple example of using this module directly.
# 
# It's recommended to call it from Lyrics::Fetcher (see example.pl) rather
# than directly, but if you'd prefer to use it directly, this is how.
#
# $Id: example-direct.pl 247 2008-02-19 19:36:58Z davidp $

use strict;
use warnings;
use Lyrics::Fetcher::AstraWeb;


my ($artist, $title) = @ARGV;

if (!$artist || !$title) {
    print "Usage: $0 artist title\n";
    exit;
}

print "Fetching lyrics for $title by $artist\n";

if (my $lyrics = Lyrics::Fetcher::AstraWeb->fetch($artist, $title)) 
{
    print "Got lyrics:\n$lyrics\n";
} else {
    die "Failed to fetch lyrics ($Lyrics::Fetcher::Error)\n";
}
