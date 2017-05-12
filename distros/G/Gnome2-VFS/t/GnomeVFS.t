#!/usr/bin/perl -w
use strict;
use Test::More;

# $Id$

plan -d "$ENV{ HOME }/.gnome" ?
  (tests => 3) :
  (skip_all => "You have no ~/.gnome");

###############################################################################

use_ok("Gnome2::VFS", qw(
  GNOME_VFS_PRIORITY_MIN
  GNOME_VFS_PRIORITY_MAX
  GNOME_VFS_PRIORITY_DEFAULT
  GNOME_VFS_SIZE_FORMAT_STR
  GNOME_VFS_OFFSET_FORMAT_STR
  GNOME_VFS_MIME_TYPE_UNKNOWN
  GNOME_VFS_URI_MAGIC_STR
  GNOME_VFS_URI_PATH_STR
));

Gnome2::VFS -> init();
ok(Gnome2::VFS -> initialized());

###############################################################################

# FIXME: how to reliably test this? seems to require a running nautilus.
# my ($result, $uri) = Gnome2::VFS -> find_directory("/home", "desktop", 0, 1, 0755);
# is($result, "ok");
# isa_ok($uri, "Gnome2::VFS::URI");

ok(defined Gnome2::VFS -> result_to_string("ok"));

###############################################################################

Gnome2::VFS -> shutdown();
