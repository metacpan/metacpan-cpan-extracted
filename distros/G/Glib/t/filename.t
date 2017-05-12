#!/usr/bin/perl
# vim: set filetype=perl :

#
# Test the filename conversion facilities in Glib
#

use strict;
use warnings;
use Glib qw(:functions);
use Test::More tests => 26;

my $filename = "test";

is(Glib->filename_to_unicode($filename), $filename);
is(Glib::filename_to_unicode($filename), $filename);
is(filename_to_unicode($filename), $filename);

is(Glib->filename_from_unicode($filename), $filename);
is(Glib::filename_from_unicode($filename), $filename);
is(filename_from_unicode($filename), $filename);


#
# These URI related tests are deliberately permissive so as not to fail on
# MSWin32.
#

use Cwd qw(cwd);

my $path = cwd() . "/" . $filename;
my $host = "localhost";
my $uri = "file://$host/$filename";
my $expected = qr/\Q$filename\E/;

like(Glib->filename_to_uri($path, undef), $expected);
like(Glib::filename_to_uri($path, undef), $expected);
like(filename_to_uri($path, undef), $expected);

like(Glib->filename_to_uri($path, $host), $expected);
like(Glib::filename_to_uri($path, $host), $expected);
like(filename_to_uri($path, $host), $expected);

like(Glib->filename_from_uri($uri), $expected);
like(Glib::filename_from_uri($uri), $expected);
like(filename_from_uri($uri), $expected);
like(filename_from_uri("file:///$filename"), $expected);
{
  # note in the return "localhost" is downgraded to undef on msdos, so don't
  # check $ret[1] eq 'localhost'
  my @ret;
  @ret = Glib->filename_from_uri($uri);
  like ($ret[0], $expected);

  @ret = filename_from_uri($uri);
  like ($ret[0], $expected);

  @ret = filename_from_uri("file:///$filename");
  like ($ret[0], $expected);
  is ($ret[1], undef);
}

SKIP: {
	skip "g_filename_display_name was added glib 2.6.0", 6
		unless Glib->CHECK_VERSION (2, 6, 0);

	ok (Glib::filename_display_name ("test"));
	ok (Glib::filename_display_basename ("test"));

	ok (Glib::filename_display_name ("/tmp/test"));
	ok (Glib::filename_display_basename ("/tmp/test"));

	# should not fail even on invalid stuff
	my $something = "/tmp/test\x{fe}\x{03}invalid";
	ok (Glib::filename_display_name ($something));
	ok (Glib::filename_display_basename ($something));
}
