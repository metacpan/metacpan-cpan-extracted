#! /usr/bin/perl
#---------------------------------------------------------------------

use Test::More 0.88;            # done_testing

use strict;
use warnings;
use 5.010;

use Media::LibMTP::API ':filetypes';

my (@names, @paths);
BEGIN {
  @names = (
    'image/gif'  => LIBMTP_FILETYPE_GIF,
    jpg          => LIBMTP_FILETYPE_JPEG,
    mpg          => LIBMTP_FILETYPE_MPEG,
    'video/mpeg' => LIBMTP_FILETYPE_MPEG,
    ogg          => LIBMTP_FILETYPE_OGG,
  );

  @paths = (
    'image.gif'                 => LIBMTP_FILETYPE_GIF,
    'pict.jpg'                  => LIBMTP_FILETYPE_JPEG,
    '/tmp/file.mpg'             => LIBMTP_FILETYPE_MPEG,
    'relative/path/to.mpeg'     => LIBMTP_FILETYPE_MPEG,
    'song.ogg'                  => LIBMTP_FILETYPE_OGG,
    'extensionFree'             => LIBMTP_FILETYPE_UNKNOWN,
    '/some/dir.jpg/no_ext'      => LIBMTP_FILETYPE_UNKNOWN,
    '/no/filename.doc/'         => LIBMTP_FILETYPE_UNKNOWN,
  );

  plan tests => 1 + @names/2 + @paths/2;

  use_ok('Media::LibMTP::API::Filetypes', qw(filetype filetype_from_path));
}

while (@names) {
  my $name     = shift @names;
  my $expected = shift @names;

  is(filetype($name), $expected, $name);
} # end while @names

while (@paths) {
  my $path     = shift @paths;
  my $expected = shift @paths;

  is(filetype_from_path($path), $expected, $path);
} # end while @paths

done_testing;
