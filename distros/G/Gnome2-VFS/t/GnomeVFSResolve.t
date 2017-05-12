#!/usr/bin/perl -w
use strict;
use Gnome2::VFS;

use Test::More;

# $Id$

unless (-d "$ENV{ HOME }/.gnome") {
  plan(skip_all => "You have no ~/.gnome");
}

unless (Gnome2::VFS -> CHECK_VERSION(2, 8, 0)) {
  plan(skip_all => "This is new in 2.8");
}

plan(tests => 2);

Gnome2::VFS -> init();

###############################################################################

my $handle = Gnome2::VFS -> resolve("localhost");
isa_ok($handle, "Gnome2::VFS::Resolve::Handle");
isa_ok($handle -> next_address(), "Gnome2::VFS::Address");

$handle -> reset_to_beginning();

###############################################################################

Gnome2::VFS -> shutdown();
