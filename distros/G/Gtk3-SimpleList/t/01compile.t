#!/usr/bin/perl
# $Id$

use Test::More tests => 2;

use_ok('Gtk3::SimpleList');
can_ok('Gtk3::SimpleList', qw(new new_from_treeview));

