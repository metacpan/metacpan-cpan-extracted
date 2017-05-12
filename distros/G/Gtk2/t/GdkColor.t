#
# $Id$
#

#########################
# GdkColor Tests
# 	- muppet
#########################

use Gtk2::TestHelper tests => 18;

my $cmap = Gtk2::Gdk::Colormap->get_system;
ok ($cmap, 'system colormap');

my $visual = $cmap->get_visual;
ok ($visual, 'got a visual');

my $tmp_cmap = Gtk2::Gdk::Colormap->new ($visual, 1);
ok ($tmp_cmap, 'new colormap');

SKIP: {
	skip 'get_screen is new in 2.2', 1
		unless Gtk2->CHECK_VERSION (2, 2, 0);

	ok ($cmap->get_screen, 'got a screen');
}

# ten random colors
my @colors = map {
	Gtk2::Gdk::Color->new (rand (65535), rand (65535), rand (65535))
} 0..9;

is ($colors[0]->pixel, 0, 'before alloc_color, pixel is 0');
$cmap->alloc_color ($colors[0], 0, 1);
ok ($colors[0]->pixel > 0, 'alloc_color allocated a color');
my @success = $cmap->alloc_colors (0, 1, @colors);
is (@success, @colors, 'same number of status values as input colors');
ok ($colors[1]->pixel > 0, 'alloc_colors allocated a color');

my $c = $cmap->query_color ($colors[0]->pixel);
ok($c, 'query_color does something');

$cmap->free_colors (@colors);
ok (1, 'free_colors didn\'t coredump');

my $black = Gtk2::Gdk::Color->parse("Black");
ok ($black, 'Black parsed ok');

ok ($black->equal($black), 'Black == Black');
is ($black->hash, 0, 'Black\'s hash == 0');

like($black->pixel, qr/^\d+$/);
is($black->red, 0);
is($black->green, 0);
is($black->blue, 0);

SKIP: {
	skip 'new 2.12 stuff', 1
		unless Gtk2 -> CHECK_VERSION(2, 12, 0);

	is($black->to_string, '#000000000000');
}

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
