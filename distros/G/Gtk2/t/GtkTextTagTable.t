#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 5, noinit => 1;

# $Id$

my $table = Gtk2::TextTagTable -> new();
isa_ok($table, "Gtk2::TextTagTable");

my $tag = Gtk2::TextTag -> new("bla");

$table -> add($tag);

is($table -> lookup("bla"), $tag);

$table -> foreach(sub {
  is(shift(), $tag);
  is(shift(), "bla");
}, "bla");

is($table -> get_size(), 1);

$table -> remove($tag);

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
