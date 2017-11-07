#!/usr/bin/perl
# $Id$

use Test::More tests => 2;

use_ok('Gtk3::Helper');
can_ok('Gtk3::Helper', qw(add_watch remove_watch));

