#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 41;

# $Id$

my $button = Gtk2::Button -> new("Bla");
my $font = Gtk2::Pango::FontDescription -> from_string("Sans 12");
my $green = Gtk2::Gdk::Color -> new(0, 0xFFFF, 0);

my $style = Gtk2::Rc -> get_style($button);
isa_ok($style, "Gtk2::Style");

my $settings = $button -> get_settings();
my $path = ($button -> path())[0];
my $class_path = ($button -> class_path())[0];

my $retval = Gtk2::Rc -> get_style_by_paths($settings,
                                            $path,
                                            $class_path,
                                            Gtk2::Button::);

ok(not defined $retval or UNIVERSAL::isa($retval, "Gtk2::Style"));

# Gtk2::Rc -> parse(...);
Gtk2::Rc -> parse_string(qq(style "blablabla" { }));
like(Gtk2::Rc -> reparse_all(), qr/^$|^0$/);
Gtk2::Rc -> reparse_all_for_settings($settings, 1);
ok(1);

SKIP: {
  skip("reset_styles is new in 2.4", 0)
    unless (Gtk2 -> CHECK_VERSION(2, 4, 0));

  Gtk2::Rc -> reset_styles($settings);
}

Gtk2::Rc -> add_default_file("/tmp/bla.rc");
is((Gtk2::Rc -> get_default_files())[-1], "/tmp/bla.rc");

Gtk2::Rc -> set_default_files("/tmp/bla.rc", "/tmp/blub.rc");
is_deeply([Gtk2::Rc -> get_default_files()], ["/tmp/bla.rc", "/tmp/blub.rc"]);

ok(Gtk2::Rc -> get_module_dir());
ok(Gtk2::Rc -> get_im_module_path());
ok(Gtk2::Rc -> get_im_module_file());
ok(Gtk2::Rc -> get_theme_dir());

my $rc_style = Gtk2::RcStyle -> new();
isa_ok($rc_style, "Gtk2::RcStyle");
isa_ok($rc_style -> copy(), "Gtk2::RcStyle");

# first, test normal values
is($rc_style -> name("bla"), undef);
is($rc_style -> bg_pixmap_name("normal", "blub"), undef);
is($rc_style -> font_desc($font), undef);

isa_ok($rc_style -> fg("active", $green), "Gtk2::Gdk::Color");
isa_ok($rc_style -> bg("prelight", $green), "Gtk2::Gdk::Color");
isa_ok($rc_style -> text("selected", $green), "Gtk2::Gdk::Color");
isa_ok($rc_style -> base("insensitive", $green), "Gtk2::Gdk::Color");

ok($rc_style -> color_flags("active", "fg") == []);
ok($rc_style -> color_flags("prelight", "bg") == []);
ok($rc_style -> color_flags("selected", "text") == []);
ok($rc_style -> color_flags("insensitive", "base") == []);

is($rc_style -> xthickness(5), -1);
is($rc_style -> ythickness(5), -1);

is($rc_style -> name(), "bla");
is($rc_style -> bg_pixmap_name("normal"), "blub");
is($rc_style -> font_desc() -> to_string(), "Sans 12");

is($rc_style -> fg("active") -> green(), 0xFFFF);
is($rc_style -> bg("prelight") -> green(), 0xFFFF);
is($rc_style -> text("selected") -> green(), 0xFFFF);
is($rc_style -> base("insensitive") -> green(), 0xFFFF);

ok($rc_style -> color_flags("active") == ["fg"]);
ok($rc_style -> color_flags("prelight") == ["bg"]);
ok($rc_style -> color_flags("selected") == ["text"]);
ok($rc_style -> color_flags("insensitive") == ["base"]);

is($rc_style -> xthickness(), 5);
is($rc_style -> ythickness(), 5);

# second, test undef
$rc_style -> name(undef);
is($rc_style -> name(), undef);

$rc_style -> bg_pixmap_name("normal", undef);
is($rc_style -> bg_pixmap_name("normal"), undef);

$rc_style -> font_desc(undef);
is($rc_style -> font_desc(), undef);

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
