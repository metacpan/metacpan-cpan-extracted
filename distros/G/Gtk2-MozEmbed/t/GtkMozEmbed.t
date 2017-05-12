#!/usr/bin/perl

# $Id$

use strict;
use warnings;

use Gtk2 -init;
use Gtk2::MozEmbed;

use Test::More tests => 8;

# These cause an abort:
# Gtk2::MozEmbed -> push_startup();
# Gtk2::MozEmbed -> pop_startup();

Gtk2::MozEmbed -> set_comp_path($ENV{ HOME });
Gtk2::MozEmbed -> set_profile_path($ENV{ HOME } . "/.Schmuh", "Schmuh");

my $moz = Gtk2::MozEmbed -> new();
isa_ok($moz, "Gtk2::MozEmbed");

my $uri = "file://" . $ENV{ HOME };

$moz -> load_url($uri);
$moz -> stop_load();

ok(not $moz -> can_go_back());
ok(not $moz -> can_go_forward());

$moz -> go_back();
$moz -> go_forward();

# my $window = Gtk2::Window -> new();
# $window -> add($moz);
# $window -> realize();
# $moz -> show_all();
# $window -> show_all();

# segfault: $moz -> render_data("<html></html>", $uri, "text/html");
#           $moz -> open_stream($uri, "text/html");
#           $moz -> append_data("<!-- bla -->");
#           $moz -> close_stream();

is($moz -> get_link_message(), undef);
is($moz -> get_js_status(), undef);
is($moz -> get_title(), undef);
is($moz -> get_location(), $uri);

$moz -> reload([qw/reloadnormal reloadbypassproxyandcache/]);

$moz -> set_chrome_mask([qw/defaultchrome modal/]);
ok($moz -> get_chrome_mask() == [qw/defaultchrome modal/]);

# my $single = Gtk2::MozEmbedSingle -> new();
# isa_ok($single, "Gtk2::MozEmbedSingle");
