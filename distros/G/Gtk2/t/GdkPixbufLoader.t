#!/usr/bin/perl -w
#
# Copyright (c) 2005 by the gtk2-perl team (see the file AUTHORS)
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, write to the 
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, 
# Boston, MA  02110-1301  USA.
#
# $Id$

use strict;
use warnings;
use Gtk2;
use Test::More;

unless (Gtk2->CHECK_VERSION (2, 2, 0)) {
    plan skip_all => "This doesn't seem to work on 2.0";
} else {
    plan tests => 29;
}

# first, a helper.
sub make_ppm_data {
    my ($width, $height) = @_;
    my $header = "P6\n$width $height\n255\n";
    my $data = pack 'a*', map { $_ % 255 } 1..($width * $height * 3);
    return $header.$data;
}

# now, let's test!

# Automatic detection of the image type seems to be broken in some versions of
# gtk+; see <http://bugzilla.gnome.org/show_bug.cgi?id=570780>.  So we don't
# use an auto-detecting loader here.
my $loader = Gtk2::Gdk::PixbufLoader->new_with_mime_type (
                 'image/x-portable-pixmap');
isa_ok ($loader, 'Glib::Object');
isa_ok ($loader, 'Gtk2::Gdk::PixbufLoader');
$loader->write (make_ppm_data (10, 15));
$loader->close;
my $pixbuf = $loader->get_pixbuf;
isa_ok ($pixbuf, 'Gtk2::Gdk::Pixbuf');
is ($pixbuf->get_width, 10, 'image width');
is ($pixbuf->get_height, 15, 'image height');
# looks like you get an animation regardless of whether the file is animated.
isa_ok ($loader->get_animation, 'Gtk2::Gdk::PixbufAnimation');
SKIP: {
    skip 'get_format was added in 2.2.0', 3
        if Gtk2->check_version (2, 2, 0);

    my $format = $loader->get_format;
    isa_ok ($format, 'HASH');
    isa_ok ($format, 'Gtk2::Gdk::PixbufFormat');
    is ($format->{name}, 'pnm');
}
$loader = undef;
$pixbuf = undef;


# bad explicit type should throw an exception.
eval { $loader = Gtk2::Gdk::PixbufLoader->new_with_type ('something bogus'); };
is ($loader, undef);
ok ($@, 'got an exception');
isa_ok ($@, 'Glib::Error');
is ($@->value, 'unknown-type');

foreach (Gtk2::Gdk::PixbufLoader->new_with_type ('png'),
         Gtk2::Gdk::PixbufLoader::new_with_type ('png')) {
  # we should get an error when writing ppm data to a png loader.
    eval { $_->write (make_ppm_data (20, 20)); };
    ok ($@, 'got an exception');
    isa_ok ($@, 'Glib::Error');
    is ($@->value, 'corrupt-image');
    $_->close;
}



SKIP: {
    skip 'gdk_pixbuf_loader_set_size was added in 2.2.0', 2
        if Gtk2->check_version (2, 2, 0);

    # set_size can be used to do load-time scaling.

    $loader = Gtk2::Gdk::PixbufLoader->new_with_mime_type (
                  'image/x-portable-pixmap');
    $loader->set_size (48, 32);
    $loader->write (make_ppm_data (96, 64));
    $loader->close;
    $pixbuf = $loader->get_pixbuf;
    is ($pixbuf->get_width, 48);
    is ($pixbuf->get_height, 32);
    $loader = undef;
}


SKIP: {
    skip 'new_with_mime_type was added in 2.4.0, but only works with 2.6.0', 4
        if Gtk2->check_version (2, 6, 0);

    foreach (Gtk2::Gdk::PixbufLoader->new_with_mime_type ('image/x-portable-pixmap'),
             Gtk2::Gdk::PixbufLoader::new_with_mime_type ('image/x-portable-pixmap')) {
        isa_ok ($_, 'Glib::Object');
        isa_ok ($_, 'Gtk2::Gdk::PixbufLoader');
        $_->write (make_ppm_data (64, 64));
        $_->close;
        $_ = undef;
    }
}



# test chunked writing and signals and such
SKIP: {
    my $filename = 'gtk-demo/alphatest.png';
    skip "can't locate test image file", 4
        unless -f $filename;

    open IN, $filename or die "can't open $filename: $!";
    binmode IN;
    $loader = Gtk2::Gdk::PixbufLoader->new;
    $loader->signal_connect (size_prepared => sub { ok (1, 'size-prepared') });
    $loader->signal_connect (area_prepared => sub { ok (1, 'area-prepared') });
    my $area_updated = 0;
    $loader->signal_connect (area_updated => sub { $area_updated++ });
    $loader->signal_connect (closed => sub { ok (1, 'closed') });
    my $data;
    while (sysread IN, $data, 64) {
        $loader->write ($data);
    }
    ok ($area_updated, 'got some area-updated signals');
    close IN;
    $loader->close;
    $loader = undef;
}
