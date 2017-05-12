#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 3;

# $Id$

my $buffer = Gtk2::TextBuffer -> new();
my $view = Gtk2::TextView -> new_with_buffer($buffer);

my $iter = $buffer -> get_start_iter();

$buffer -> insert($iter,
                  join("", "Lore ipsem dolor.  I think that is misspelled.\n" x 80));

my $anchor = Gtk2::TextChildAnchor -> new();
isa_ok($anchor, "Gtk2::TextChildAnchor");

# letting an anchor die without having inserted it into a buffer causes
# very bad things to happen.  dispose of it nicely.
$buffer->insert_child_anchor ($iter, $anchor);

my $button = Gtk2::Button -> new("Bla");
my $label = Gtk2::Label -> new("Bla");

$anchor = $buffer -> create_child_anchor($iter);
$view -> add_child_at_anchor($button, $anchor);
$view -> add_child_at_anchor($label, $anchor);

is_deeply([$anchor -> get_widgets()], [$button, $label]);
ok(!$anchor -> get_deleted());

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
