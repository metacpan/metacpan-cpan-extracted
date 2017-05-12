#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 46;

# $Id$

use Gtk2::Gdk::Keysyms;

my $map = Gtk2::Gdk::Keymap -> get_default();
isa_ok($map, "Gtk2::Gdk::Keymap");

SKIP: {
  skip("GdkDisplay is new in 2.2", 1)
    unless Gtk2->CHECK_VERSION (2, 2, 0);

  $map = Gtk2::Gdk::Keymap -> get_for_display (Gtk2::Gdk::Display -> get_default());
  isa_ok($map, "Gtk2::Gdk::Keymap");
}

my @keys = $map -> get_entries_for_keyval($Gtk2::Gdk::Keysyms{ Escape });

SKIP: {
skip 'No key entries for Escape found in the keymap', 41
  unless scalar @keys;

isa_ok($keys[0], "HASH");
like($keys[0] -> { keycode }, qr/^\d+$/);
like($keys[0] -> { group }, qr/^\d+$/);
like($keys[0] -> { level }, qr/^\d+$/);

@keys = Gtk2::Gdk::Keymap -> get_entries_for_keyval($Gtk2::Gdk::Keysyms{ Escape });
isa_ok($keys[0], "HASH");
like($keys[0] -> { keycode }, qr/^\d+$/);
like($keys[0] -> { group }, qr/^\d+$/);
like($keys[0] -> { level }, qr/^\d+$/);

my ($keyval, $group, $level, $mods) = $map -> translate_keyboard_state($keys[0] -> { keycode }, [qw(shift-mask)], 0);
like($keyval, qr/^\d+$/);
like($group, qr/^\d+$/);
like($level, qr/^\d+$/);
isa_ok($mods, "Gtk2::Gdk::ModifierType");

SKIP: {
  skip("translate_keyboard_state is broken", 4)
    unless (Gtk2 -> CHECK_VERSION(2, 4, 1));

  ($keyval, $group, $level, $mods) = Gtk2::Gdk::Keymap -> translate_keyboard_state($keys[0] -> { keycode }, [qw(shift-mask)], 0);
  like($keyval, qr/^\d+$/);
  like($group, qr/^\d+$/);
  like($level, qr/^\d+$/);
  isa_ok($mods, "Gtk2::Gdk::ModifierType");
}

my $key = {
  keycode => $keys[0] -> { keycode },
  group => $group,
  level => $level
};

like($map -> lookup_key($key), qr/^\d+$/);
like(Gtk2::Gdk::Keymap -> lookup_key($key), qr/^\d+$/);

my @entries = $map -> get_entries_for_keycode($keys[0] -> { keycode });
isa_ok($entries[0], "HASH");
like($entries[0] -> { keyval }, qr/^\d+$/);
isa_ok($entries[0] -> { key }, "HASH");
like($entries[0] -> { key } -> { keycode }, qr/^\d+$/);
like($entries[0] -> { key } -> { group }, qr/^\d+$/);
like($entries[0] -> { key } -> { level }, qr/^\d+$/);

@entries = Gtk2::Gdk::Keymap -> get_entries_for_keycode($keys[0] -> { keycode });
isa_ok($entries[0], "HASH");
like($entries[0] -> { keyval }, qr/^\d+$/);
isa_ok($entries[0] -> { key }, "HASH");
like($entries[0] -> { key } -> { keycode }, qr/^\d+$/);
like($entries[0] -> { key } -> { group }, qr/^\d+$/);
like($entries[0] -> { key } -> { level }, qr/^\d+$/);

ok(defined($map -> get_direction()));
ok(defined(Gtk2::Gdk::Keymap -> get_direction()));

SKIP: {
  skip "new 2.12 stuff", 1
    unless Gtk2 -> CHECK_VERSION(2, 12, 0);

  ok(defined($map -> have_bidi_layouts()));
}

SKIP: {
  skip "new 2.16 stuff", 1
    unless Gtk2 -> CHECK_VERSION(2, 16, 0);

  ok(defined($map -> get_caps_lock_state), 'get_caps_lock_state');
}

my $a = $Gtk2::Gdk::Keysyms{ a };
my $A = $Gtk2::Gdk::Keysyms{ A };

is(Gtk2::Gdk -> keyval_name($a), "a");
is(Gtk2::Gdk -> keyval_from_name("a"), $a);

is_deeply([Gtk2::Gdk -> keyval_convert_case($a)],
          [$a, $A]);

is(Gtk2::Gdk -> keyval_to_upper($a), $A);
is(Gtk2::Gdk -> keyval_to_lower($A), $a);
is(Gtk2::Gdk -> keyval_is_upper($A), 1);
is(Gtk2::Gdk -> keyval_is_lower($a), 1);

my $unicode = Gtk2::Gdk -> keyval_to_unicode($a);
is(Gtk2::Gdk -> unicode_to_keyval($unicode), $a);

}

SKIP: {
  skip 'new 2.20 stuff', 2
    unless Gtk2->CHECK_VERSION(2, 20, 0);

  my $map = Gtk2::Gdk::Keymap -> get_default();
  ok(defined $map -> add_virtual_modifiers([qw/mod1-mask super-mask/]));
  my ($result, $new_state) = $map -> map_virtual_modifiers([qw/mod1-mask super-mask/]);
  ok(defined $result && defined $new_state);
}

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
