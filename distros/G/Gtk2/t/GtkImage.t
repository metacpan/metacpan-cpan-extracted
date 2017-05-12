#!/usr/bin/perl
#
# $Id$
#

#########################
# GtkImage Tests
# 	- rm
#########################

use Data::Dumper;
use Gtk2::TestHelper tests => 45;

# get some things ready to use below ###########################################

# borrowed from xsane-icons.c
my @pixbuf_data =
(
	"    20    20        4            1",
	"  none",
	". c #000000",
	"+ c #208020",
	"a c #ffffff",
	"                    ",
	" .................  ",
	" .+++++++++++++++.  ",
	" .+      .      +.  ",
	" .+     ...     +.  ",
	" .+    . . .    +.  ",
	" .+      .      +.  ",
	" .+      .      +.  ",
	" .+  .   .   .  +.  ",
	" .+ .    .    . +.  ",
	" .+.............+.  ",
	" .+ .    .    . +.  ",
	" .+  .   .   .  +.  ",
	" .+      .      +.  ",
	" .+    . . .    +.  ",
	" .+     ...     +.  ",
	" .+      .      +.  ",
	" .+++++++++++++++.  ",
	" .................  ",
	"                    ",
);

my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_xpm_data (@pixbuf_data);

my ($pixmap, $mask) = $pixbuf->render_pixmap_and_mask (255);

my $iconset = Gtk2::IconSet->new_from_pixbuf ($pixbuf);

# Plain old new ################################################################

ok (my $img = Gtk2::Image->new, 'Gtk2::Image->new');

ok (eq_array ([$img->get_icon_set], [undef, 'button']), 'get_icon_set empty');
is ($img->get_image, undef, 'get_image empty');
is ($img->get_pixbuf, undef, 'get_pixbuf empty');
is ($img->get_pixmap, undef, 'get_pixmap empty');
ok (eq_array ([$img->get_stock ()], [undef, 'button']), 'get_stock empty');
is ($img->get_animation, undef, 'get_animation empty');
is ($img->get_storage_type, 'empty', 'get_storage_type empty');

# new from stock ###############################################################

ok ($img = Gtk2::Image->new_from_stock ('gtk-cancel', 'menu'),
    'Gtk2::Image->new_from_stock');
is ($img->get_storage_type, 'stock', 'new_from_stock get_storage_type');
ok (eq_array ([$img->get_stock ()], ['gtk-cancel', 'menu']),
    'new_from_stock get_stock');

# new from icon set ############################################################

ok ($img = Gtk2::Image->new_from_icon_set ($iconset, 'small-toolbar'),
    'Gtk2::Image->new_from_icon_set');
my @ret = $img->get_icon_set;
is (scalar (@ret), 2, 'new_from_icon_set get_icon_set num rets');
isa_ok ($ret[0], 'Gtk2::IconSet', 'new_from_icon_set get_icon_set icon_set');
is ($ret[1], 'small-toolbar', 'new_from_icon_set get_icon_set size');

# new from image ###############################################################

ok ($img = Gtk2::Image->new_from_image (undef, undef),
    'Gtk2::Image->new_from_pixbuf undef');
is ($img->get_image, undef, 'new_from_image get_image empty');
# TODO: from a valid image

# new from pixbuf ##############################################################

ok ($img = Gtk2::Image->new_from_pixbuf ($pixbuf),
    'Gtk2::Image->new_from_pixbuf');
isa_ok ($img->get_pixbuf, 'Gtk2::Gdk::Pixbuf', 'new_from_pixbuf get_pixbuf');

# new from pixmap ##############################################################

ok ($img = Gtk2::Image->new_from_pixmap (undef, undef),
    'Gtk2::Image->new_from_pixbuf');
ok ($img = Gtk2::Image->new_from_pixmap ($pixmap, $mask),
    'Gtk2::Image->new_from_pixbuf');
@ret = $img->get_pixmap;
is (scalar(@ret), 2, 'new_from_pixmap get_pixmap num rets');
isa_ok ($ret[0], 'Gtk2::Gdk::Pixmap', 'new_from_pixmap get_pixbuf pixmap');
isa_ok ($ret[1], 'Gtk2::Gdk::Bitmap', 'new_from_pixmap get_pixbuf mask');

# set from stock ###############################################################

$img->set_from_stock ('gtk-quit', 'dialog');
is ($img->get_storage_type, 'stock', 'set_from_stock get_storage_type');
ok (eq_array ([$img->get_stock ()], ['gtk-quit', 'dialog']),
    'set_from_stock get_stock');

# set from icon set ############################################################

$img->set_from_icon_set ($iconset, 'small-toolbar');
@ret = $img->get_icon_set;
is (scalar (@ret), 2, 'set_from_icon_set get_icon_set num rets');
isa_ok ($ret[0], 'Gtk2::IconSet', 'set_from_icon_set get_icon_set icon_set');
is ($ret[1], 'small-toolbar', 'set_from_icon_set get_icon_set size');

# set from image ###############################################################

$img->set_from_image (undef, undef);
is ($img->get_image, undef, 'set_from_image get_image empty');
# TODO: from a valid image

# set from pixbuf ##############################################################

$img->set_from_pixbuf (undef);
$img->set_from_pixbuf ($pixbuf);
isa_ok ($img->get_pixbuf, 'Gtk2::Gdk::Pixbuf', 'set_from_pixbuf get_pixbuf');

# set from pixmap ##############################################################

$img->set_from_pixmap (undef, undef);
$img->set_from_pixmap ($pixmap, $mask);
@ret = $img->get_pixmap;
is (scalar(@ret), 2, 'set_from_pixmap get_pixmap num rets');
isa_ok ($ret[0], 'Gtk2::Gdk::Pixmap', 'set_from_pixmap get_pixbuf pixmap');
isa_ok ($ret[1], 'Gtk2::Gdk::Bitmap', 'set_from_pixmap get_pixbuf mask');

# These require access to a file, so they may be skipped

my $testfile = './gtk-demo/gnome-foot.png';

SKIP:
{
	skip "unable to find test file, $testfile", 1
		unless (-R $testfile);

	my $animation = Gtk2::Gdk::PixbufAnimation->new_from_file ($testfile);

# new from file ################################################################

	ok ($img = Gtk2::Image->new_from_file (undef),
	    'Gtk2::Image->new_from_file undef');
	ok ($img = Gtk2::Image->new_from_file ($testfile),
	    'Gtk2::Image->new_from_file');
	isa_ok ($img->get_pixbuf, 'Gtk2::Gdk::Pixbuf',
		'new_from_file get_pixbuf');

# new from animation ###########################################################

	ok ($img = Gtk2::Image->new_from_animation ($animation),
	    'Gtk2::Image->new_from_animation');
	isa_ok ($img->get_animation, 'Gtk2::Gdk::PixbufAnimation',
		'new_from_animation get_animationf');

# set from file ################################################################

	$img->set_from_file (undef);
	$img->set_from_file ($testfile);
	isa_ok ($img->get_pixbuf, 'Gtk2::Gdk::Pixbuf',
		'set_from_file get_pixbuf');

# set from animation ###########################################################

	$img->set_from_animation ($animation);
	isa_ok ($img->get_animation, 'Gtk2::Gdk::PixbufAnimation',
		'set_from_animation get_animationf');
}

SKIP: {
	skip 'new stuff in 2.6', 4
		unless Gtk2->CHECK_VERSION (2, 6, 0);

	$img = Gtk2::Image->new_from_icon_name ('gtk-ok', 'button');
	isa_ok ($img, 'Gtk2::Image');
	is_deeply ([$img->get_icon_name], ['gtk-ok', 'button']);

	$img->set_from_icon_name ('gtk-cancel', 'menu');
	is_deeply ([$img->get_icon_name], ['gtk-cancel', 'menu']);

	$img->set_pixel_size (23);
	is ($img->get_pixel_size, 23);
}

SKIP: {
	skip 'new stuff in 2.8', 0
		unless Gtk2->CHECK_VERSION (2, 8, 0);

	$img->clear;
}

__END__

Copyright (C) 2003-2005 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

