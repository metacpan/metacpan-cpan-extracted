#!/usr/bin/perl -w
use strict;

use lib './lib','../lib';

use File::Type;
use Test::More;

my $types = {
  "00setup.t" => "application/x-perl",
  "files/blank.jpg" => "image/jpeg",
  "files/blank.tif" => "image/tiff",
  "files/blank.bmp" => "image/x-bmp",
  "files/blank.png" => "image/x-png",
  "files/blank.pdf" => "application/pdf",
  "files/rebound.wav" => "audio/x-wav",
  "files/tarball.tar" => "application/x-tar",
  "files/tarball.tar.gz" => "application/x-gzip",
  "files/tarball.tar.bz2" => "application/x-bzip2",
#  "files/no-id3.mp3"  => "audio/mp3",
  "files/id3v2.4.mp3" => "audio/mp3",
  "files/blank.gif"  => "image/gif",
  "files/blank.zip"  => "application/zip",
  "files/File-Type.html" => "text/html",
  "files/standards.mov" => "video/quicktime",
  "files/kite.asf" => "video/x-ms-asf",
  "files/0001.avi" => "video/x-msvideo",
  "files/0001.wav" => "audio/x-wav",
};

plan tests => scalar keys %{ $types };

=for testing

Initialise the object.

=cut

my $ft = File::Type->new();

=for testing

Loop over the objects, testing each both ways.

=cut

foreach my $filename (sort keys %{ $types }) {
  my $mimetype = $types->{$filename};
  my $argument = $filename;
  my $checktype;

  # randomly read in file, or make filename correct
  if (rand > 0.5) {
    $argument = read_file("t/$filename") || die;
    $checktype = 'data';
  } else {
    $argument = "t/".$argument;
    $checktype = 'file';
  }

  is($ft->mime_type($argument), $mimetype, "magically checked $checktype");
}

sub read_file {
  my $file = shift;

  local $/ = undef;
  open FILE, $file or die "Can't open file $file: $!";
  my $data = <FILE>;
  close FILE;
  
  return $data;
}
