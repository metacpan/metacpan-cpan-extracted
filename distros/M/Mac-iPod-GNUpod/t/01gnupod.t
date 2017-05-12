#!/usr/bin/perl

# This file tests reading and writing the GNUpod DB w/ playlist support

#use warnings; # Testing
no warnings;  # Production
use strict;
use Test::More tests => 10;
use Mac::iPod::GNUpod;
use File::Spec;

my $test = File::Spec->catfile('t', 'test.xml');
my $test2 = File::Spec->catfile('t', 'test2.xml');
my $null = File::Spec->devnull;
my $crazy = File::Spec->catfile('t', 'crazy.xml');
my $crazy2 = File::Spec->catfile('t', 'crazy2.xml');

# Read and write normal file
{
    my $ipod = Mac::iPod::GNUpod->new(gnupod_db => $test, itunes_db => $null);

    ok $ipod->read_gnupod, "Read GNUpod";

    # Test playlists
    ok $ipod->rm_pl("IDs"), "Remove a playlist";
    ok $ipod->add_pl("Programmed", 1, { title => '[Tt]enpo' }, { artist => "Soundtrack", exact => 1 }, { album => 'inc', nocase => 1 }, 3), "Add a playlist";

    # Write to a different file
    $ipod->gnupod_db($test2);
    ok $ipod->write_gnupod, "Write GNUpod";

    # Reread, check sameness
    my $ipod2 = Mac::iPod::GNUpod->new(gnupod_db => $test2, itunes_db => $null);
    $ipod2->read_gnupod;
    is_deeply $ipod, $ipod2, "Read/write results in same structure";

    # Test playlist rendering
    is_deeply [ $ipod->get_pl("Programmed") ], [ $ipod2->get_pl("Programmed") ], "Got playlists";
    is_deeply [ $ipod->render_pl("Programmed") ], [ $ipod2->render_pl("Programmed") ], "Rendered playlists";

    # Cleanup
    unlink $test2;
}

# Read the crazy file
{
    my $ipod = Mac::iPod::GNUpod->new(gnupod_db => $crazy, itunes_db => $null);

    ok $ipod->read_gnupod, "Read crazy GNUpod";

    # Write, reread
    $ipod->gnupod_db($crazy2);
    $ipod->write_gnupod;
    my $ipod2 = Mac::iPod::GNUpod->new(gnupod_db => $crazy2, itunes_db => $null);
    $ipod2->read_gnupod;

    # is_deeply can't succeed (diff order of items), so we'll check manually
    
    # We also cheat, because the notorig key in the file hashes will not be the
    # same (and should not be). So we manually copy over before checking
    # everything else.
    for (@{$ipod->{files}}) {
        next unless ref $_ eq 'HASH';
        delete $_->{notorig};
    }
    is_deeply $ipod->{files}, $ipod2->{files}, "All files OK";
    is_deeply $ipod->{pl_idx}, $ipod2->{pl_idx}, "All pls OK";

    # Cleanup
    unlink $crazy2;
}
