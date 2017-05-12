#!/usr/bin/perl
=head1 NAME

examples/scan.pl

=head1 SYNOPSIS

perl scan.pl /path/to/itunes/music/library.xml

=head1 DESCRIPTION

Parse an iTunes XML library and do something to each song

=cut

use warnings;
use strict;

use lib '../lib';
use Mac::iTunes::Library;
use Mac::iTunes::Library::XML;
use Mac::iTunes::Library::Item;

my $usage = "Usage: scan.pl <library.xml>\n";

die $usage if (scalar(@ARGV) != 1);
my $file = $ARGV[0];

# Make a new Library
print "Loading '$file'...";
my $library = Mac::iTunes::Library::XML->parse($file);
print " loaded " . $library->num() . " items.\n"; 

# Get the hash of items
my %items = $library->items();

foreach my $artist ( sort keys %items ) {
    print "$artist\n";

    # $artistSongs is a hash-ref
    my $artistSongs = $items{$artist};

    # Dereference $artistSongs so that you can pass it to keys()
    # $songName is a key in the $artistSongs hash-ref
    foreach my $songName (sort keys %$artistSongs) {
        # The songs are stored as an array, because there can
        # be multiple songs with identical names
        my $artistSongItems = $artistSongs->{$songName};

        # Go through all of the songs in the array-ref
        foreach my $song (@$artistSongItems) {
            print "    " . $song->name() . "\n";
        }
    }
}

=head1 SEE ALSO

L<Mac::iTunes::Library>

=head1 AUTHOR

Scott Lawrence (http://linkedin.com/in/scottdlawrence)

=head1 CONTRIBUTORS

Drew Stephens <drew@dinomite.net>, http://dinomite.net

=head1 SVN INFO

$Revision: 52 $
$Date: 2008-08-05 23:38:33 -0700 (Tue, 05 Aug 2008) $
$Author: drewgstephens $

=cut

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Drew Stephens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
