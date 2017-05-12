#!/usr/bin/perl -w
use strict;
use utf8;
use Gnome2::VFS;

use Cwd qw(cwd);

use Test::More;

# $Id$

plan -d "$ENV{ HOME }/.gnome" ?
  (tests => 31) :
  (skip_all => "You have no ~/.gnome");

Gnome2::VFS -> init();

###############################################################################

# Gnome2::VFS -> escape_set(...);
# Gnome2::VFS -> icon_path_from_filename(...);
# Gnome2::VFS -> url_show("http://www.bla.de");
# Gnome2::VFS -> url_show_with_env("http://www.bla.de", [map { "$_=" . $ENV{ $_ } } (keys(%ENV))]);

is(Gnome2::VFS -> format_file_size_for_display(1200000000), "1.1 GB");

SKIP: {
  skip("escape_string, format_uri_for_display, gnome_vfs_make_uri_from_input, make_uri_canonical_strip_fragment, uris_match, get_uri_scheme and make_uri_from_shell_arg are new in 2.2.0", 13)
    unless (Gnome2::VFS -> CHECK_VERSION(2, 2, 0));

  is(Gnome2::VFS -> escape_string('%$§äöü'), '%25%24%C2%A7%C3%A4%C3%B6%C3%BC');
  is(Gnome2::VFS -> format_uri_for_display("/usr/bin/äöü"), "/usr/bin/äöü");
  is(Gnome2::VFS -> make_uri_from_input("gtk2-perl.sf.net"), "http://gtk2-perl.sf.net");
  is(Gnome2::VFS -> make_uri_canonical_strip_fragment("http://gtk2-perl.sf.net#bla"), "http://gtk2-perl.sf.net");
  ok(Gnome2::VFS -> uris_match("http://gtk2-perl.sf.net", "http://gtk2-perl.sf.net"));
  is(Gnome2::VFS -> get_uri_scheme("http://gtk2-perl.sf.net"), "http");
  is(Gnome2::VFS -> make_uri_from_shell_arg("/~/bla"), "file:///~/bla");

  my ($result, $size, $content) = Gnome2::VFS -> read_entire_file(cwd() . "/" . $0);
  is($result, "ok");
  like($size, qr/^\d+$/);
  like($content, qr(^#!/usr/bin/perl));

  ($result, $size, $content) = Gnome2::VFS -> read_entire_file(cwd());
  is($result, "error-is-directory");
  is($size, 0);
  is($content, undef);
}

SKIP: {
  skip("make_uri_from_input_with_dirs is new in 2.4.0", 1)
    unless (Gnome2::VFS -> CHECK_VERSION(2, 4, 0));

  ok(defined(Gnome2::VFS -> make_uri_from_input_with_dirs("~/tmp", qw(homedir))));
}

SKIP: {
  skip("make_uri_from_input_with_trailing_ws is new in 2.12.0", 1)
    unless (Gnome2::VFS -> CHECK_VERSION(2, 12, 0));

  ok(defined(Gnome2::VFS -> make_uri_from_input_with_trailing_ws("file:///tmp")));
}

foreach (Gnome2::VFS -> escape_path_string('%$§äöü'),
         Gnome2::VFS -> escape_host_and_path_string('%$§äöü')) {
  is($_, '%25%24%C2%A7%C3%A4%C3%B6%C3%BC');
  is(Gnome2::VFS -> unescape_string($_), '%$§äöü');
}

is(Gnome2::VFS -> escape_slashes("/%/"), "%2F%25%2F");

SKIP: {
  skip ("make_uri_canonical is borken in versions prior to 2.2.0", 1)
    unless (Gnome2::VFS -> CHECK_VERSION(2, 2, 0));

  is(Gnome2::VFS -> make_uri_canonical("bla/bla.txt"), "file:///bla/bla.txt");
}

is(Gnome2::VFS -> make_path_name_canonical("/bla"), "/bla");
ok(defined(Gnome2::VFS -> expand_initial_tilde("~/bla")));
is(Gnome2::VFS -> unescape_string_for_display("%2F%25%2F"), "/%/");
is(Gnome2::VFS -> get_local_path_from_uri("file:///bla"), "/bla");
is(Gnome2::VFS -> get_uri_from_local_path("/bla"), "file:///bla");
ok(Gnome2::VFS -> is_executable_command_string("perl -wle 'print 23'"));

my ($result, $size) = Gnome2::VFS -> get_volume_free_space(Gnome2::VFS::URI -> new("file://" . cwd()));
is($result, "ok");
like($size, qr/^\d+$/);

ok(Gnome2::VFS -> is_primary_thread());

###############################################################################

Gnome2::VFS -> shutdown();
