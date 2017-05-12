#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 12;

# $Id$

my $selection = Gtk2::ColorSelection -> new();
isa_ok($selection, "Gtk2::ColorSelection");

$selection -> set_has_opacity_control(1);
is($selection -> get_has_opacity_control(), 1);

$selection -> set_has_palette(1);
is($selection -> get_has_palette(), 1);

$selection -> set_current_alpha(65535);
is($selection -> get_current_alpha(), 65535);

my $color = Gtk2::Gdk::Color -> new(255, 255, 255);

$selection -> set_current_color($color);
isa_ok($selection -> get_current_color(), "Gtk2::Gdk::Color");

$selection -> set_previous_alpha(0);
is($selection -> get_previous_alpha(), 0);

$selection -> set_previous_color($color);
isa_ok($selection -> get_previous_color(), "Gtk2::Gdk::Color");

ok(! $selection -> is_adjusting());

my @palette = $selection -> palette_from_string("DarkSlateGray:LightBlue:Black");
isa_ok($_, "Gtk2::Gdk::Color") foreach (@palette);

is($selection -> palette_to_string(@palette), "#2F4F4F:#ADD8E6:#000000");

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
