#!/usr/bin/perl -w
# unit-demo.pl --- 
# Last modify Time-stamp: <Ye Wenbin 2007-09-28 15:33:41>
# Version: v 0.0 2007/09/26 13:31:45
# Author: Ye Wenbin <wenbinye@gmail.com>

use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/../blib/arch";
use lib "$Bin/../blib/lib";

use Gtk2 '-init';
use Glib qw(TRUE FALSE);
use Goo::Canvas;

my $window = Gtk2::Window->new('toplevel');
$window->signal_connect('delete_event' => sub { Gtk2->main_quit; });
$window->set_default_size(640, 600);

my $notebook = Gtk2::Notebook->new;
$window->add($notebook);

foreach my $unit ( ['pixel', 'pixels'],
                   ['points', 'points'],
                   ['inch', 'inches'],
                   ['mm', 'millimeters'] ) {
    $notebook->append_page(
        create_canvas(@$unit),
        Gtk2::Label->new(ucfirst($unit->[1])),
    );
}
$window->show_all();
Gtk2->main;

sub create_canvas {
    my ($unit, $name) = @_;
    my ($vbox, $hbox, $w, $swin, $canvas, $adj);
    $vbox = Gtk2::VBox->new(FALSE, 4);
    $vbox->set_border_width(4);
    $hbox= Gtk2::HBox->new(FALSE, 4);
    $vbox->pack_start($hbox, FALSE, FALSE, 0);
    $canvas = Goo::Canvas->new;
    $w = Gtk2::Label->new("Zoom:");
    $hbox->pack_start($w, FALSE, FALSE, 0);
    $adj = Gtk2::Adjustment->new(1, 0.05, 100, 0.05, 0.5, 0.5);
    $w = Gtk2::SpinButton->new($adj, 0, 2);
    $adj->signal_connect('value-changed',
                         \&zoom_changed, $canvas);
    $w->set_size_request(50, -1);
    $hbox->pack_start($w, FALSE, FALSE, 0);
    $swin = Gtk2::ScrolledWindow->new;
    $vbox->pack_start($swin, TRUE, TRUE, 0);
    $canvas->set_size_request(600, 450);
    setup_canvas($canvas, $unit, $name);
    $canvas->set_bounds(0, 0, 1000, 1000);
    $canvas->set(
        "units" => $unit,
        "anchor" => 'center'
    );
    $swin->add($canvas);
    return $vbox;
}

sub zoom_changed {
    my ($adj, $canvas) = @_;
    $canvas->set_scale($adj->get_value);
}

sub setup_canvas {
    my ($canvas, $unit, $name) = @_;
    my ($root, $item) ;
    my %data = (
        'pixel'  => [100, 100, 200, 20, 10, 200, 310, 24],
        'points' => [100, 100, 200, 20, 10, 200, 310, 24],
        'inch'   => [1, 1, 3, 0.5, 0.16,    3, 4, 0.3 ],
        'mm'     => [30, 30, 100, 10, 5,    80, 60, 10 ]
    );
    my @d = @{$data{$unit}};
    $root = $canvas->get_root_item;
    $item = Goo::Canvas::Rect->new($root, @d[0..3]);
    $item->signal_connect(
        "motion_notify_event",
        \&on_motion_notify);
    $item->{id} = "$unit - $name";
    $item = Goo::Canvas::Text->new(
        $root, "This box is $d[2]x$d[3] $name",
        $d[0]+$d[2]/2, $d[1]+$d[3]/2, -1, 'center',
        'font' => "Sans $d[4]"
    );
    $item = Goo::Canvas::Text->new(
        $root, "This font is $d[7] $name high",
        $d[5], $d[6], -1, 'center',
        "font" => "Sans $d[7]"
    );
}

sub on_motion_notify {
    my $item = shift;
    print (($item->{id} || "Unknown"), " item received 'motion-notify' signal\n");
    return FALSE;
}
