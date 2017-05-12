#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 2;

# $Id$

my $tag = Gtk2::TextTag -> new("bla");
isa_ok($tag, "Gtk2::TextTag");

my $table = Gtk2::TextTagTable -> new();
$table -> add($tag);

$tag -> set_priority(0);
is($tag -> get_priority(), 0);

my $model = Gtk2::TextBuffer -> new();
$model -> insert($model -> get_start_iter(),
                 join("", "Lore ipsem dolor.  I think that is misspelled.\n" x 80));

my $button = Gtk2::Button -> new("Bla");
my $event = Gtk2::Gdk::Event -> new("button-press");
my $iter = $model -> get_iter_at_offset(10);

# FIXME: check retval?
$tag -> event($button, $event, $iter);

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
