#!/usr/bin/perl -w
use strict;
use Gnome2;

use constant TESTS => 4;
use Test::More tests => TESTS;

# $Id$

###############################################################################

is(Gnome2::Util -> extension("blub.abw"), "abw");
like(Gnome2::Util -> prepend_user_home("blub.abw"), qr/blub.abw/);
like(Gnome2::Util -> home_file("blub.abw"), qr/blub.abw/);
ok(-e Gnome2::Util -> user_shell());
