#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 12;

# $Id$

my $item = Gtk2::ImageMenuItem -> new();
isa_ok($item, "Gtk2::ImageMenuItem");

$item = Gtk2::ImageMenuItem -> new("_Bla");
isa_ok($item, "Gtk2::ImageMenuItem");

$item = Gtk2::ImageMenuItem -> new_with_label("Bla");
isa_ok($item, "Gtk2::ImageMenuItem");

$item = Gtk2::ImageMenuItem -> new_with_mnemonic("Bla");
isa_ok($item, "Gtk2::ImageMenuItem");

$item = Gtk2::ImageMenuItem -> new_from_stock("gtk-ok");
isa_ok($item, "Gtk2::ImageMenuItem");

$item = Gtk2::ImageMenuItem -> new_from_stock("gtk-ok", Gtk2::AccelGroup -> new());
isa_ok($item, "Gtk2::ImageMenuItem");

my $image = Gtk2::Image -> new_from_stock("gtk-quit", "menu");

$item -> set_image($image);
is($item -> get_image(), $image);

SKIP: {
	skip 'use_stock methods', 5
		unless Gtk2->CHECK_VERSION(2, 16, 0);

	# Get an item from a stock and test the getter/setter
	my $from_stock = Gtk2::ImageMenuItem -> new_from_stock("gtk-yes");
	is($from_stock -> get_use_stock(), TRUE);
	$from_stock -> set_use_stock(FALSE);
	is($from_stock -> get_use_stock(), FALSE);


	# Get an item WITHOUT a stock and test the getter/setter
	my $with_label = Gtk2::ImageMenuItem -> new_with_label("Fake");
	is($with_label -> get_use_stock(), FALSE);
	$with_label -> set_use_stock(TRUE);
	is($with_label -> get_use_stock(), TRUE);

	# Add an accelator (applies only to stock items). Can't be verified, at least
	# the method call is tested for a crash
	my $with_accelartor = Gtk2::ImageMenuItem -> new_from_stock("gtk-no");
	$from_stock -> set_accel_group(Gtk2::AccelGroup -> new());

	my $imagemitem = Gtk2::ImageMenuItem->new_from_stock("gtk-yes");
	$imagemitem->set_always_show_image(TRUE);
	is( $imagemitem->get_always_show_image, TRUE, '[gs]et_always_show_image');
}

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
