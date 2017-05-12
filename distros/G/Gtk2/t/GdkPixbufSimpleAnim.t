#!/usr/bin/perl -w

use strict;
use Gtk2::TestHelper tests => 131, noinit => 1,
    at_least_version => [2, 8, 0, 'GdkPixbufSimpleAnim is new in 2.8'];

my $simple_anim = Gtk2::Gdk::PixbufSimpleAnim->new (64, 64, 24.0);
isa_ok ($simple_anim, 'Gtk2::Gdk::PixbufSimpleAnim');
isa_ok ($simple_anim, 'Gtk2::Gdk::PixbufAnimation');

foreach my $alpha (0..127) {
    my $pixels = pack 'C*', (0xe2, 0xc6, 0xe1, 2*$alpha) x (64*64);
    my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_data ($pixels, 'rgb', TRUE, 8,
                                                   64, 64, 64*4);
    $simple_anim->add_frame ($pixbuf);
    ok (1, 'added frame');
}

SKIP: {
    skip 'new 2.18 stuff', 1
        unless Gtk2->CHECK_VERSION(2, 18, 0);

    $simple_anim->set_loop (TRUE);
    ok ($simple_anim->get_loop);
}

my $interactive = $ENV{INTERACTIVE} || (@ARGV > 0);
if ($interactive && Gtk2->init_check) {
    my $window = Gtk2::Window->new;
    my $image = Gtk2::Image->new_from_animation ($simple_anim);
    $window->add ($image);
    $window->show_all;
    $window->signal_connect (destroy => sub {Gtk2->main_quit});
    Gtk2->main;
}

# vim: set syntax=perl et sw=4 sts=4 :
