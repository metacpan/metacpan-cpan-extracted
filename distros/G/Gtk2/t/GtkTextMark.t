#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 11, noinit => 1;

# $Id$

my $buffer = Gtk2::TextBuffer -> new();
my $iter = $buffer -> get_start_iter();

$buffer -> insert($iter, "Lore ipsem dolor.  I think that is misspelled.\n");

my $mark = $buffer -> create_mark("bla", $iter, 1);
is($mark -> get_name(), "bla");
is($mark -> get_buffer(), $buffer);
is($mark -> get_left_gravity(), 1);

$mark -> set_visible(1);
is($mark -> get_visible(), 1);

$buffer -> delete_mark($mark);
is($mark -> get_deleted(), 1,    'deleted mark - get_deleted()');
is($mark -> get_buffer(), undef, 'deleted mark - get_buffer()');

SKIP: {
  skip 'new 2.12 stuff', 5
    unless Gtk2 -> CHECK_VERSION(2, 12, 0);

  my $mark = Gtk2::TextMark -> new(undef, TRUE);
  isa_ok($mark, 'Gtk2::TextMark');
  is ($mark->get_name,   undef, 'new() anonymous mark - get_name()');
  is ($mark->get_buffer, undef, 'new() anonymous mark - get_buffer()');

  $mark = Gtk2::TextMark -> new('bla', TRUE);
  isa_ok($mark, 'Gtk2::TextMark');
  is ($mark->get_name, 'bla', 'new() named mark - get_name()');
}

__END__

Copyright (C) 2003, 2010 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
