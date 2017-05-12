#! /usr/bin/env perl
#---------------------------------------------------------------------
# delete-folder.pl
# Created by Christopher J. Madsen
#
# This example script is in the public domain.
#
# Recursively delete a folder and all its contents from device
#---------------------------------------------------------------------

use 5.010;
use strict;
use warnings;

use Media::LibMTP::API qw(Get_First_Device
                          LIBMTP_FILETYPE_ALBUM LIBMTP_FILETYPE_PLAYLIST);

my $device;

while (1) {
  $device = Get_First_Device() and last;
  say STDERR "Trying again in 5 seconds...";
  sleep 5;
}

say STDERR "Connected to " . $device->Get_Friendlyname;

my $fileList   = $device->Get_Filelisting;
my $folderList = $device->Get_Folder_List;

#=====================================================================
sub folder_by_path
{
  my ($path) = @_;

  my @path = split qr!/!, $path;

  shift @path unless length $path[0];

  my $folder = $folderList;

  while (@path) {
    while ($folder->name ne $path[0]) {
      $folder = $folder->sibling // die "Can't find $path";
    }
    shift @path;
    $folder = $folder->child // die "Can't find $path" if @path
  }

  return $folder;
} # end folder_by_path

#---------------------------------------------------------------------
sub delete_folder
{
  my ($folder) = @_;

  my $id = $folder->folder_id;

  printf "Beginnning folder %s (%d)...\n", $folder->name, $id;

  my $child = $folder->child;
  while ($child) {
    delete_folder($child);
    $child = $child->sibling;
  }

  my (@albums, @playlists, @files);

  for (my $file = $fileList;  $file;  $file = $file->next) {
    next unless $file->parent_id == $id;

    given ($file->filetype) {
      when (LIBMTP_FILETYPE_ALBUM)    { push @albums,    $file }
      when (LIBMTP_FILETYPE_PLAYLIST) { push @playlists, $file }
      default                         { push @files,     $file }
    }
  }

  delete_files(playlist => @playlists);
  delete_files(album    => @albums);
  delete_files(file     => @files);

  printf "Deleting folder %s (%d)...\n", $folder->name, $id;
  delete_objects($id);
} # end delete_folder

#---------------------------------------------------------------------
sub delete_files
{
  my $type = shift;

  foreach my $file (@_) {
    printf "Deleting %s %s (%d)...\n", $type, $file->filename, $file->item_id;
    delete_objects($file->item_id);
  }
} # end delete_files

#---------------------------------------------------------------------
sub delete_objects
{
  foreach my $id (@_) {
    $device->Delete_Object($id) and die "$id failed: " . $device->errstr;
  }
} # end delete_objects

#=====================================================================
for my $path (@ARGV) {
  my $folder = folder_by_path($path);
  delete_folder($folder);
} # end for each $id in @ARGV

undef $device;
