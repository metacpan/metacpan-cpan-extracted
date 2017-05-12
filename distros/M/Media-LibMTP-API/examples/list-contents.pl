#! /usr/bin/env perl
#---------------------------------------------------------------------
# Created by Christopher J. Madsen
#
# This example script is in the public domain.
#
# List folders, albums, and tracks on a device
#---------------------------------------------------------------------

use strict;
use warnings;
use 5.010;

use Media::LibMTP::API qw(Get_First_Device);

my $device;

while (1) {
  $device = Get_First_Device() and last;
  say STDERR "Trying again in 5 seconds...";
  sleep 5;
}

#say Media::LibMTP::API::Get_Friendlyname($device);
say STDERR "Connected to " . $device->Get_Friendlyname;

say "\nFolders:";
my $root = $device->Get_Folder_List;

my %folder;

printTree($root);

sub printTree
{
  my ($node, $level) = @_;

  return unless defined $node;

  my $id = $node->folder_id;
  $folder{$id} = $node->name . " ($id)";

  $level //= 0;

  say('  ' x $level, $folder{$id});

  printTree($node->child, $level+1);

  printTree($node->sibling, $level);
} # end printTree

say "\nAlbums:";
my $album = $device->Get_Album_List;

while ($album) {
  say "Title:    " . $album->name . ' (' . $album->album_id . ')';
  say "Artist:   " . ($album->artist // 'Unknown Artist');
  say "Parent:   " . $album->parent_id;
  say "Storage:  " . $album->storage_id;
  say "Composer: " . ($album->composer // 'Unknown Composer');
  say "Genre:    " . ($album->genre // 'Unknown Genre');

#  say "Tracks: " . join(', ', $album->tracks) . ' (' . $album->no_tracks . ')';
  say "Tracks: " . join(', ', @{$album->tracks}) . ' (' . $album->no_tracks . ')';
  print "\n";

  $album = $album->next;
} # end while $album

say "\nTracks:";
my $track = $device->Get_Tracklisting;

while ($track) {
  say "Parent: $folder{$track->parent_id}";
  say "Track#: " . $track->tracknumber;
  say "Title:  " . ($track->title // 'Unknown Title')
                 . ' (' . $track->item_id . ')';
  say "Artist: " . ($track->artist // 'Unknown Artist');
  say "Album:  " . ($track->album // 'Unknown Album');
  say "File:   " . ($track->filename // '');

  print "\n";

  $track = $track->next;
} # end while $track

undef $device;
