#!/usr/bin/perl

#use warnings; # Testing
no warnings;  # Production
use strict;
use Test::More tests => 13; # One test temporarily removed
use Mac::iPod::GNUpod;
use File::Spec;

my $fakepod = File::Spec->catdir('t', 'fakepod');
my $mp3 = File::Spec->catfile('t', 'test.mp3');
my $accent = File::Spec->catfile('t', 'accented.mp3');

# This test adds/removes files
{
    my $ipod = Mac::iPod::GNUpod->new(mountpoint => $fakepod);

    # Add a file
    my $id;
    ok $id = $ipod->add_song($mp3), "Adding $mp3";
    # Is it actually there?
    my($path) = $ipod->get_path($id);
    ok -e $path, "$mp3 successfully moved";
    # In the db?
    is scalar($ipod->all_songs), 1, "Song added to DB";

    # Do the same w/ a song with a weird name
    $ipod->allow_dup(1);
    ok $id = $ipod->add_song($accent), "Adding $accent";
    my $path = $ipod->get_path($id);
    ok -e $path, "$accent successfully moved";
    my $fh = $ipod->get_song($id);
    is $fh->{title}->latin1, "Áccèñtëd Song", "Accents correctly handled";
    $ipod->allow_dup(0);


    # Rm the file
    ok $ipod->rm_song($id), "Removing test.mp3";
    # Is it gone?
    ok((not -e $path), "Song successfully removed");
    # Not in db?
    is scalar($ipod->all_songs), 1, "Song rmed from DB";
}

# Test finding duplicates
{
    my $ipod = Mac::iPod::GNUpod->new(mountpoint => $fakepod);
    
    my $id0 = $ipod->add_song($mp3);
    # This should fail
    my $id1 = $ipod->add_song($mp3);
    ok((not $id1), "Add failed on duplicate");

    # Try again, turning duplicate checking off
    $ipod->allow_dup(1);
    my $id2 = $ipod->add_song($mp3);
    ok $id2, "Duplicate succeeded w/ allow_dup on";

    # Check there are two actual files on disk
    my ($path1, $path2) = $ipod->get_path($id0, $id2);
    ok((-e $path1 && -e $path2), 'Both songs exist on disk');

    # Cleanup: rm all songs
    $ipod->rm_song($ipod->all_songs);
}

# Test obedience of move_files
{
    my $ipod = Mac::iPod::GNUpod->new(mountpoint => $fakepod);

    # Don't move the file
    $ipod->move_files(0);
    my $id = $ipod->add_song($mp3);
    my $path = $ipod->get_path($id);
    #ok((not -f $path), "No path for new $mp3");
    $ipod->rm_song($id); # Out of DB!
    # Is the preceding test meaningful? The return of get_path when move_files
    # is off is pure garbage.

    # Ok, now move the file
    $ipod->move_files(1);
    $id = $ipod->add_song($mp3);
    ($path) = $ipod->get_path($id);
    # Rm the song w/ move_files off
    $ipod->move_files(0);
    $ipod->rm_song($id);
    ok -e $path, "File still exists";

}

# Final cleanup
#unlink glob './t/fakepod/iPod_Control/Music/*/*';
