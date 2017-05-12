#!/usr/bin/perl
=head1 NAME

examples/iTunesStats.pl

=head1 SYNOPSIS

perl iTunesStats.pl /path/to/itunes/music/library.xml num_top_items

=head1 DESCRIPTION

Parse iTunes XML libraries and print some aggregate statistics.

=cut

use warnings;
use strict;

use lib '../lib';
use Mac::iTunes::Library;
use Mac::iTunes::Library::Item;
use Mac::iTunes::Library::XML;

my $usage = "iTunesStats.pl library.xml top_x_number\n";

die $usage if (scalar(@ARGV) != 2);
my $file = $ARGV[0];
my $topNum = $ARGV[1];

# Make a new Library
my $library = Mac::iTunes::Library->new();
$library = Mac::iTunes::Library::XML->parse($file);

# Make some numbers
my $librarySize = $library->size()/(1024**2);
my $numTracks = $library->num();

my $totalTime = $library->time()/1000;
my $days = int($totalTime/60/60/24);
my $hours = int($totalTime/60/60%24);
my $minutes = int($totalTime/60%60);
my $seconds = $totalTime%60;
my $averageTime = ($totalTime/$library->num());
my $averageMinutes = int($averageTime/60);
my $averageSeconds = int($averageTime%60);
my %artists = $library->artist();

# Total tracks
print "Number of tracks: " . $numTracks . "\n";

# Size
printf "Total size: %.2f MB\t\t", $librarySize;
printf "Average size: %.2f MB\n", $librarySize/$numTracks;

# Time
print "Total time: ${days}d ${hours}h ${minutes}m ${seconds}s\t";
print "Average time: ${averageMinutes}m${averageSeconds}s\n";

# Ratio of songs/artists
print "Ratio of songs/artists: " . $numTracks/(keys %artists) . "\n";

# Artists
print "\nMost popular artists, by number of tracks:\n";
&top($topNum, $library->artist());

# Artists, playcount
print "\nMost popular artists, by playcount:\n";
&top($topNum, $library->partist());

# Album Artists
print "\nMost popular album artists, by number of tracks:\n";
&top($topNum, $library->albumArtist());

# Album Artists, playcount
print "\nMost popular album artists, by playcount:\n";
&top($topNum, $library->palbumArtist());

# Genres
print "\nMost popular genres, by number of tracks:\n";
&top($topNum, $library->genre());

# Genres, playcount
print "\nMost popular genres, by playcount:\n";
&top($topNum, $library->pgenre());


# Print the top n of a string->int hash
sub top {
    my($num, %hash) = @_;

    my %reverse;
    foreach my $artist ( keys %hash ) {
        my $count = $hash{$artist};

        if (exists $reverse{$count}) {
            unshift @{$reverse{ $count }}, $artist;
        } else {
            $reverse{ $count } = [$artist];
        }
    } #foreach

    # Sort the reverse keyset and print the $topNum
    my @sorted = sort by_number keys(%reverse);
    my $count = 0;
    foreach my $numTracks (@sorted) {
        last if ($count == $topNum);
        my @artists = @{$reverse{$numTracks}};
        print "\t$numTracks\t";

        for (my $x = 0; $x < scalar(@artists); $x++) {
            print ", " if ($x > 0);
            print $artists[$x];
        } #for

        print "\n";

        $count++;
    } #foreach
} #top

sub by_number {
    # Sort subroutine; expect $a and $b
    if ($a > $b) { -1 } elsif ($a < $b) { 1 } else { 0 }
} #by_number

=head1 SEE ALSO

L<Mac::iTunes::Library>

=head1 AUTHOR

Drew Stephens <drew@dinomite.net>, http://dinomite.net

=head1 SVN INFO

$Revision: 72 $
$Date: 2009-10-28 22:10:20 -0700 (Wed, 28 Oct 2009) $
$Author: drewgstephens $

=cut

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Drew Stephens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
