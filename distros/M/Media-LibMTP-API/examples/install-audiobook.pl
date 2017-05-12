#! /usr/bin/env perl
#---------------------------------------------------------------------
# install-audiobook.pl
# Created by Christopher J. Madsen
#
# This example script is in the public domain.
#
# Copy an audiobook to your player
#---------------------------------------------------------------------

use strict;
use warnings;
use 5.010;

use Image::Size qw(imgsize); # Comment this out if you don't have cover images
use Path::Class qw(dir);
use Lingua::Conjunction qw(conjunction);
Lingua::Conjunction->connector('&');

use Media::LibMTP::API qw(Get_First_Device LIBMTP_FILETYPE_JPEG
                          LIBMTP_FILETYPE_OGG);

# This script is specific to the way I handle my audiobooks, but you
# may be able to adapt it to your needs.  I have a basic M3U playlist
# named book.m3u, which lists the tracks in OGG format.
#
# On my device, books are stored under the Audiobooks top-level folder,
# first in a folder by author, then by title.

my $audiobook_folder_name = 'Audiobooks';
my $playlist_filename     = 'book.m3u';
my $cover_filename        = 'cover.jpg';

#---------------------------------------------------------------------
# First, we open the MTP device.  For some reason, this tends to fail
# on the first try, but will usually succeed if you keep trying.

my $device;

while (1) {
  $device = Get_First_Device() and last;
  say STDERR "Trying again in 5 seconds...";
  sleep 5;
}

#=====================================================================
# Routines to deal with finding/creating folders:
#---------------------------------------------------------------------
# Find an existing child folder by name:
#
# Input:
#   folder: the parent Folder object
#   name:   the folder name we're looking for
#
# Returns:
#   The desired Folder object, or undef if not found
#
# Notes:
#   Only the immediate children of folder are searched

sub find_folder
{
  my ($folder, $name) = @_;

  while ($folder and $folder->name ne $name) {
    $folder = $folder->sibling;
  }

  return $folder;
} # end find_folder

#---------------------------------------------------------------------
# Create a new folder:
#
# Input:
#   name:       the new folder name
#   parent_id:  the folder ID of the parent folder
#   storage_id: the storage ID of the parent folder
#
# Returns:
#   The folder ID of the new folder

sub create_folder
{
  my ($name, $parent_id, $storage_id) = @_;

  my $new_id = $device->Create_Folder(
    $name, $parent_id, $storage_id
  ) or die "Creating folder $name failed: " . $device->errstr;

  return $new_id;
} # end create_folder

#---------------------------------------------------------------------
# Create a new folder to store the audiobook:
#
# Input:
#   author: the author's name (1st level folder)
#   title:  the book's title (2nd level folder)
#
# Returns:
#   The folder ID of the new folder
#
# Notes:
#   Dies if the title folder already exists.

sub create_book_folder
{
  my ($author, $title) = @_;

  my $folderList = $device->Get_Folder_List;

  my $audiobook_folder = find_folder($folderList, $audiobook_folder_name)
      or die "Can't find $audiobook_folder_name folder";
  my $storage_id = $audiobook_folder->storage_id;

  my ($author_folder);
  if (defined $author) {
    $author_folder = find_folder($audiobook_folder->child, $author)
        // create_folder($author, $audiobook_folder->folder_id, $storage_id);
  } else {
    $author_folder = $audiobook_folder;
  }

  if (ref $author_folder) {
    if (my $f = find_folder($author_folder->child, $title)) {
      #return $f->folder_id;     # FIXME
      printf STDERR "%s already exists in %s, skipping it\n",
          $title, $author_folder->name;
      return undef;
    }
    $author_folder = $author_folder->folder_id;
  }

  return create_folder($title, $author_folder, $storage_id);
} # end create_book_folder

#=====================================================================
# Main loop:
#---------------------------------------------------------------------
BOOK:
for my $directory (@ARGV) {
  # Make sure we got a directory:
  die "Usage: $0 DIRECTORY...\n" unless -d $directory;

  say "\n$directory...";

  $directory = dir($directory);

  # Read the playlist:
  my $playlist = $directory->file($playlist_filename);
  die "$playlist does not exist" unless -e $playlist;

  my @filenames = $playlist->slurp(chomp => 1, iomode => '<:utf8:crlf');

  die "$playlist is empty\n" unless @filenames;

  # Make sure we aren't missing any files:
  for my $fn (@filenames) {
    die "unrecognized line in $playlist: $fn\n" unless $fn =~ /\.ogg\z/i;
    die "$fn does not exist\n" unless -e $directory->file($fn);
  }

  # Copy each track to the device:
  my ($artist, $album_name, $folder_id, @tracks);
  for my $tracknumber (0 .. $#filenames) {
    my $title;
    my $fn = $directory->file($filenames[$tracknumber]);
    # Read track comments:
    {
      my @artists;
      open(my $in, '-|:utf8', qw(vorbiscomment --list), $fn)
          or die "vorbiscomment failed on $fn: $!";
      while (<$in>) {
        if (/^title=(.+)/i) { $title = $1 }
        elsif ($tracknumber > 0) { } # only get artist & album from first track
        elsif (/^artist=(.+)/i) { push @artists, $1 }
        elsif (/^album=(.+)/i)  { $album_name = $1 }
      }
      close $in;

      $artist = conjunction(@artists) if @artists;

      die "No chapter title" unless defined $title;

      if ($tracknumber == 0) {
        die "No book title\n" unless defined $album_name;

        say "Album:  $album_name";
        say "Artist: $artist" if defined $artist;

        $folder_id = create_book_folder($artists[0], $album_name)
            or next BOOK;
      } # end if track 0
    } # end reading comments from track

    # Load the Track object with metadata for the new track:
    my $stat = $fn->stat;

    my $track = Media::LibMTP::API::Track->new;
    $track->parent_id($folder_id);
    $track->tracknumber($tracknumber);
    $track->title($title);
    $track->artist($artist) if defined $artist;
    $track->album($album_name);
    $track->filename($filenames[$tracknumber]);
    $track->filesize( $stat->size );
    $track->modificationdate( $stat->mtime );
    $track->filetype(LIBMTP_FILETYPE_OGG);

    # Send the track to the device:
    say "Sending $filenames[$tracknumber]...";
    $device->Send_Track_From_File("$fn", $track)
        and die "Sending $fn failed: " . $device->errstr;

    push @tracks, $track->item_id;
  } # end for $tracknumber in @filenames

  # Now create the Album for the book:
  my $album = Media::LibMTP::API::Album->new;

  $album->parent_id($folder_id);
  $album->name($album_name);
  $album->artist($artist) if defined $artist;
  $album->tracks(\@tracks);

  $device->Create_New_Album($album)
      and die "Create_New_Album failed: " . $device->errstr;

  # Report details about the new album:
  my $album_id   = $album->album_id;

  say "Title:    " . $album->name . " ($album_id)";
  say "Author:   " . ($album->artist // 'Unknown Author');
  say "Parent:   " . $album->parent_id;
  say "Storage:  " . $album->storage_id;
  say "Tracks: " . join(', ', @{$album->tracks})
      . ' (' . $album->no_tracks . ')';

  # Now transfer the cover image, if available:
  my $cover = $directory->file($cover_filename);

  if (-e $cover) {
    say "Sending $cover_filename...";

    my ($width, $height) = imgsize("$cover");

    my $data = $cover->slurp(iomode => '<:raw');

    my $sample = Media::LibMTP::API::FileSampleData->new;
    $sample->width($width);
    $sample->height($height);
    $sample->filetype(LIBMTP_FILETYPE_JPEG);
    $sample->data($data);

    $device->Send_Representative_Sample($album_id, $sample)
        and warn "Sending $cover failed\n";
  } # end if cover.jpg exists
} # end while @ARGV

undef $device;
