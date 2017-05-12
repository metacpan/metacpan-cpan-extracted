#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 11;

use utf8; # for the umlaut test

# $Id$

my $adjustment = Gtk2::Adjustment -> new(0, 0, 100, 1, 5, 0);
my $spin = Gtk2::SpinButton -> new($adjustment, 0.2, 1);
isa_ok($spin, "Gtk2::Editable");

my $entry = Gtk2::Entry -> new();
isa_ok($entry, "Gtk2::Editable");

$entry -> set_text("Bla");

$entry -> select_region(1, 3);
is_deeply([$entry -> get_selection_bounds()], [1, 3]);

is($entry -> insert_text(" Blub", 3), 8);
is($entry -> get_chars(0, 8), "Bla Blub");
$entry -> delete_text(3, 8);

is($entry -> insert_text(" Blub", 5, 3), 8);
is($entry -> get_chars(0, 8), "Bla Blub");
$entry -> delete_text(3, 8);

$entry -> set_position(2);
is($entry -> get_position(), 2);

$entry -> set_editable(1);
is($entry -> get_editable(), 1);

my $window = Gtk2::Window -> new();
$window -> add($entry);

$entry -> cut_clipboard();
$entry -> copy_clipboard();
$entry -> paste_clipboard();
$entry -> delete_selection();

# Test the custom insert-text marshaller.
{
  my $entry = Gtk2::Entry -> new();
  $entry -> set_text("äöü");
  $entry -> signal_connect(insert_text => sub {
    my ($entry, $new_text, $new_text_length, $position, $data) = @_;
    $_[1] = reverse $new_text;
    $_[3] = 0;
    return ();
  });
  $entry -> insert_text("123", 3);
  is($entry -> get_text(), "321äöü");
}
{
  my $entry = Gtk2::Entry -> new();
  $entry -> set_text("äöü");
  $entry -> signal_connect('insert-text' => sub {
    my ($entry, $new_text, $new_text_length, $position, $data) = @_;
    my $mangled_new_text = reverse $new_text;
    my $mangled_position = 0;
    return ($mangled_new_text, $mangled_position);
  });
  $entry -> insert_text("123", 3);
  is($entry -> get_text(), "321äöü");
}

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
