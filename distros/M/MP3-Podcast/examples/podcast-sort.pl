#!/usr/bin/perl

use lib "../lib";
use MP3::Podcast;

#Generates a podcast from directories handled in the command line

my $dirbase = shift || die "Base dir missing\n";
my $urlbase = shift || die "Base URL missing\n";
my $dir = shift || die "Dir to scan missing\n";

my $pod = MP3::Podcast->new($dirbase,$urlbase);
my $rss = $pod->podcast( $dir, "Podcast test", "JJ", "Love Potion #9", 1 ); #Last one for sort

print $rss->as_string;
